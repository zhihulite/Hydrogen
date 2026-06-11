// features/report.js - 举报功能
(() => {
    const Report = {
        name: 'Report',

        init() {
            this.initFetchInterceptor();
        },

        initFetchInterceptor() {
            FetchManager.registerOnce('report', {
                matcher: (url) => url && url.includes('/api/v4/reports'),
                after: async (res) => {
                    if (res.status === 200) {
                        const data = await res.json();
                        console.log('举报成功', data);
                        HydrogenCore.api.toast('举报成功');
                    } else {
                        console.log('举报失败，状态码:', res.status);
                        HydrogenCore.api.toast('举报失败');
                    }
                    HydrogenCore.api.finishPage();
                    return true;
                }
            });
        }
    };

    window.Report = Report;
})();