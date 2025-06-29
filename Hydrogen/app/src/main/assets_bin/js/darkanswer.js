(function () {
    // 如果 document.head 已经存在，直接执行注入逻辑
    if (document.head) {
        injectStyles();
    } else {
        // 否则监听 DOM 变化直到 <head> 出现
        var observer = new MutationObserver(function (mutations, me) {
            if (document.head) {               
                me.disconnect(); // 停止观察
                injectStyles();
            }
        });

        // 开始观察 <html> 元素的子元素变化
        observer.observe(document.documentElement, {
            childList: true,
            subtree: true
        });
    }

    // 样式注入函数
    function injectStyles() {
        var styleElem = null,
            doc = document,
            fontColor = 80;

        // 设置 .AnswerItem-time 和 .ExtraInfo 保持原字体颜色
        styleElem = createCSS('.AnswerItem-time *, .ExtraInfo *', 'color: inherit !important;', styleElem);

        // 设置 .GifPlayer-icon 及其内部的所有子元素背景透明
        styleElem = createCSS('.GifPlayer-icon, .GifPlayer-icon *', 'background-color: transparent !important;', styleElem);

        // 设置其他元素的新字体颜色和背景颜色
        styleElem = createCSS('body, body *', 'background-color: #' + appbackgroudc + ' !important; color: RGB(' + fontColor + '%,' + fontColor + '%,' + fontColor + '%) !important;', styleElem);
    }

    function createCSS(sel, decl, styleElem) {
       var doc = document,
           h = doc.getElementsByTagName("head")[0],
           styleElem = styleElem || doc.createElement("style");

       styleElem.setAttribute("type", "text/css");
  
       // 非 IE 的处理方式
       h.appendChild(styleElem);
       styleElem.appendChild(doc.createTextNode(sel + " {" + decl + "}"));
       // IE 的处理方式已移除 因为用不到
       return styleElem;
   }
})();