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

        // 设置其他元素的新字体颜色和背景颜色
        styleElem = createCSS('body, body *', 'background-color: #' + appbackgroudc + ' !important; color: RGB(' + fontColor + '%,' + fontColor + '%,' + fontColor + '%) !important;', styleElem);

        // 设置 .ztext-math 及其子元素背景透明，防止 body * 的背景色覆盖
        // 必须放在 body * 后面以覆盖样式
        styleElem = createCSS('.ztext-math, .ztext-math *', 'background-color: transparent !important;', styleElem);

        // 仅对公式图片进行反色处理
        // 必须放在 body * 后面，确保 background-color 是 transparent，这样 invert 只主要反转前景内容
        styleElem = createCSS('.ztext-math img, img[src*="equation"], .ztext-math svg, img.ztext-math', 'filter: invert(1) !important; background-color: transparent !important;', styleElem);
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