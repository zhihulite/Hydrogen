// messages.js - 消息页面
(() => {
    const MessagesPage = {
        name: 'MessagesPage',

        init() {
            this.injectStyles();
            this.initDocumentListener();

            window.addEventListener('load', () => {
                setTimeout(() => {
                    this.setupInitialVisibility();
                }, 0);
            });
        },

        injectStyles() {
            StyleManager.addBatch({
                'messages-fix': [
                    /* 隐藏顶部栏 */
                    '.AppHeader { display: none !important; }',
                    /* 主容器绝对定位贴顶 */
                    '.App-main { position: absolute !important; top: 0 !important; left: 0 !important; right: 0 !important; }',
                    /* 聊天容器全屏固定 */
                    '.Chat { position: fixed !important; width: 100% !important; height: 100% !important; margin: 0 !important; top: 0 !important; left: 0 !important; min-height: unset !important; max-height: unset !important; min-width: unset !important; max-width: unset !important; }',
                    /* 聊天内容区域全屏 */
                    '.Chat-ChatBox { min-height: unset !important; max-height: unset !important; min-width: unset !important; max-width: unset !important; width: 100% !important; height: 100% !important; }',
                    /* 侧边栏移除限制 */
                    '.ChatSideBar { position: unset !important; width: unset !important; }',
                    /* 图片不压缩 */
                    'img { max-width: unset !important; }',
                    /* 消息卡片不压缩 */
                    '.CardMessage { width: unset !important; }',
                    /* 返回按钮样式及标题栏居中 */
                    '.back-button { background: none; border: none; padding: 8px; margin-right: 8px; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; border-radius: 4px; }',
                    '.Chat-ChatBox header { display: flex !important; align-items: center !important; }',
                    '.Chat-ChatBox header > :first-child { margin: 0 auto !important; }'
                ].join('\n')
            });
        },

        setupInitialVisibility() {
            if (this.isInMessageDetail()) {
                this.toggleList(false);
                this.toggleContent(true);
                this.addBackButton();
            } else {
                this.toggleList(true);
                this.toggleContent(false);
            }
        },

        isInMessageDetail() {
            const path = window.location.pathname.split('/');
            return path[1] === 'messages' && path.length > 2 && path[2] !== '';
        },

        toggleList(show) {
            const list = document.querySelector('.ChatSideBar');
            if (list) {
                list.style.visibility = show ? 'visible' : 'hidden';
                list.style.pointerEvents = show ? 'auto' : 'none';
            }
        },

        toggleContent(show) {
            const content = document.querySelector('.Chat-ChatBox, .ChatBox-empty');
            if (content) {
                content.style.visibility = show ? 'visible' : 'hidden';
                content.style.pointerEvents = show ? 'auto' : 'none';
            }
        },

        initDocumentListener() {
            document.addEventListener('click', (event) => {
                const target = event.target.closest('.ChatUserListItem');
                if (target) {
                    this.toggleList(false);
                    this.toggleContent(true);
                    this.addBackButton();
                }
            });
        },

        addBackButton() {
            setTimeout(() => {
                const titleBar = document.querySelector(".Chat-ChatBox header");
                if (!titleBar || titleBar.querySelector('.back-button')) return;

                const backBtn = this.createBackButton();
                titleBar.insertBefore(backBtn, titleBar.firstChild);
                this.backButton = backBtn;
            }, 300);
        },

        createBackButton() {
            const backBtn = document.createElement('button');
            backBtn.className = 'back-button';
            backBtn.setAttribute('aria-label', '返回');
            backBtn.innerHTML = '<svg width="24" height="24" viewBox="0 0 1024 1024" style="display:block"><path d="M879.476 470.342H244.829L507.113 209.455a41.658 41.658 0 0 0-58.88-58.88L114.967 482.676a41.891 41.891 0 0 0 0 58.88l333.266 333.033a41.658 41.658 0 0 0 58.88 0 41.891 41.891 0 0 0 0-58.88L244.829 553.658h634.647a41.658 41.658 0 1 0 0-83.316z" fill="#056de8"/></svg>';

            backBtn.onclick = (e) => {
                e.preventDefault();
                this.backToList();
            };

            return backBtn;
        },

        backToList() {
            this.toggleList(true);
            this.toggleContent(false);

            if (this.backButton) {
                this.backButton.remove();
                this.backButton = null;
            }

            history.pushState(null, null, '/messages');
        }
    };

    window.MessagesPage = MessagesPage;
})();