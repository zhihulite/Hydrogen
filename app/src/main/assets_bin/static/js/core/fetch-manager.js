// fetch-manager.js
(() => {
    const FetchManager = {
        name: 'FetchManager',
        originalFetch: window.fetch.bind(window),
        interceptors: [],
        onceInterceptors: [],

        register(name, matcher, handler) {
            this.interceptors.push({ name, matcher, handler });
        },

        // 单次拦截器，执行后自动移除
        registerOnce(name, matcher, handler) {
            this.onceInterceptors.push({ name, matcher, handler });
        },

        unregister(name) {
            const index = this.interceptors.findIndex(i => i.name === name);
            if (index !== -1) this.interceptors.splice(index, 1);

            const onceIndex = this.onceInterceptors.findIndex(i => i.name === name);
            if (onceIndex !== -1) this.onceInterceptors.splice(onceIndex, 1);
        },

        init() {
            const self = this;
            window.fetch = async function (input, init) {
                const url = typeof input === 'string' ? input : input.url;
                const response = await self.originalFetch(input, init);

                // 处理永久拦截器
                for (const { name, matcher, handler } of self.interceptors) {
                    if (matcher(url, response)) {
                        try {
                            await handler(response.clone(), url);
                        } catch (e) {
                            console.error(`[FetchManager] Interceptor error [${name}]:`, e);
                        }
                    }
                }

                // 处理单次拦截器（执行后移除）
                const onceCopy = [...self.onceInterceptors];
                for (const { name, matcher, handler } of onceCopy) {
                    if (matcher(url, response)) {
                        try {
                            await handler(response.clone(), url);
                        } catch (e) {
                            console.error(`[FetchManager] Once interceptor error [${name}]:`, e);
                        }
                        // 执行后移除
                        const index = self.onceInterceptors.findIndex(i => i.name === name);
                        if (index !== -1) self.onceInterceptors.splice(index, 1);
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