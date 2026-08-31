// pages/zvideo.js - 视频页面
(() => {
    const ZVideoPage = {
        name: 'ZVideoPage',

        init() {
            StyleManager.add('zvideo-fix', '.VideoPlayer-container { position: relative !important; }');
        }
    };

    window.ZVideoPage = ZVideoPage;
})();