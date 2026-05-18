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
            }
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

        if (get('debug') && window.eruda) window.eruda.init();

        runIf('FetchManager');
        runIf('StyleManager');
        runIf('ZhihuStyleFix');

        if (get('custom_font')) runIf('CustomFont');
        if (get('image_viewer')) runIf('ImageViewer');
        if (get('fade_animation')) runIf('FadeAnimation');
        if (pageType !== 'answer' && get('dark_mode')) runIf('DarkMode');
  
        // 只在 answer、pin、article 页面执行 ContentBackground
        const contentPages = ['answer', 'pin', 'article'];
        if (get('background_color') && contentPages.includes(pageType)) {
            runIf('ContentBackground');
        }
        
        if (get('md_copy')) runIf('MarkdownCopy');
        if (get('enableScrollTracking')) runIf('ScrollExposureTracker');

        if (pageType === 'answer') {
            if (get('dark_answer') && get('background_color')) runIf('DarkAnswer');
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

    if (document.head) {
        initAll();
    } else {
        const obs = new MutationObserver((mutations, observer) => {
            if (document.head) {
                observer.disconnect();
                initAll();
            }
        });
        obs.observe(document, { childList: true, subtree: true });
    }
})();