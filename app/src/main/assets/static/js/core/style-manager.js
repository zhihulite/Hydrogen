// style-manager.js
(() => {
    const StyleManager = {
        name: 'StyleManager',
        styles: new Map(),

        add(name, css, priority = false) {
            if (this.styles.has(name)) {
                this.update(name, css);
                return;
            }

            const style = document.createElement('style');
            style.id = `app-style-${name}`;
            style.textContent = css;

            if (priority && document.head.firstChild) {
                document.head.insertBefore(style, document.head.firstChild);
            } else {
                document.head.appendChild(style);
            }

            this.styles.set(name, style);
        },

        update(name, css) {
            const style = this.styles.get(name);
            if (style) style.textContent = css;
        },

        addBatch(styles) {
            for (const [name, css] of Object.entries(styles)) {
                this.add(name, css);
            }
        },

        remove(name) {
            const style = this.styles.get(name);
            if (style?.parentNode) {
                style.parentNode.removeChild(style);
                this.styles.delete(name);
            }
        },

        has(name) {
            return this.styles.has(name);
        },

        clear() {
            for (const name of this.styles.keys()) {
                this.remove(name);
            }
        }
    };

    window.StyleManager = StyleManager;
})();