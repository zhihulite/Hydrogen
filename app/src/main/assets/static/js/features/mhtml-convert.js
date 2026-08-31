// features/mhtml-convert.js - MHTML转HTML功能
(() => {
    window.MhtmlConvert = {
        name: 'MhtmlConvert',
        ready: false,

        init() {
            HydrogenCore.loadJSModule('mhtml2html', {
                jsWindowName: 'mhtml2html',
                callback: () => this.ready = true
            });
        },

        convert() {
            if (!this.ready) return alert('转换功能加载中，请稍后重试');
            const data = HydrogenCore.api.sendMessage('fetchMHTML', null);
            if (!data) return alert('获取内容失败');
            try {
                const html = mhtml2html.convert(data).window.document.documentElement.outerHTML;
                HydrogenCore.api.sendMessage('saveHTML', html);
            } catch (e) {
                alert('转换失败，请重试');
            }
        }
    };
})();