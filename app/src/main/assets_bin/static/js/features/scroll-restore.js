// scroll-restore.js - 滚动位置恢复
(() => {
    const ScrollRestore = {
        name: 'ScrollRestore',

        config: {
            dbName: 'scroll-position-db',
            storeName: 'scroll-position',
            dbVersion: 1,
            expirationPeriod: 10 * 24 * 60 * 60 * 1000, // 10 days
            debounceTime: 1000,
            scrollThreshold: 5
        },

        db: null,
        lastPosition: 0,
        debounceTimer: null,

        init() {
            if (!window.indexedDB) {
                alert('IndexedDB not supported');
                return;
            }
            this.openDB();
            this.bindScrollEvent();
            this.clearExpired();
        },

        openDB() {
            const request = indexedDB.open(this.config.dbName, this.config.dbVersion);

            request.onupgradeneeded = (event) => {
                const db = event.target.result;
                if (!db.objectStoreNames.contains(this.config.storeName)) {
                    db.createObjectStore(this.config.storeName, { keyPath: 'url' });
                }
            };

            request.onsuccess = (event) => {
                this.db = event.target.result;
                this.restore();
            };

            request.onerror = () => {
                alert('Failed to open DB');
            };
        },

        getCurrentKey() {
            return window.location.href;
        },

        save() {
            if (!this.db) return;

            const transaction = this.db.transaction([this.config.storeName], 'readwrite');
            const store = transaction.objectStore(this.config.storeName);
            store.put({
                url: this.getCurrentKey(),
                position: window.scrollY,
                timestamp: Date.now()
            });
        },

        restore() {
            if (!this.db) return;

            const transaction = this.db.transaction([this.config.storeName], 'readonly');
            const store = transaction.objectStore(this.config.storeName);
            const request = store.get(this.getCurrentKey());

            request.onsuccess = () => {
                const data = request.result;
                if (data && data.position > 10) {
                    window.scrollTo({ top: data.position, behavior: 'smooth' });
                }
            };
        },

        clearExpired() {
            if (!this.db) return;

            const now = Date.now();
            const expiration = this.config.expirationPeriod;
            const transaction = this.db.transaction([this.config.storeName], 'readwrite');
            const store = transaction.objectStore(this.config.storeName);
            const request = store.openCursor();

            request.onsuccess = (event) => {
                const cursor = event.target.result;
                if (cursor) {
                    if (cursor.value.timestamp < now - expiration) {
                        cursor.delete();
                    }
                    cursor.continue();
                }
            };
        },

        bindScrollEvent() {
            window.addEventListener('scroll', () => {
                const currentPosition = window.scrollY;
                if (Math.abs(currentPosition - this.lastPosition) > this.config.scrollThreshold) {
                    clearTimeout(this.debounceTimer);
                    this.debounceTimer = setTimeout(() => {
                        this.save();
                        this.lastPosition = currentPosition;
                    }, this.config.debounceTime);
                }
            });
        },

        deleteCurrent() {
            if (!this.db) return;
            const transaction = this.db.transaction([this.config.storeName], 'readwrite');
            const store = transaction.objectStore(this.config.storeName);
            store.delete(this.getCurrentKey());
        },

        deleteAll() {
            if (!this.db) return;
            const transaction = this.db.transaction([this.config.storeName], 'readwrite');
            const store = transaction.objectStore(this.config.storeName);
            store.clear();
        }
    };

    window.ScrollRestore = ScrollRestore;
})();