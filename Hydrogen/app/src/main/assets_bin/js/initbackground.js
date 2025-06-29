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
        var styleElem = null

        // 设置其他元素的新字体颜色和背景颜色
        // appbackgroudc为软件backgroudc 加载js时会替换 如果调用需要赋值 apppbackgroudc 哦
        // CommentSection 评论区 Toolbar 底部栏 skeleton预加载 AuthorCard 用户卡片 PostIndex-Footer 文章底部
        styleElem = createCSS('body,body > div:not([class]):not([id]) *, root, .AppMain,  .AppMain > div, .CommentSection , .CommentSection, .skeleton, .Toolbar, .AuthorCard-wrapper > div, .PostIndex-Footer *', 'background-color: #' + appbackgroudc + ' !important;', styleElem);
    
        // 设置 文章下反馈 .css-1kvz3a2 遮罩 bottom-shadow 无背景
        styleElem = createCSS('.css-1kvz3a2,.bottom-shadow', 'background: unset !important;')
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