// pages/ask.js - 提问页面
(() => {
    const AskPage = {
        name: 'AskPage',

        init() {
            this.injectStyles();
            this.initFetchInterceptor();
            this.autoClickAskButton();
        },

        injectStyles() {
            StyleManager.addBatch({
                'ask-fix': [
                    /* 隐藏顶部栏和主容器 -> 全屏模式 */
                    '.App-main, .AppHeader { display: none !important; }',
                    /* 弹窗占满视口宽度 */
                    '.Modal { width: 100vw !important; }',
                    /* 问答列表取消最大宽度限制 -> 充分利用屏幕空间 */
                    '.Ask-items { max-width: unset !important; }',
                    /* 表单区域高度自适应 -> 避免内容被截断 */
                    '.Ask-form > div { height: unset !important; }',
                    /* 关闭按钮还原位置 -> 取消绝对定位 */
                    '.Modal-closeButton { position: unset !important; }',
                    /* 弹窗内容溢出隐藏 -> 防止双滚动条 */
                    '.Modal-content.Modal-content--spread { overflow: hidden !important; }'
                ].join('\n')
            });
        },

        initFetchInterceptor() {
            FetchManager.registerOnce('ask',
                (url) => url && url.includes('/api/v4/questions'),
                async (response) => {
                    if (response.status === 200) {
                        const res = await response.json();
                        console.log('提问成功', res);
                        HydrogenCore.api.toast("提问成功");
                    } else {
                        console.log('提问失败，状态码:', response.status);
                        HydrogenCore.api.toast('提问失败');
                    }

                    HydrogenCore.api.finishPage();
                }
            );
        },

        autoClickAskButton() {
            DomHelper.onElement('#Popover2-toggle', (toggleElement) => {
                console.log('找到 Popover2-toggle，模拟 mouseover');
                // 模拟 mouseover 事件（触发 React 合成事件的 onMouseOver，基于原生 mouseover，会冒泡）
                // React 中 onMouseOver 对应原生 mouseover 事件
                DomHelper.emulateMouseOver(toggleElement);
                // 等待菜单内容中的第一个 MenuItem
                DomHelper.onElement('#Popover2-content .Menu > :first-child', (firstMenuItem) => {
                    console.log('找到菜单第一项，模拟点击');
                    DomHelper.emulateClick(firstMenuItem);
                    // 移除关闭按钮
                    DomHelper.onElement('.Modal-closeButton', (button) => {
                        button.remove();
                    });
                });
            });
        }
    };

    window.AskPage = AskPage;
})();