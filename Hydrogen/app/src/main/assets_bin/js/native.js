function sendZhihuWebAppCustomRequest(callbackData) {
    // 检查window.zhihuWebApp是否存在并调用callback方法
    if (window.zhihuWebApp && typeof window.zhihuWebApp.callback === 'function') {
        // 必须设置延迟 否则无效果
        setTimeout(function () {
            window.zhihuWebApp.callback(callbackData);
        }, 1);
    } else {
        console.error('Zhihu Web App API is not available.');
    }
}

function constructCallback(data) {
    // 构造新的params.values数组
    const values = data.params.paramKeys.map(key => ({ paramKey: key, value: "0" }));

    console.log(values)

    // 构建新的callback对象
    const callbackData = {
        id: data.callbackID,
        type: "success",
        params: {
            values: values
        }
    };

    sendZhihuWebAppCustomRequest(callbackData)

}

function notifySupportStatus(data) {
    const action = data.params.action
    const keywords = ['showAlert', 'showCommentList'];
    let isSupported = false
    if (keywords.some(keyword => action.includes(keyword))) {
        isSupported = true
    } else if (action == "handleAuthRequiredAction") {
        alert("执行操作失败 请检查是否处于登录状态 如果处于登录状态请尝试重新登录后执行该操作")
    }
    const callbackData = {
        id: data.callbackID,
        type: "success",
        params: { "isSupported": isSupported }
    };

    sendZhihuWebAppCustomRequest(callbackData)
}

function showConfirm(data) {
    const result = confirm(data.params.content);

    let callbackType = result ? "AFFIRM" : "DISMISS";
    const callbackData = {
        id: data.callbackID,
        type: "success",
        params: { "result": callbackType }
    };

    sendZhihuWebAppCustomRequest(callbackData)

}

function triggerZhihuWebAppSuccessCallback(data) {
    const callbackData = {
        id: data.callbackID,
        type: "success"
    };
    sendZhihuWebAppCustomRequest(callbackData)
}

// App段获取网页传入的分享类型
function setShareInfo(data) {
    // 不准备支持 或许后期会加上
    const values = Object.keys(data.params).map(key => (key));
    const callbackData = {
        id: data.callbackID,
        type: "success",
        params: {
            successType: values
        }
    };
    sendZhihuWebAppCustomRequest(callbackData)
}

// 网页段获取支持的分享类型
function checkSupportedShareType(data) {
    // 不准备支持 或许后期会加上
    const callbackData = {
        id: data.callbackID,
        type: "success",
        params: {
            QQ: false,
            Qzone: false,
            weibo: false,
            wechat: false
        }
    }
    sendZhihuWebAppCustomRequest(callbackData)
}

// 网页段分享按钮点击 例如 https://www.zhihu.com/appview/picture-share/p/698376677
function shareLongImage(data) {
    // 不准备支持 或许后期会加上
    alert("Hydrogen 暂不支持图片分享")
    triggerZhihuWebAppSuccessCallback(data)
}

// 网页端收藏 打印即可 App段接受打印数值
function showCollectionPanel(data) {
    console.log("收藏分割" + data.callbackID)
}

function checkHadViewAppeared(data) {
    // 不知道有什么用 直接返回true
    const callbackData = {
        id: data.callbackID,
        type: "success",
        params: {
            hadViewAppeared: true
        }
    }
    sendZhihuWebAppCustomRequest(callbackData)
}

function getCurrentTheme(data) {
    // 软件使用js设置夜间 不需要使用这个api
    const callbackData = {
        id: data.callbackID,
        type: "success",
        params: {
            theme: "light"
        }
    }
    sendZhihuWebAppCustomRequest(callbackData)
}

function getPageLifecycleStatus(data) {
    // 不知道有什么用 直接返回true
    const callbackData = {
        id: data.callbackID,
        type: "success",
        params: {
            show: true
        }
    }
    sendZhihuWebAppCustomRequest(callbackData)
}

// 解决付费专栏无法点击赞同
function showLoginDialog(data) {
    const callbackData = {
        id: data.callbackID,
        type: "fail",
        params: {
            name: "ERR_ACOUNT_NOTGUEST",
            message: "已登录"
        }
    }

    sendZhihuWebAppCustomRequest(callbackData)
}

function transformUrl(url) {
    // 匹配 /section/ 后接数字 ID 的路径
    const pattern = /\/section\/(\d+)(?:\/|$)/;
    const match = url.match(pattern);

    if (match && match[1]) {
        return `https://www.zhihu.com/comment/list/paid_column_section_manuscript/${match[1]}`;
    } else {
        const errorMsg = "获取id失败 目前仅支持收费专栏链接 请提供链接联系作者修复";
        console.warn(errorMsg);
        alert(errorMsg);
        return null;
    }
}

