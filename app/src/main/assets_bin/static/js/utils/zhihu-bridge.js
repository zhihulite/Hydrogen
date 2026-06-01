// utils/zhihu-bridge.js - 知乎原生桥接代理
(() => {
    const sendCallback = (callbackData) => {
        if (window.zhihuWebApp && typeof window.zhihuWebApp.callback === 'function') {
            setTimeout(() => {
                window.zhihuWebApp.callback(callbackData);
            }, 1);
        }
    };

    const successCallback = (id, params) => {
        sendCallback({ id, type: "success", params: params || {} });
    };

    const failCallback = (id, params) => {
        sendCallback({ id, type: "fail", params: params || {} });
    };

    const handleAction = (data) => {
        const { action, callbackID: id, params = {} } = data;

        switch (action) {
            case "getZLabAbValues": {
                const values = params.paramKeys.map(key => ({ paramKey: key, value: "0" }));
                successCallback(id, { values });
                break;
            }
            case "supportAction": {
                const supported = ['showAlert', 'showCommentList'].some(k => action.includes(k));
                successCallback(id, { isSupported: supported });
                break;
            }
            case "showAlert": {
                const result = confirm(params.content);
                successCallback(id, { result: result ? "AFFIRM" : "DISMISS" });
                break;
            }
            case "handleAuthRequiredAction":
                alert("执行操作失败 请检查是否处于登录状态");
                break;
            case "openURL":
                window.location.href = params.url;
                break;
            case "setShareInfo":
                successCallback(id, { successType: Object.keys(params) });
                break;
            case "checkSupportedShareType":
                successCallback(id, { QQ: false, Qzone: false, weibo: false, wechat: false });
                break;
            case "shareLongImage":
                alert("Hydrogen 暂不支持图片分享");
                successCallback(id);
                break;
            case "showCollectionPanel":
                HydrogenCore.api.sendMessage('showCollection', id);
                break;
            case "checkHadViewAppeared":
                successCallback(id, { hadViewAppeared: true });
                break;
            case "getCurrentTheme":
                successCallback(id, { theme: "light" });
                break;
            case "getPageLifecycleStatus":
                successCallback(id, { show: true });
                break;
            case "showToast":
                HydrogenCore.api.toast(params.text);
                successCallback(id);
                break;
            case "showLoginDialog":
                failCallback(id, { name: "ERR_ACOUNT_NOTGUEST", message: "已登录" });
                break;
            case "showCommentList": {
                const match = window.location.href.match(/\/section\/(\d+)(?:\/|$)/);
                if (match && match[1]) {
                    window.location.href = `https://www.zhihu.com/comment/list/paid_column_section_manuscript/${match[1]}`;
                } else {
                    alert("获取id失败，目前仅支持收费专栏链接");
                }
                successCallback(id);
                break;
            }
            case "showShareActionSheet":
            case "shareGoldenSentences":
                alert("Hydrogen 暂不支持在网页内分享");
                break;
            case "closeCurrentPage":
                alert("Hydrogen 暂不支持在网页内返回");
                break;
            case "askQuestion":
                alert("Hydrogen 暂不支持在网页内提问");
                break;
            case "writeAnswer":
                alert("Hydrogen 暂不支持在网页内回答");
                break;
            case "showCatalog":
                alert("目录显示TODO中(懒得做了😋)");
                break;
            // 忽略以下动作
            case "log":
            case "setAssetStatus":
            case "trackZA":
            // 好像没什么用，需要在 params 传入 HybridConfig
            case "getHybridConfig":
            // 未知，看名字像获取广告推广信息
            case "getAdPromotion":
            case "getContentSign":
            // 未知，好像是获取引导图。格式：params 传入 "imgUrls":[]
            case "getGuidingImgUrl":
            // 软件自己处理打开图片，不需要处理
            case "openImage":
                break;
            default:
                successCallback(id);
        }
    };

    window.zhihuNativeApp = new Proxy({}, {
        get(target, prop) {
            if (prop === 'sendToNative') {
                return (arg) => {
                    try {
                        const data = JSON.parse(arg);
                        console.log("sendToNative:", data.action, data);
                        handleAction(data);
                    } catch (e) {
                        console.error("Invalid JSON in sendToNative", e);
                    }
                };
            }
            return () => {
                console.log(`${prop} 被触发`, arguments);
            };
        }
    });

    // 专栏页面禁用 selectionchange
    if (window.location.href.includes("www.zhihu.com/appview/p/")) {
        const originalAddEventListener = EventTarget.prototype.addEventListener;
        EventTarget.prototype.addEventListener = function (type, listener, options) {
            if (type === 'selectionchange') {
                originalAddEventListener.call(this, type, () => { }, options);
            } else {
                originalAddEventListener.call(this, type, listener, options);
            }
        };
    }

    // 登录检查
    window.addEventListener('load', () => {
        if (document.documentElement.innerText?.includes("请求存在异常")) {
            alert("知乎限制只能登录后访问，请检查是否登录账号");
        }
    });

    const ZhihuBridge = {
        name: 'ZhihuBridge',
        send: sendCallback,
        success: successCallback,
        fail: failCallback
    };

    window.ZhihuBridge = ZhihuBridge;
})();