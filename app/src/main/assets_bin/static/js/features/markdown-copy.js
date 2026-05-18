// features/markdown-copy.js - Markdown导出功能
(() => {
    const MarkdownCopy = {
        name: 'MarkdownCopy',
        turndownService: null,

        init() {
            this.loadTurndown();
        },

        loadTurndown() {
            if (typeof TurndownService === 'undefined') {
                alert('[MarkdownCopy] waiting for turndown');
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
                replacement: (content, node) => {
                    const src = node.getAttribute('src');
                    if (src && src.startsWith('image/svg')) {
                        return '';
                    }
                    return `![](${src})`;
                }
            });
        },

        getMarkdown() {
            if (!this.turndownService) {
                alert('[MarkdownCopy] turndown not ready');
                return null;
            }

            const richtext = document.querySelector('.RichText.ztext');
            if (!richtext) {
                alert('[MarkdownCopy] RichtText not found');
                return null;
            }

            return this.turndownService.turndown(richtext.innerHTML);
        },

        copy() {
            const markdown = this.getMarkdown();
            if (markdown) {
                HydrogenCore.api.copyText(markdown);
                return true;
            }
            return false;
        }
    };

    window.MarkdownCopy = MarkdownCopy;
})();