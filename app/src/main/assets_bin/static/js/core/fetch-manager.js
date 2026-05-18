// fetch-manager.js
(() => {
    const FetchManager = {
        name: 'FetchManager',
        originalFetch: window.fetch.bind(window),
        interceptors: [],

        register(name, matcher, handler) {
            this.interceptors.push({ name, matcher, handler });
        },

        unregister(name) {
            const index = this.interceptors.findIndex(i => i.name === name);
            if (index !== -1) this.interceptors.splice(index, 1);
        },

        init() {
            const self = this;
            window.fetch = async function (input, init) {
                const url = typeof input === 'string' ? input : input.url;
                const response = await self.originalFetch(input, init);

                for (const { name, matcher, handler } of self.interceptors) {
                    if (matcher(url, response)) {
                        try {
                            await handler(response.clone(), url);
                        } catch (e) {
                            console.error(`[FetchManager] Interceptor error [${name}]:`, e);
                        }
                    }
                }
                return response;
            };
        },

        restore() {
            window.fetch = this.originalFetch;
        }
    };

    window.FetchManager = FetchManager;
})();