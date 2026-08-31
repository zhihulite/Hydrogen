// features/markdown-copy.js - Markdown导出功能
(() => {
    const MarkdownCopy = {
        name: 'MarkdownCopy',
        turndownService: null,

        init() {
            // 动态加载 libs/turndown，完成后初始化 turndown 规则
            HydrogenCore.loadJSModule('turndown', {
                jsWindowName: 'TurndownService',
                callback: () => this.initTurndown()
            });
        },

        initTurndown() {
            if (this.turndownService) {
                alert('功能已就绪，无需重复加载');
                return;
            }

            this.turndownService = new TurndownService();

            // 忽略 noscript 标签
            this.turndownService.addRule('ignoreNoscript', {
                filter: ['noscript'],
                replacement: () => ''
            });

            // 处理图片：忽略 SVG Data URI，保留正常图片
            this.turndownService.addRule('ignoreDataImages', {
                filter: 'img',
                replacement: (_, node) => {
                    const src = node.getAttribute('src');
                    return src?.startsWith('image/svg') ? '' : `![](${src})`;
                }
            });
        },

        getMarkdown() {
            // 检查 turndown 是否就绪
            if (!this.turndownService) {
                alert('功能加载中，请稍后重试');
                return null;
            }
            const richtext = document.querySelector('.RichText.ztext');
            // 未找到正文内容
            if (!richtext) {
                alert('未找到正文内容');
                return null;
            }
            return this.turndownService.turndown(richtext.innerHTML);
        },

        copy() {
            const markdown = this.getMarkdown();
            // 复制成功返回 true，失败返回 false
            if (markdown) HydrogenCore.api.copyText(markdown);
            return !!markdown;
        }
    };

    window.MarkdownCopy = MarkdownCopy;
})();