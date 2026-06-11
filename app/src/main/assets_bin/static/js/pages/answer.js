// answer.js - 回答页面优化
(() => {
    // HTTP 拦截器模块
    const HttpInterceptor = {
        run() {
            // 拦截推荐阅读请求（阻断）
            FetchManager.register('block-related-readings', {
                matcher: (url) => url && url.includes('related-readings'),
                before: () => false
            });

            // 拦截回答接口，禁用打赏功能
            FetchManager.registerOnce('disable-reward', {
                matcher: (url) => url?.includes('/api/v4/answers/'),
                after: async (res) => {
                    const data = await res.json();
                    if (!data?.reward_info) return null;
                    data.reward_info = {
                        can_open_reward: false,
                        is_rewardable: false,
                        reward_member_count: 0,
                        reward_total_money: 0,
                        tagline: ""
                    };
                    return new Response(JSON.stringify(data), { status: res.status, headers: res.headers });
                }
            });
        }
    };

    // 样式注入模块
    const StyleInjector = {
        run() {
            StyleManager.addBatch({
                'answer-fix': [
                    '.RichText figure > figure { width: 100% !important; margin: unset !important; }',
                    '.MobileAppHeader { display: none !important; }',
                    '.Modal-closeButton { position: unset !important; }',
                    '.Modal { box-shadow: unset !important; width: unset; }',
                    '.OpenInAppButton { display: none !important; }'
                ].join('\n'),
                'hide-reward': '.AnswerReward { display: none !important; }',
                'hide-reading': '.AppViewRecommendedReading { display: none !important; }'
            });
        }
    };

    // 横竖屏处理模块
    const OrientationHandler = {
        run() {
            let landscapeStyle = null;

            const updateImageStyles = () => {
                const isLandscape = window.matchMedia('(orientation: landscape)').matches;

                if (isLandscape && !landscapeStyle) {
                    landscapeStyle = document.createElement('style');
                    landscapeStyle.textContent = 'img { max-height: 100vmin !important; width: auto !important; }';
                    document.head.appendChild(landscapeStyle);
                } else if (!isLandscape && landscapeStyle) {
                    landscapeStyle.remove();
                    landscapeStyle = null;
                }
            };

            window.addEventListener('orientationchange', () => {
                setTimeout(updateImageStyles, 50);
            });
            updateImageStyles();
        }
    };

    // 代码滚动模块
    const CodeScrollHandler = {
        initialized: false,

        run() {
            if (this.initialized) return;

            const enableScroll = HydrogenCore.getConfig('answer_code_scroll');
            const shouldScroll = enableScroll === undefined ? true : enableScroll;

            if (shouldScroll) {
                this.initScrollEvents();
            } else {
                this.applyLineWrap();
            }

            this.initialized = true;
        },

        applyLineWrap() {
            document.querySelectorAll(".ztext pre").forEach(p => {
                p.style.whiteSpace = "pre-wrap";
                p.style.wordBreak = "break-all";
            });
        },

        needsHorizontalScroll(element) {
            return element.scrollWidth > element.clientWidth;
        },

        initScrollEvents() {
            document.querySelectorAll(".ztext pre").forEach(element => {
                if (!this.needsHorizontalScroll(element)) return;

                let startX, startY, isHorizontal = false;

                element.addEventListener('touchstart', (event) => {
                    startX = event.touches[0].clientX;
                    startY = event.touches[0].clientY;
                    isHorizontal = false;
                });

                element.addEventListener('touchmove', (event) => {
                    const currentX = event.touches[0].clientX;
                    const currentY = event.touches[0].clientY;
                    const deltaX = Math.abs(currentX - startX);
                    const deltaY = Math.abs(currentY - startY);

                    if (!isHorizontal && (deltaX > 4 || deltaY > 4)) {
                        isHorizontal = deltaX > deltaY;
                        HydrogenCore.api.sendMessage(isHorizontal ? "disableParentScroll" : "enableParentScroll");
                    }
                });

                const onEnd = () => {
                    if (isHorizontal) {
                        HydrogenCore.api.sendMessage("enableParentScroll");
                    }
                    isHorizontal = false;
                };

                element.addEventListener('touchend', onEnd);
                element.addEventListener('touchcancel', onEnd);
            });
        }
    };

    // 视频加载模块
    const VideoLoader = {
        run() {
            document.querySelectorAll('.video-box').forEach(box => this.loadVideo(box));
        },

        loadVideo(videoBox) {
            const href = videoBox.href;
            if (!href) return;

            const match = decodeURIComponent(href).match(/\/video\/(\S*)/);
            if (!match) return;

            const videoId = match[1];
            fetch(`https://lens.zhihu.com/api/v4/videos/${videoId}`)
                .then(res => res.json())
                .then(data => {
                    const playlists = data.playlist;
                    const videoUrl = playlists.SD?.play_url || playlists.LD?.play_url || playlists.HD?.play_url;
                    if (videoUrl) {
                        videoBox.outerHTML = `<div class="video-box"><video src="${videoUrl}" style="width:100%" controls></video></div>`;
                    }
                })
                .catch(err => console.error('Video load failed:', err));
        }
    };

    // 付费回答模块
    const PaidAnswerHandler = {
        run() {
            DomHelper.onElement('.ExtraInfo', (extraInfo) => {
                const parent = extraInfo.parentElement;
                if (!parent) return;

                const div = parent.querySelector('div:last-child');
                if (div && div.innerText.includes('使用 App 查看完整内容') && div.innerText.includes('🔗App 内查看')) {
                    const tip = document.createElement('div');
                    tip.className = 'ExtraInfo';
                    tip.innerText = '该回答为付费回答';
                    extraInfo.insertBefore(tip, extraInfo.firstChild);

                    const link = div.querySelector('a');
                    if (link) {
                        link.href = 'javascript:void(0)';
                        link.textContent = '🔗立即加载';
                        link.onclick = () => this.loadPaidContent(link, div);
                    }
                }
            });
        },

        async loadPaidContent(link, container) {
            if (link.textContent === '加载中...') return;
            link.textContent = '加载中...';

            const id = window.location.pathname.split('/').pop();
            try {
                const res = await fetch(`https://www.zhihu.com/appview/v2/answer/${id}`);
                const html = await res.text();

                const sourceRich = new DOMParser().parseFromString(html, 'text/html').querySelector('.RichText');
                const targetRich = document.querySelector('.RichText');

                if (sourceRich && targetRich) {
                    Array.from(sourceRich.children).forEach(child => {
                        targetRich.appendChild(child.cloneNode(true));
                    });
                    container.remove();
                }
            } catch (e) {
                alert('加载失败');
            } finally {
                link.textContent = '🔗立即加载';
            }
        }
    };

    // 回答加载等待模块
    const AnswerLoadWaiter = {
        loaded: false,

        run(callback) {
            FetchManager.registerOnce('answer-wait-load', {
                matcher: (url) => url && url.includes('/api/v4/answers/'),
                before: () => {
                    setTimeout(() => {
                        if (!this.loaded) {
                            this.loaded = true;
                            callback();
                        }
                    }, 500);
                    return true
                }
            });

            if (document.querySelector('.RichText')) {
                setTimeout(() => {
                    if (!this.loaded) {
                        this.loaded = true;
                        callback();
                    }
                }, 100);
            }
        }
    };

    // 主模块
    const AnswerPage = {
        name: 'AnswerPage',
        init() {
            HttpInterceptor.run();
            StyleInjector.run();
            OrientationHandler.run();

            AnswerLoadWaiter.run(() => {
                if (HydrogenCore.getConfig("answer_code_no_scroll") !== true) CodeScrollHandler.run();
                VideoLoader.run();
                PaidAnswerHandler.run();
                ScrollRestore.restore();
            });
        }
    };

    window.AnswerPage = AnswerPage;
})();