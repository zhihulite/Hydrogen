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
            scrollThreshold: 5,
            maxPollingMs: 5000
        },

        db: null,
        lastPosition: 0,
        debounceTimer: null,
        pollingTimer: null,
        pollingStartTime: null,

        log(...args) {
            console.log('[ScrollRestore]', ...args);
        },
        warn(...args) {
            console.warn('[ScrollRestore]', ...args);
        },

        init() {
            if (!window.indexedDB) {
                this.warn('不支持 IndexedDB');
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
                this.log('初始化完成');
            };

            request.onerror = () => {
                this.warn('数据库打开失败');
            };
        },

        getCurrentKey() {
            return window.location.href;
        },

        // 保存滚动位置（无限制，直接保存）
        save() {
            if (!this.db) return;

            const transaction = this.db.transaction([this.config.storeName], 'readwrite');
            const store = transaction.objectStore(this.config.storeName);
            store.put({
                url: this.getCurrentKey(),
                position: window.scrollY,
                timestamp: Date.now()
            });
            this.log(`保存: ${window.scrollY}`);
        },

        getDocumentHeight() {
            return Math.max(
                document.body.scrollHeight,
                document.documentElement.scrollHeight,
                document.body.offsetHeight,
                document.documentElement.offsetHeight
            );
        },

        scrollToPosition(position, options) {
            const behavior = options.behavior || 'smooth';
            window.scrollTo({ top: position, behavior: behavior });
            this.log(`滚动到: ${position}`);
        },

        checkAndRestore(targetPosition, options) {
            const currentHeight = this.getDocumentHeight();
            
            this.log(`目标: ${targetPosition}, 高度: ${currentHeight}`);
            
            if (currentHeight <= targetPosition) {
                const maxPollingMs = options.maxPollingMs !== undefined ? options.maxPollingMs : this.config.maxPollingMs;
                this.log(`高度不足, 轮询 ${maxPollingMs}ms`);
                this.startPolling(targetPosition, options);
            } else {
                this.scrollToPosition(targetPosition, options);
            }
        },

        startPolling(targetPosition, options) {
            if (this.pollingTimer) clearInterval(this.pollingTimer);
            
            const maxPollingMs = options.maxPollingMs !== undefined ? options.maxPollingMs : this.config.maxPollingMs;
            this.pollingStartTime = Date.now();
            
            this.pollingTimer = setInterval(() => {
                const currentHeight = this.getDocumentHeight();
                const elapsed = Date.now() - this.pollingStartTime;
                
                if (currentHeight > targetPosition || elapsed >= maxPollingMs) {
                    clearInterval(this.pollingTimer);
                    this.pollingTimer = null;
                    
                    if (currentHeight > targetPosition) {
                        this.log(`轮询完成, 高度: ${currentHeight}`);
                        this.scrollToPosition(targetPosition, options);
                    } else {
                        this.log(`轮询超时, 删除记录`);
                        this.deleteCurrent();
                    }
                } else {
                    this.log(`轮询中... 高度: ${currentHeight}, 目标: ${targetPosition}, 已过: ${elapsed}ms`);
                }
            }, 100);
        },

        restore(options) {
            if (!this.db) {
                this.warn('数据库未初始化');
                return;
            }

            options = options || {};
            // 延迟防止某些时候平滑滚动无效的问题。
            const delay = options.delay !== undefined ? options.delay : 100;

            const transaction = this.db.transaction([this.config.storeName], 'readonly');
            const store = transaction.objectStore(this.config.storeName);
            const request = store.get(this.getCurrentKey());

            request.onsuccess = () => {
                const data = request.result;
                if (data && data.position > 10) {
                    this.log(`找到记录: ${data.position}`);
                    setTimeout(() => {
                        this.checkAndRestore(data.position, options);
                    }, delay);
                } else {
                    this.log('未找到记录');
                    if (options.onNotFound) options.onNotFound();
                }
            };

            request.onerror = () => {
                this.warn('读取失败');
                if (options.onError) options.onError();
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
                        this.log(`删除过期: ${cursor.value.url}`);
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
            this.log('已删除当前记录');
        },

        deleteAll() {
            if (!this.db) return;
            const transaction = this.db.transaction([this.config.storeName], 'readwrite');
            const store = transaction.objectStore(this.config.storeName);
            store.clear();
            this.log('已删除所有记录');
        },

        destroy() {
            if (this.pollingTimer) {
                clearInterval(this.pollingTimer);
                this.pollingTimer = null;
            }
            if (this.debounceTimer) {
                clearTimeout(this.debounceTimer);
                this.debounceTimer = null;
            }
        }
    };

    window.ScrollRestore = ScrollRestore;
})();