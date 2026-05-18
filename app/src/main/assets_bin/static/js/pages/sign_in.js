// pages/sign_in.js - 登录页面
(() => {
    const SignInPage = {
        name: 'SignInPage',

        init() {
            this.initFetchInterceptor();
        },

        initFetchInterceptor() {
            FetchManager.register('sign_in',
                (url) => url && url.includes('oauth'),
                async (response) => {
                    if (response.status === 200) {
                        const data = await response.text();
                        if (data && data.includes('access_token')) {
                            HydrogenCore.api.sendMessage('login_success', data);
                        }
                    }
                }
            );
        }
    };

    window.SignInPage = SignInPage;
})();