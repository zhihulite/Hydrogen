// scroll-exposure-tracker.js - 滚动曝光追踪器
(() => {
    // 从 URL 中提取类型和 ID（/p/ 映射为 article）
    const getPageInfo = () => {
        const path = window.location.pathname;
        const rules = [
            [/\/(?:appview\/)?answer\/(\d+)/, 'answer'],
            [/\/(?:appview\/)?pin\/(\d+)/, 'pin'],
            [/\/(?:appview\/)?p\/(\d+)/, 'article']
        ];

        for (const [regex, type] of rules) {
            const match = path.match(regex);
            if (match) return { type, id: match[1] };
        }
        return null;
    };

    const getContainerSelector = (pageType) => {
        switch (pageType) {
            case 'pin': return '.css-0';
            case 'answer':
            case 'article': return '.RichText';
            default: return null;
        }
    };

    // 计算滚动进度 (0-100)
    const getScrollProgress = (container) => {
        if (!container) return 0;

        const rect = container.getBoundingClientRect();
        const winH = window.innerHeight;
        const height = container.offsetHeight;

        // 视口底部相对于容器顶部的距离
        // 如果 top 是正的，说明容器顶部在屏幕内，可见部分 = winH - top
        // 如果 top 是负的，说明容器顶部已滚出，可见部分 = winH + |top|
        let visibleFromTop = winH - rect.top;

        // 1. 还没滚到容器 (visibleFromTop <= 0)
        if (visibleFromTop <= 0) return 0;

        // 2. 已经完全滚过 (visibleFromTop >= height)
        if (visibleFromTop >= height) return 100;

        // 3. 正常计算比例
        // 注意：这里计算的是“视口覆盖了多少比例的容器”
        // 对于短内容，初始值就会很高，这是物理事实。
        return Math.round((visibleFromTop / height) * 100);
    };

    const ScrollExposureTracker = {
        name: 'ScrollExposureTracker',
        timer: null,
        scrollHandler: null,

        init() {
            const pageInfo = getPageInfo();
            if (!pageInfo) {
                console.warn('[ScrollExposureTracker] 无法识别页面类型或ID');
                return;
            }

            this.pageType = pageInfo.type;
            this.contentId = pageInfo.id;
            this.containerSelector = getContainerSelector(this.pageType);
            this.lastProgress = -1;

            DomHelper.onElement(this.containerSelector, (container) => {
                this.container = container;
                this.initScrollListener();
                this.checkAndSendProgress();
            });
        },

        sendProgress(progress) {
            HydrogenCore.api.scrollHistory({
                type: this.pageType,
                id: this.contentId,
                progress: progress
            });
        },

        checkAndSendProgress() {
            if (!this.container) return;

            const progress = getScrollProgress(this.container);

            // 只有进度变化时才发送
            if (progress !== this.lastProgress) {
                this.lastProgress = progress;
                this.sendProgress(progress);

                // 达到 100% 后移除监听，节省性能
                if (progress === 100) {
                    this.removeScrollListener();
                }
            }
        },

        initScrollListener() {
            const onScroll = () => {
                if (this.timer) clearTimeout(this.timer);
                this.timer = setTimeout(() => {
                    this.checkAndSendProgress();
                }, 3000);
            };

            this.scrollHandler = onScroll;
            window.addEventListener('scroll', onScroll, { passive: true });
        },

        removeScrollListener() {
            if (this.scrollHandler) {
                window.removeEventListener('scroll', this.scrollHandler);
                this.scrollHandler = null;
            }
            if (this.timer) {
                clearTimeout(this.timer);
                this.timer = null;
            }
        }
    };

    window.ScrollExposureTracker = ScrollExposureTracker;
})();