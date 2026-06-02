// dark-mode.js - 暗色模式
// 修改自 https://greasyfork.org/scripts/436455
(() => {

    const DarkMode = {
        name: 'DarkMode',
        styleId: 'dark-mode-style',

        // 滤镜配置
        filter: '-webkit-filter: url(#dark-mode-filter) !important; filter: url(#dark-mode-filter) !important;',
        reverseFilter: '-webkit-filter: url(#dark-mode-reverse-filter) !important; filter: url(#dark-mode-reverse-filter) !important;',
        noneFilter: '-webkit-filter: none !important; filter: none !important;',

        init() {
            this.createFilterSVG();
            this.updateByFullscreen();
            this.bindFullscreenEvents();
        },

        updateByFullscreen() {
            if (document.fullscreenElement) {
                this.disable();
            } else {
                this.enable();
            }
        },

        bindFullscreenEvents() {
            document.addEventListener('fullscreenchange', () => this.updateByFullscreen());
            document.addEventListener('webkitfullscreenchange', () => this.updateByFullscreen());
            document.addEventListener('mozfullscreenchange', () => this.updateByFullscreen());
        },

        enable() {
            this.removeStyle();
            this.createStyle();
            this.updateThemeColor('#131313');
        },

        disable() {
            this.removeStyle();
            this.updateThemeColor('#ffffff');
        },

        createFilterSVG() {
            // 避免重复添加
            if (document.querySelector('#dark-mode-filter-svg')) return;
            const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
            svg.id = 'dark-mode-filter-svg';
            svg.style.cssText = 'height:0;width:0;position:absolute;visibility:hidden';
            svg.innerHTML = [
                '<filter id="dark-mode-filter" color-interpolation-filters="sRGB">',
                '<feColorMatrix type="matrix" values="0.283 -0.567 -0.567 0 0.925 -0.567 0.283 -0.567 0 0.925 -0.567 -0.567 0.283 0 0.925 0 0 0 1 0"/>',
                '</filter>',
                '<filter id="dark-mode-reverse-filter" color-interpolation-filters="sRGB">',
                '<feColorMatrix type="matrix" values="0.333 -0.667 -0.667 0 1 -0.667 0.333 -0.667 0 1 -0.667 -0.667 0.333 0 1 0 0 0 1 0"/>',
                '</filter>'
            ].join('');
            document.head.appendChild(svg);
        },

        createStyle() {
            const defaultCss = [
                `html { ${this.filter} scrollbar-color: #454a4d #202324; }`,
                /* Reverse */
                `img, video, iframe, canvas, :not(object):not(body) > embed, object, svg image,`,
                `[style*="background:url"], [style*="background-image:url"],`,
                `[style*="background: url"], [style*="background-image: url"],`,
                `[background], twitterwidget {`,
                `    ${this.reverseFilter}`,
                `}`,
                /* None */
                `[style*="background:url"] *, [style*="background-image:url"] *,`,
                `[style*="background: url"] *, [style*="background-image: url"] *,`,
                `input, [background] *, img[src^="https://s0.wp.com/latex.php"],`,
                `twitterwidget .NaturalImage-image { ${this.noneFilter} }`,
                `html { text-shadow: 0 0 0 !important; }`,
                `::-webkit-scrollbar { background-color: #202324; }`,
                `::-webkit-scrollbar-thumb { background-color: #454a4d; }`,
                `::-webkit-scrollbar-corner { background-color: #181a1b; }`,
                /* 透明背景防止白屏闪烁 */
                `html, body {`,
                `    background-color: transparent !important;`,
                `}`
            ].join('\n');

            const zhihuCss = [
                /* 知乎加载图片时的文字 */
                `.ImageLoader-message { ${this.reverseFilter} }`,
                /* 知乎回答链接卡片 */
                `.RichText-LinkCardContainer { ${this.reverseFilter} }`,
            ].join('\n');

            const css = defaultCss + '\n' + zhihuCss;

            const style = document.createElement('style');
            style.id = this.styleId;
            style.textContent = css;
            document.head.appendChild(style);
        },

        removeStyle() {
            const style = document.getElementById(this.styleId);
            if (style) style.remove();
        },

        updateThemeColor(color) {
            let meta = document.querySelector('meta[name="theme-color"]');
            if (!meta) {
                meta = document.createElement('meta');
                meta.name = 'theme-color';
                document.head.appendChild(meta);
            }
            meta.content = color;
        }
    };

    window.DarkMode = DarkMode;
})();