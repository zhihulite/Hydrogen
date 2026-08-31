// features/custom-font.js - 自定义字体
(() => {
    const CustomFont = {
        name: 'CustomFont',

        init() {
            this.injectFont();
        },

        getFontUrl() {
            // 本地文件使用 file:// 协议
            if (window.location.href.startsWith('file://')) {
                return 'file://customappfont';
            }
            // 网络页面使用当前域名
            const hostname = window.location.hostname;
            return `https://${hostname}/customappfont`;
        },

        injectFont() {
            const fontUrl = this.getFontUrl();
            const css = `
                @font-face {
                    font-family: "customappfont";
                    src: url("${fontUrl}") format("truetype");
                }
                * {
                    font-family: "customappfont" !important;
                }
            `;
            StyleManager.add('custom-font', css);
        }
    };

    window.CustomFont = CustomFont;
})();