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
            FetchManager.registerOnce('add_column',
                (url) => url && url.includes('/api/v4/columns/request'),
                async (response) => {
                    if (response.status === 200) {
                        const res = await response.json();
                        console.log('创建专栏成功', res);
                    } else {
                        console.log('创建专栏失败，状态码:', response.status);
                    }
                }
            );
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