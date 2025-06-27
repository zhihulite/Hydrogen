(function () {
    var styleElem = null,
        doc = document,
        ie = doc.all,
        fontColor = 80;

    // 设置 .AnswerItem-time 和 .ExtraInfo 保持原字体颜色
    styleElem = createCSS('.AnswerItem-time *, .ExtraInfo *', 'color: inherit !important;', styleElem);

    // 设置 .GifPlayer-icon 及其内部的所有子元素透明色
    styleElem = createCSS('.GifPlayer-icon, .GifPlayer-icon *', 'background-color: transparent !important;', styleElem);

    // 设置其他元素的新字体颜色和背景颜色
    // appbackgroudc为软件backgroudc 加载js时会替换 如果调用需要赋值 apppbackgroudc 哦
    styleElem = createCSS('body, body *', 'background-color: #' + appbackgroudc + ' !important; color: RGB(' + fontColor + '%,' + fontColor + '%,' + fontColor + '%) !important;', styleElem);

    function createCSS(sel, decl, styleElem) {
        var doc = document,
            h = doc.getElementsByTagName("head")[0],
            styleElem = styleElem || doc.createElement("style");

        styleElem.setAttribute("type", "text/css");
        if (ie) {
            // IE 的处理方式
            doc.styleSheets[doc.styleSheets.length - 1].addRule(sel, decl);
        } else {
            // 非 IE 的处理方式
            h.appendChild(styleElem);
            styleElem.appendChild(doc.createTextNode(sel + " {" + decl + "}"));
        }
        return styleElem;
    }
})();