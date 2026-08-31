// pages/setting.js - 设置页面
(() => {
    const SettingsPage = {
        name: 'SettingsPage',

        init() {
            this.injectStyles();
            this.optimizeViewport();
        },

        injectStyles() {
            StyleManager.addBatch({
                'settings-fix': [
                    /* 隐藏顶部栏 */
                    '.AppHeader { display: none !important; }',
                    /* 主容器绝对定位贴顶 */
                    '.App-main { position: absolute !important; top: 0 !important; left: 0 !important; right: 0 !important; }',
                    /* 主内容区占满全宽 */
                    '.SettingsMain { width: 100% !important; margin: unset; }',
                    /* 侧边栏隐藏（绝对定位移出屏幕） */
                    '.SettingsMain-sideColumn { position: absolute !important; left: 100% !important; }',
                    /* 左侧导航宽度自适应 */
                    '.SettingsNav { width: unset !important; }',
                    /* 导航链接高度自适应，左内边距 */
                    '.SettingsNav-link { height: unset !important; padding-left: 10px !important; }',
                    /* 弹窗宽度自适应 */
                    '.Modal { width: unset !important; max-height: -webkit-fill-available !important; }',
                    /* 弹窗关闭按钮位置还原 */
                    '.Modal-closeButton { position: unset !important; }',
                    /* 购买 VIP 弹窗占满宽度 */
                    '.KfeCollection-PayModal-modal { width: 100% !important; }',
                    /* 隐藏 VIP 推荐卡片 */
                    '.VipInterests { display: none !important; }',
                    /* 防止图片被压缩 */
                    'img { min-width: unset !important; }',
                    /* 隐藏底部 footer */
                    'footer { display: none !important; }',
                    /* 第三方账号列表换行 */
                    '.css-1alsiom { flex-wrap: wrap !important; }',
                    /* 第三方账号列表项自适应 */
                    '.css-60n72z { width: unset !important; flex: auto !important; }',
                    /* 水印偏好背景隐藏 */
                    '.WatermarkPreferenceExamples-bg { display: none !important; }',
                    /* 水印偏好换行 */
                    '.WatermarkPreferenceExamples { flex-wrap: wrap !important; }'
                ].join('\n')
            });
        },

        optimizeViewport() {
            const viewport = document.querySelector('meta[name="viewport"]');
            if (!viewport) return;

            let content = viewport.content || '';
            if (content && !content.includes('user-scalable=no')) {
                viewport.setAttribute('content', `${content},user-scalable=no`);
            } else if (!content) {
                viewport.setAttribute('content', 'width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no');
            }
        }
    };

    window.SettingsPage = SettingsPage;
})();