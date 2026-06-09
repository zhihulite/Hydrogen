// features/report.js - 举报功能
(() => {
    const Report = {
        name: 'Report',

        init() {
            this.initFetchInterceptor();
        },

        initFetchInterceptor() {
            FetchManager.registerOnce('report',
                (url) => url && url.includes('/api/v4/reports'),
                async (response) => {
                    if (response.status === 200) {
                        const data = await response.json();
                        console.log('举报成功', data);
                        HydrogenCore.api.toast('举报成功');
                    } else {
                        console.log('举报失败，状态码:', response.status);
                        HydrogenCore.api.toast('举报失败');
                    }
                    
                    HydrogenCore.api.finishPage();
                }
            );
        }
    };

    window.Report = Report;
})();