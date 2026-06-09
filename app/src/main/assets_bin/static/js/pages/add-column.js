// pages/add-column.js - 添加专栏页面
(() => {
    const AddColumnPage = {
        name: 'AddColumnPage',

        init() {
            this.injectStyles();
            this.initFetchInterceptor();
            this.autoClickCreateButton();
        },

        injectStyles() {
            StyleManager.addBatch({
                'add-column-fix': [
                    '.Modal-closeButton { position: unset !important; }',
                    '.Modal { box-shadow: unset !important; width: unset; }',
                    '.OpenInAppButton { display: none !important; }'
                ].join('\n')
            });
        },

        initFetchInterceptor() {
            FetchManager.registerOnce('add_column', {
                matcher: (url) => url && url.includes('/api/v4/columns/request'),
                after: async (res) => {
                    if (res.status === 200) {
                        const data = await res.json();
                        console.log('创建专栏成功', data);
                    } else {
                        console.log('创建专栏失败，状态码:', res.status);
                    }
                    return res;
                }
            });
        },

        autoClickCreateButton() {
            DomHelper.onElement('.CreateColumnButton', (btn) => {
                DomHelper.emulateClick(btn);
            });
        },

        createColumn(title, description) {
            const titleInput = document.querySelector('input[name="title"]');
            const descInput = document.querySelector('textarea[name="description"]');

            if (titleInput) DomHelper.emulateInput(titleInput, title);
            if (descInput) DomHelper.emulateInput(descInput, description);

            const submitBtn = document.querySelector('.Button--primary');
            if (submitBtn) DomHelper.emulateClick(submitBtn);
        }
    };

    window.AddColumnPage = AddColumnPage;
})();