// content-background.js - 软件背景色
(() => {
    const ContentBackground = {
        name: 'ContentBackground',

        init() {
            const bgColor = HydrogenCore.getConfig('background_color');
            if (!bgColor) return;
            this.inject(bgColor);
        },

        inject(bgColor) {
            // 核心背景覆盖: body, 根容器, AppMain, 评论区(CommentSection), 预加载骨架(skeleton), 
            // 底部栏(Toolbar), 作者卡片(AuthorCard), 文章底部(PostIndex-Footer)
            const mainSelectors = [
                'body',
                'body > div:not([class]):not([id]) *',
                'root',
                '.AppMain',
                '.AppMain > div',
                '.CommentSection',
                '.skeleton',
                '.Toolbar',
                '.UserLine.AuthorCard',
                '.PostIndex-Footer *'
            ].join(', ');

            // 特殊处理: 移除文章反馈遮罩(.css-1kvz3a2)和底部阴影(.bottom-shadow)的背景，防止冲突
            const resetSelectors = '.css-1kvz3a2, .bottom-shadow';

            const css = `
                ${mainSelectors} { background-color: ${bgColor} !important; }
                ${resetSelectors} { background: unset !important; }
            `;

            StyleManager.add('content-background', css);
        }
    };

    window.ContentBackground = ContentBackground;
})();