(function () {

    function init() {
        const isZhihuPage = window.location.hostname.includes('zhihu.com');
        const isLocalPage = window.location.href.startsWith("about:/") || window.location.href.startsWith("file://");


        const match = window.location.pathname.match(/\/appview\/(.*?)\//);
        const AppViewType = match ? match[1] : null;

        function getImgs() { 
            return document.querySelectorAll("img")
        }

        function isImageIsEnabled() {
            return true
        }

        if (isZhihuPage && AppViewType) {
            switch (AppViewType) {
                case "pin":
                    getImgs = function () {
                        return document.querySelectorAll(".pin-header-image")
                    }
                    isImageIsEnabled = function (doc) {
                        return document.querySelector(".css-0").contains(doc)
                    }
                    break
                case "answer": case "p":
                    getImgs = function () {
                        return document.querySelector(".RichText").querySelectorAll("img")
                    }
                    isImageIsEnabled = function (doc) {
                        return document.querySelector(".RichText").contains(doc)
                    }
                    break
            }
        }

        if (isLocalPage) {
            if (document.querySelector(".pin-header-image")) {
                getImgs = function () {
                    return document.querySelectorAll(".pin-header-image")
                }
                isImageIsEnabled = function (doc) {
                    return document.querySelector(".css-0").contains(doc)
                }
            } else if (document.querySelector(".RichText")) {
                getImgs = function () {
                    return document.querySelector(".RichText").querySelectorAll("img")
                }
                isImageIsEnabled = function (doc) {
                    return document.querySelector(".RichText").contains(doc)
                }
            }
        }

        function getSrc(doc) {
            if (isLocalPage) return doc.src
            return doc.getAttribute("data-original-token") || doc.src;

        }

        function replaceSrcWithGif(src) {
            return src.replace(/(\.\w+)(\?.*)?$/, ".gif$2");
        }

        function getImageIndexAndSrc(eleSrc) {
            console.log("getting img");
            const images = Array.from(getImgs()).filter(function (element) {
                return element.style.display !== 'none';
            });
            const imageInfo = {};

            for (let index = 0; index < images.length; index++) {
                let src = getSrc(images[index]);

                if (isZhihuPage && images[index].parentNode.className.includes("GifPlayer")) {
                    src = replaceSrcWithGif(src);
                }

                imageInfo[index] = src;

                if (images[index].src === eleSrc) {
                    imageInfo[images.length] = index;
                }
            }

            return imageInfo;
        }


        function checkClickTarget(event) {
            let target = event.target;
            console.log(target)


            if (target.tagName.toLowerCase() === 'div' || target.tagName.toLowerCase() === 'video') {
                while (target && target.tagName.toLowerCase() !== 'body') {
                    const parent = target.parentElement;

                    if (parent && Math.abs(target.clientWidth - parent.clientWidth) <= 5 &&
                        Math.abs(target.clientHeight - parent.clientHeight) <= 5) {

                        const img = parent.querySelector('img:first-child');
                        if (img && Math.abs(img.clientHeight - parent.clientHeight) <= 5) {
                            return img;
                        }
                    } else {
                        break;
                    }

                    target = target.parentElement;
                }
            }
            return event.target;
        }

        document.addEventListener('click', function (event) { // 判断点击的目标是否为img元素 
            let doc = event.target
            if (isImageIsEnabled(doc) == false) return
                        
            if (doc.tagName !== 'IMG') {
                doc = checkClickTarget(event)
            }
            if (isZhihuPage) {
                if (doc.parentNode.className.includes("GifPlayer")) {
                    // 禁止父元素接受事件
                    doc.parentNode.style.pointerEvents = "none"
                    doc.src = replaceSrcWithGif(doc.src);
                    doc.dataset.original = doc.src;
                    event.stopPropagation()
                    let children = doc.parentNode.children
                    for (var i = 0; i < children.length; i++) {
                        if (children[i].tagName != "IMG") {
                            children[i].style.display = "none"
                            children[i].style.pointerEvents = "none"
                        }
                    }
                    doc.parentNode.className = doc.parentNode.className.replace("GifPlayer", "")
                    return false
                }
            }
            if (doc.tagName === 'IMG') {
                window.androlua.execute(JSON.stringify(getImageIndexAndSrc(doc.src)));
            }
        }, true);
    }
    
    window.addEventListener("load", init)

})();