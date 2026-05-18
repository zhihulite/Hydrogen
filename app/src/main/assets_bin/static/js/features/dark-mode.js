// dark-mode.js - 暗色模式
(() => {
    const DarkMode = {
        name: 'DarkMode',
        enabled: false,
        styleId: 'dark-mode-style',
        svgId: 'dark-mode-svg',

        init() {
            this.enabled = true;
            this.enable();
        },

        enable() {
            if (!this.enabled) return;
            if (!this.isFirefox()) this.createFilterSVG();
            this.createDarkStyle();
            this.updateThemeColor('#131313');
        },

        disable() {
            this.removeFilterSVG();
            this.removeDarkStyle();
            this.updateThemeColor('#ffffff');
            this.enabled = false;
        },

        createFilterSVG() {
            if (document.getElementById(this.svgId)) return;

            const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
            svg.id = this.svgId;
            svg.style.cssText = 'height:0;width:0';
            svg.innerHTML = [
                '<filter id="dark-mode-filter">',
                '<feColorMatrix type="matrix" values="0.283 -0.567 -0.567 0 0.925 -0.567 0.283 -0.567 0 0.925 -0.567 -0.567 0.283 0 0.925 0 0 0 1 0"/>',
                '</filter>',
                '<filter id="dark-mode-reverse-filter">',
                '<feColorMatrix type="matrix" values="0.333 -0.667 -0.667 0 1 -0.667 0.333 -0.667 0 1 -0.667 -0.667 0.333 0 1 0 0 0 1 0"/>',
                '</filter>'
            ].join('');
            document.head.appendChild(svg);
        },

        removeFilterSVG() {
            const svg = document.getElementById(this.svgId);
            if (svg) svg.remove();
        },

        createDarkStyle() {
            if (document.getElementById(this.styleId)) return;

            const isFF = this.isFirefox();

            // 基础滤镜
            const filterVal = '0.283 -0.567 -0.567 0 0.925 -0.567 0.283 -0.567 0 0.925 -0.567 -0.567 0.283 0 0.925 0 0 0 1 0';
            // 反向滤镜（用于图片等）
            const reverseVal = '0.333 -0.667 -0.667 0 1 -0.667 0.333 -0.667 0 1 -0.667 -0.667 0.333 0 1 0 0 0 1 0';

            const getFilterCss = (values, id) => {
                if (isFF) {
                    const encoded = encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg"><filter id="${id}"><feColorMatrix type="matrix" values="${values}"/></filter></svg>`);
                    return `filter: url('data:image/svg+xml;utf8,${encoded}#${id}') !important;`;
                }
                return `-webkit-filter: url(#${id}) !important; filter: url(#${id}) !important;`;
            };

            const filterCss = getFilterCss(filterVal, 'dark-mode-filter');
            const reverseFilterCss = getFilterCss(reverseVal, 'dark-mode-reverse-filter');

            const css = [
                `html { ${filterCss} scrollbar-color: #454a4d #202324; }`,
                `img, video, iframe, canvas, object, svg image { ${reverseFilterCss} }`,
                `img { filter: none !important; }`,
                `::-webkit-scrollbar { background-color: #202324; }`,
                `::-webkit-scrollbar-thumb { background-color: #454a4d; }`,
                `body, body * { background-color: #1a1a1a !important; color: #e0e0e0 !important; }`,
                `.AnswerItem-time *, .ExtraInfo * { color: inherit !important; }`,
                `.ztext-math, .ztext-math *, [eeimg], [data-tex] { background-color: transparent !important; }`
            ].join('\n');

            const style = document.createElement('style');
            style.id = this.styleId;
            style.textContent = css;
            document.head.appendChild(style);
        },

        removeDarkStyle() {
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
        },

        isFirefox() {
            return /Firefox/i.test(navigator.userAgent);
        }
    };

    window.DarkMode = DarkMode;
})();