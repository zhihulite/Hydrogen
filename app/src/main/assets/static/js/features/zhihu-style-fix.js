// zhihu-style-fix.js - 知乎样式修复模块
(() => {
    const ZhihuStyleFix = {
        name: 'ZhihuStyleFix',

        isZhihuDomain() {
            return window.location.hostname.includes('zhihu.com');
        },

        inject() {
            StyleManager.addBatch({
                'zhihu-modal-close': '.Modal-closeButton { position: unset !important; }',
                'zhihu-modal-box': '.Modal { box-shadow: unset !important; width: unset; }',
                'zhihu-openinapp': '.OpenInAppButton { display: none !important; }'
            });
        },

        init() {
            if (this.isZhihuDomain()) this.inject();
        }
    };

    window.ZhihuStyleFix = ZhihuStyleFix;
})();