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

    // 代码块显示模块：换行或横向滑动
    const CodeScrollHandler = {
        initialized: false,

        run() {
            if (this.initialized) return;

            const wrap = HydrogenCore.getConfig('answer_code_wrap');
            const shouldWrap = wrap === undefined ? true : wrap;

            if (shouldWrap) {
                this.applyLineWrap();
            } else {
                this.initScrollEvents();
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
            DomHelper.onElement('.RichText', (richtext) => this.setupGate(richtext));
        },

        // 门禁块为 RichText 内最后一个 div，文本含 App 与 查看
        setupGate(richtext) {
            const divs = richtext.getElementsByTagName('div');
            if (divs.length === 0) return;

            const gate = divs[divs.length - 1];
            const gateText = gate.innerText;
            if (!(gateText.includes('App') || gateText.includes('app')) || !gateText.includes('查看')) return;

            const extraInfo = document.querySelector('.ExtraInfo');
            if (extraInfo) {
                const tip = document.createElement('div');
                tip.className = 'ExtraInfo';
                tip.innerText = '该回答为付费回答';
                extraInfo.insertBefore(tip, extraInfo.firstChild);
            }

            const link = gate.querySelector('a');
            if (!link) return;
            link.href = 'javascript:void(0);';
            link.textContent = '🔗立即加载';
            link.onclick = () => this.loadPaidContent(link, richtext, gate);
        },

        // 定位预览结尾元素（倒数第二个，最后一个为门禁块）在完整内容中的位置，其后即付费部分；
        // 同文本元素可能在预览内重复出现，按其在预览中出现的序次对齐
        findPaidStartIndex(richtext, sourceRich) {
            const targetChildren = Array.from(richtext.children);
            const sourceChildren = Array.from(sourceRich.children);
            if (targetChildren.length < 2 || sourceChildren.length < 2) return -1;

            const tailText = targetChildren[targetChildren.length - 2].textContent.trim();
            let remaining = targetChildren.filter(child => child.textContent.trim() === tailText).length;
            return sourceChildren.findIndex(child => child.textContent.trim() === tailText && --remaining === 0);
        },

        async loadPaidContent(link, richtext, gate) {
            if (link.textContent === '加载中...') return;
            link.textContent = '加载中...';

            try {
                const id = window.location.pathname.split('/').pop();
                const res = await fetch(`https://www.zhihu.com/appview/v2/answer/${id}`);
                if (!res.ok) throw new Error(`HTTP ${res.status}`);

                const sourceRich = new DOMParser().parseFromString(await res.text(), 'text/html').querySelector('.RichText');
                if (!sourceRich) throw new Error('未找到正文');

                // appview 未返回付费内容时完整版仍以预览结尾收尾，两种文本一致即未购买/未开通会员
                if (richtext.children[richtext.children.length - 2].textContent === sourceRich.children[sourceRich.children.length - 1].textContent) {
                    link.textContent = '🔗立即加载';
                    alert('获取失败 请检查是否开通会员或是否购买');
                    return;
                }

                const index = this.findPaidStartIndex(richtext, sourceRich);
                if (index === -1) throw new Error('未找到对齐元素');

                Array.from(sourceRich.children).slice(index + 1).forEach(node => {
                    const added = richtext.appendChild(node.cloneNode(true));
                    this.resolveEle(added);
                });

                gate.remove();
            } catch (e) {
                alert('出错了 请更新或反馈 错误信息' + e);
                link.textContent = '🔗立即加载';
            }
        },

        // 搬入的 figure 以 data:image 占位（懒加载），需换回原图并提供重试
        resolveEle(ele) {
            if (ele.tagName !== 'FIGURE') return;
            let img = ele.querySelector('img');
            if (!img) return;

            const orisrc = img.src;
            const loadsrc = img.dataset.original || img.dataset.src;
            if (orisrc.slice(0, 10) !== 'data:image') return;

            const figure = ele.children[0].tagName === 'FIGURE' ? ele.children[0] : ele;
            figure.innerHTML += '<div class="ImageLoader-message">加载中...</div>';
            // innerHTML 重写后原 img 引用失效，重新获取
            img = ele.querySelector('img');
            const tipEl = ele.querySelector('.ImageLoader-message');
            const errortip = '加载失败，点击重试';

            tipEl.addEventListener('click', function () {
                if (this.innerText !== errortip) return;
                this.innerText = '加载中...';
                img.src = loadsrc;
            });
            img.addEventListener('load', () => {
                if (img.src !== orisrc) tipEl.remove();
            });
            img.addEventListener('error', () => {
                img.src = orisrc;
                tipEl.innerText = errortip;
            });

            img.src = loadsrc;
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
                CodeScrollHandler.run();
                VideoLoader.run();
                PaidAnswerHandler.run();
                ScrollRestore.restore();
            });
        }
    };

    window.AnswerPage = AnswerPage;
})();