// features/dark-answer.js - 回答页暗黑主题
(() => {
    const DarkAnswer = {
        name: 'DarkAnswer',

        init() {
            this.injectStyles();
        },

        injectStyles() {
            // 从配置中获取背景色和字体颜色百分比
            const bgColor = HydrogenCore.getConfig('background_color');
            const fontColor = HydrogenCore.getConfig('font_color') || 80;

            if (!bgColor) return;

            const css = [
                /* 继承元信息颜色，防止被强制覆盖 */
                '.AnswerItem-time *, .ExtraInfo * { color: inherit !important; }',
                /* GIF 播放器图标透明化 */
                '.GifPlayer-icon, .GifPlayer-icon * { background-color: transparent !important; }',
                /* 全局背景与字体颜色设置 */
                'body, body * {',
                '    background-color: #' + bgColor + ' !important;',
                '    color: rgb(' + fontColor + '%, ' + fontColor + '%, ' + fontColor + '%) !important;',
                '}',
                /* 数学公式和特殊元素背景透明化 */
                '.ztext-math, .ztext-math *, [eeimg], [data-tex] { background-color: transparent !important; }'
            ].join('\n');

            StyleManager.add('dark-answer', css);
        }
    };

    window.DarkAnswer = DarkAnswer;
})();