// 暂时测试只有付费专栏包含
function showCommentList(data) {
    const url=transformUrl(window.location.href)
    if (url) {
        window.location.href = url
    }
    triggerZhihuWebAppSuccessCallback(data)
}

function showToast(data) {
    console.log("toast分割" + data.params.text)
    triggerZhihuWebAppSuccessCallback(data)
}

// 打开图片
function openImage(data) {
    let params = data.params
    let images = params.image
    let index = params.index
    console.log(JSON.stringify(images))
    images.push(index)
    window.androlua.execute(JSON.stringify(images));
}


// supportEvent没什么需要为true
function supportEvent(data) {
    const action = data.params.action
    const keywords = [];
    let isSupported = false
    if (keywords.some(keyword => action.includes(keyword))) {
        isSupported = true
    }
    const callbackData = {
        id: data.callbackID,
        type: "success",
        params: { "isSupported": isSupported }
    };

    sendZhihuWebAppCustomRequest(callbackData)
}

// 创建Proxy来代理zhihuNativeApp对象
window.zhihuNativeApp = new Proxy({}, {
    get(target, prop, receiver) {

        if (prop === 'sendToNative') {
            return function (arg) {

                const keywords = ['log', 'setAssetStatus', 'trackZA'];
                const argObj = JSON.parse(arg)
                const action = argObj.action

                if (keywords.some(keyword => action === keyword)) {
                    return false
                }

                console.log("sendToNative被触发");
                console.log(argObj);

                const actionHandlers = {
                    "getZLabAbValues": constructCallback,
                    "supportAction": notifySupportStatus,
                    "showAlert": showConfirm,
                    // eslint-disable-next-line no-return-assign
                    "openURL": data => {
                        console.log("拦截到URL: " + data.params.url);
                        if (data.params.url.includes("comment")) {
                             console.log("显示评论");
                        } else {
                             window.location.href = data.params.url;
                        }
                    },
                    "setShareInfo": setShareInfo,
                    "checkSupportedShareType": checkSupportedShareType,
                    "shareLongImage": shareLongImage,
                    "showCollectionPanel": showCollectionPanel,
                    "checkHadViewAppeared": checkHadViewAppeared,
                    // 获取主题的
                    "getCurrentTheme": getCurrentTheme,
                    "getPageLifecycleStatus": getPageLifecycleStatus,
                    "showToast": showToast,
                    "showLoginDialog": showLoginDialog,
                    "showCommentList" : showCommentList,
                    // 暂不支持的操作
                    "showShareActionSheet": () => alert("Hydrogen 暂不支持在网页内分享"),
                    "shareGoldenSentences": () => alert("Hydrogen 暂不支持在网页内分享"),
                    "closeCurrentPage": () => alert("Hydrogen 暂不支持在网页内返回"),
                    "askQuestion": () => alert("Hydrogen 暂不支持在网页内提问"),
                    "writeAnswer": () => alert("Hydrogen 暂不支持在网页内回答"),
                    "showCatalog": () => alert("目录显示TODO中(懒得做了😋)"),
                    // 好像没什么用 在params传入HybridConfig
                    "getHybridConfig": () => { },
                    // 未知 看名字像获取广告推广信息
                    "getAdPromotion": () => { },
                    "getContentSign": () => { },
                    // 未知 好像是获取引导图 格式params传入 "imgUrls":[]
                    "getGuidingImgUrl": () => { },
                    // 软件自己处理打开图片 不需要
                    "openImage": () => { }
                };

                const handler = actionHandlers[action];
                if (typeof handler === 'function') {
                    handler(argObj);
                } else {
                    triggerZhihuWebAppSuccessCallback(argObj)
                }

            }
        }

        return function (...args) {
            console.log(prop + "被触发", args)
        }

    },
});

if (window.location.href.includes("www.zhihu.com/appview/p/")) {
    const originalAddEventListener = EventTarget.prototype.addEventListener;

    function handleSelectionChange(event) {
        return true;
    }

    // 重写 addEventListener 方法
    EventTarget.prototype.addEventListener = function (type, listener, options) {
        if (type === 'selectionchange') {
            originalAddEventListener.call(this, type, handleSelectionChange, options);
        } else {
            // 对于其他事件类型，直接调用原始的 addEventListener 方法
            originalAddEventListener.call(this, type, listener, options);
        }
    };
}

if (document.documentElement.innerText.includes("请求存在异常")) alert("知乎限制只能登录后访问 请检查是否登录账号 如果已登录 请注销后重新登录重试")