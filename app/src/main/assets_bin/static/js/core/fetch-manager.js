// fetch-manager.js - 轻量级 fetch 拦截器
(() => {
    const FetchManager = {
        originalFetch: window.fetch.bind(window),
        interceptors: [],        // 永久拦截器
        onceInterceptors: [],    // 单次拦截器

        // 注册永久拦截器
        register(name, options) {
            const { matcher, before, after } = options;
            this.interceptors.push({ name, matcher, before, after });
        },

        // 注册单次拦截器（返回 null 可保留，否则执行后自动移除）
        registerOnce(name, options) {
            const { matcher, before, after } = options;
            this.onceInterceptors.push({ name, matcher, before, after, once: true });
        },

        // 移除拦截器
        unregister(name) {
            this.interceptors = this.interceptors.filter(i => i.name !== name);
            this.onceInterceptors = this.onceInterceptors.filter(i => i.name !== name);
        },

        // 执行拦截器列表
        async _run(list, url, init, response = null) {
            for (let i = 0; i < list.length; i++) {
                const { matcher, before, after, once } = list[i];
                if (!matcher(url)) continue;

                const hook = response ? after : before;
                if (!hook) continue;  // 无对应钩子则跳过

                const result = await hook(response?.clone() ?? url, response ? url : init);
                if (result === false) return { blocked: true };           // 阻断请求
                if (result instanceof Response) return { response: result }; // 替换响应

                // 单次拦截器：返回 null 则保留，否则移除
                if (once && result !== null) { list.splice(i, 1); i--; }
            }
            return {};
        },

        // 核心 fetch 逻辑
        async _fetch(input, init) {
            const url = typeof input === 'string' ? input : input.url;

            // 请求前拦截（before）
            for (const list of [this.interceptors, this.onceInterceptors]) {
                const res = await this._run(list, url, init);
                if (res.blocked) return new Response('{"code":-1,"message":"blocked"}', { status: 200 });
                if (res.response) return res.response;
            }

            // 发起真实请求
            const response = await this.originalFetch(input, init);

            // 响应后拦截（after）
            for (const list of [this.interceptors, this.onceInterceptors]) {
                const res = await this._run(list, url, init, response);
                if (res.response) return res.response;
            }

            return response;
        },

        // 启动拦截
        init() { window.fetch = this._fetch.bind(this); },

        // 恢复原始 fetch
        restore() { window.fetch = this.originalFetch; }
    };

    window.FetchManager = FetchManager;
})();