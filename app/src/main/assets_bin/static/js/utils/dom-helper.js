// utils/dom-helper.js
(() => {
    const DomHelper = {
        name: 'DomHelper',

        emulateClick(element) {
            if (!element) return;
            element.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
        },

        emulateInput(element, value) {
            if (!element) return;
            const lastValue = element.value;
            element.value = value;
            const tracker = element._valueTracker;
            if (tracker) tracker.setValue(lastValue);
            element.dispatchEvent(new Event('input', { bubbles: true }));
        },

        emulateMouseOver(element) {
            if (!element) return;
            const event = new MouseEvent('mouseover', { bubbles: true, cancelable: true });
            element.dispatchEvent(event);
        },

        emulateMouseOut(element) {
            if (!element) return;
            const event = new MouseEvent('mouseout', { bubbles: true, cancelable: true });
            element.dispatchEvent(event);
        },

        query(selector, parent = document) {
            return parent.querySelector(selector);
        },

        queryAll(selector, parent = document) {
            return Array.from(parent.querySelectorAll(selector));
        },

        addStyle(css, id) {
            const existing = id && document.getElementById(id);
            if (existing) {
                existing.textContent = css;
                return existing;
            }
            const style = document.createElement('style');
            if (id) style.id = id;
            style.textContent = css;
            document.head.appendChild(style);
            return style;
        },

        remove(element) {
            if (element?.parentNode) element.parentNode.removeChild(element);
        },

        hide(element) {
            if (element) element.style.display = 'none';
        },

        show(element) {
            if (element) element.style.display = '';
        },

        on(element, event, handler) {
            if (element) element.addEventListener(event, handler);
        },

        observe(target, config, callback) {
            if (!target || !config || !callback) return null;
            const observer = new MutationObserver(callback);
            observer.observe(target, config);
            return observer;
        },

        onElement(selector, callback, options = {}) {
            const { once = true, interval = 300, maxWait = 10000 } = options;
            const seen = new WeakSet();
            const startTime = Date.now();

            const id = setInterval(() => {
                let found = false;
                for (const el of document.querySelectorAll(selector)) {
                    if (seen.has(el)) continue;
                    seen.add(el);
                    callback(el);
                    found = true;
                    if (once) clearInterval(id);
                }

                const timeout = Date.now() - startTime >= maxWait;
                if ((once && found) || timeout) clearInterval(id);
            }, interval);
        }
    };

    window.DomHelper = DomHelper;
})();