// loader.js
(() => {
    if (window.__HYDROGEN_LOADED) return;
    window.__HYDROGEN_LOADED = true;

    const Core = {
        config: {},

        execute(action, data) {
            if (!window.HydrogenBridge) return null;
            const payload = typeof data === 'object' && data !== null ? JSON.stringify(data) : String(data);
            return window.HydrogenBridge.execute(action, payload);
        },

        getConfig(key) {
            return this.config[key];
        },

        getPageType() {
            if (this.config.pageType) return this.config.pageType;
            const path = window.location.pathname;
            const url = window.location.href;
            const isApp = url.includes('zhihu.com') && path.includes('/appview');

            // 格式：路径，匹配后页面类型，是否是 AppView
            const rules = [
                ['/answer/', 'answer', true],
                ['/pin/', 'pin', true],
                ['/p/', 'article', true],
                ['/zvideo/', 'zvideo', false],
                ['/messages', 'messages', false],
                ['/settings', 'settings', false],
                ['/theater', 'drama', false],
                ['/notifications', 'notification', false],
                ['/column/request', 'add_column', false],
                ['/signin', 'signin', false],
                ['/report', 'report', false],
                ['/search', 'search', false]
            ];

            for (const [keyword, type, appOnly] of rules) {
                if (appOnly && !isApp) continue;
                if (path.includes(keyword) || url.includes(keyword)) return type;
            }
            return 'default';
        },

        loadJSModule(moduleName, options) {
            const callback = typeof options === 'function' ? options : options?.callback;
            const jsWindowName = typeof options === 'object' ? options?.jsWindowName || moduleName : moduleName;

            if (window[jsWindowName]) {
                if (callback) callback();
                return;
            }
            this.execute('loadJSModule', moduleName);
            if (callback) {
                const check = setInterval(() => {
                    if (window[jsWindowName]) {
                        clearInterval(check);
                        callback();
                    }
                }, 50);
            }
        },

        injectJS: {
            // DOM 开始解析（document.head 出现时）
            start(callback) {
                if (document.head) {
                    callback();
                } else {
                    const obs = new MutationObserver(() => {
                        if (document.head) {
                            obs.disconnect();
                            callback();
                        }
                    });
                    obs.observe(document.documentElement || document, { childList: true, subtree: true });
                }
            },
            // DOM 解析完成（document-end）
            domReady(callback) {
                if (document.readyState === 'interactive' || document.readyState === 'complete') {
                    callback();
                } else {
                    document.addEventListener('DOMContentLoaded', callback);
                }
            },
            // 页面完全加载（window load）
            idle(callback) {
                if (document.readyState === 'complete') {
                    callback();
                } else {
                    window.addEventListener('load', callback);
                }
            }
        },

        api: {
            sendMessage(action, data) {
                return Core.execute('message', { action, data });
            },
            copyText(text) {
                Core.execute('copyText', text);
            },
            openImages(data) {
                Core.execute('openImages', data);
            },
            screenshotError(error) {
                Core.execute('screenshotError', error);
            },
            scrollHistory(data) {
                Core.execute('scrollHistory', data);
            },
            toast(msg) {
                Core.execute('toast', msg);
            },
            log(msg) {
                Core.execute('log', msg);
            },
            finishPage() {
                Core.execute('finishPage');
            },
        }
    };

    window.HydrogenCore = Core;

    const loadConfig = () => {
        const raw = Core.execute('getConfig', 'all');
        if (!raw) return;
        try {
            const cfg = JSON.parse(raw);
            for (const k in cfg) {
                if (cfg[k] === 'true') cfg[k] = true;
                else if (cfg[k] === 'false') cfg[k] = false;
            }
            Core.config = cfg;
        } catch (e) {
            Core.execute('log', `Config error: ${e.message}`);
        }
    };

    const initAll = () => {
        loadConfig();

        const runIf = (name) => {
            const mod = window[name];
            if (mod && typeof mod.init === 'function') {
                try {
                    mod.init(Core.config);
                } catch (e) {
                    Core.execute('log', `Init error [${name}]: ${e.message}`);
                }
            }
        };

        const get = (key) => Core.getConfig(key);
        const pageType = Core.getPageType();

        if (get('debug')) Core.injectJS.idle(() => Core.loadJSModule('eruda', () => window.eruda?.init()));

        runIf('FetchManager');
        runIf('StyleManager');
        runIf('ZhihuStyleFix');

        if (get('custom_font')) runIf('CustomFont');
        if (get('image_viewer')) runIf('ImageViewer');
        if (get('fade_animation')) runIf('FadeAnimation');
        if (get('dark_mode')) runIf('DarkMode');

        // 只在 answer、pin、article 页面且不是夜间模式执行 ContentBackground
        const contentPages = ['answer', 'pin', 'article'];
        if (get('background_color') && !get('dark_mode') && contentPages.includes(pageType)) {
            runIf('ContentBackground');
        }

        if (get('md_copy')) runIf('MarkdownCopy');
        if (get('enable_mhtml_convert')) runIf('MhtmlConvert');
        if (get('enableScrollTracking')) runIf('ScrollExposureTracker');

        if (pageType === 'answer') {
            runIf('ScrollRestore');
            runIf('VideoAnswer');
            runIf('AnswerPage');
            return;
        }

        const pageMap = {
            pin: 'PinPage',
            messages: 'MessagesPage',
            settings: 'SettingsPage',
            drama: 'DramaPage',
            notification: 'NotificationPage',
            ask: 'AskPage',
            add_column: 'AddColumnPage',
            zvideo: 'ZVideoPage',
            signin: 'SignInPage',
            report: 'ReportPage',
            search: 'SearchPage'
        };

        if (pageMap[pageType]) runIf(pageMap[pageType]);
    };

    Core.injectJS.start(() => initAll());
})();