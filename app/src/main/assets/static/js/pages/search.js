// pages/search.js - 搜索页面
(() => {
    const SearchPage = {
        name: 'SearchPage',

        init() {
            // 屏蔽搜索页可能触发的外部跳转或弹窗
            window.open = () => {};
        }
    };

    window.SearchPage = SearchPage;
})();