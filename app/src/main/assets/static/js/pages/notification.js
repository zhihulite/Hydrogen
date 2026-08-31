// notification.js - 通知页面
(() => {
    const NotificationPage = {
        name: 'NotificationPage',

        init() {
            this.injectStyles();
        },

        injectStyles() {
            StyleManager.addBatch({
                'notification-fix': [
                    /* 隐藏顶部栏 */
                    '.AppHeader { display: none !important; }',
                    /* 隐藏侧边栏（第二个子元素） */
                    '.Notifications-Layout > :nth-child(2) { display: none !important; }',
                    /* 固定吸顶元素贴顶 */
                    '.Sticky.is-fixed { top: 0 !important; }',
                    /* 通知布局占满全宽，清除边距 */
                    '.Notifications-Layout { width: 100% !important; margin: 0 !important; padding: 0 !important; }',
                    /* 主内容区占满全宽 */
                    '.Notifications-Main { width: 100% !important; margin-right: 0 !important; }',
                    /* 主容器绝对定位贴顶 */
                    '.App-main { position: absolute !important; top: 0 !important; left: 0 !important; right: 0 !important; }'
                ].join('\n')
            });
        }
    };

    window.NotificationPage = NotificationPage;
})();