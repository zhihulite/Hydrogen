// pages/sign_in.js - 登录页面
(() => {
    const SignInPage = {
        name: 'SignInPage',

        init() {
            this.initFetchInterceptor();
        },

        initFetchInterceptor() {
            FetchManager.registerOnce('sign_in', {
                matcher: (url) => url && url.includes('oauth'),
                after: async (res) => {
                    if (res.status === 200) {
                        const data = await res.text();
                        if (data && data.includes('access_token')) {
                            HydrogenCore.api.sendMessage('login_success', data);
                            return true
                        }
                    }
                }
            });
        }
    };

    window.SignInPage = SignInPage;
})();