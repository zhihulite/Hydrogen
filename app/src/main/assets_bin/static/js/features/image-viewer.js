// image-viewer.js - 图片查看器
(() => {
    const ImageViewer = {
        name: 'ImageViewer',
        ALLOWED_GIF_TYPES: ['pin', 'answer', 'article'], // 'p' mapped to 'article' in Core

        init() {
            if (this.isDirectImagePage()) {
                this.openDirectImage();
                return;
            }

            this.pageType = HydrogenCore.getPageType();
            this.bindClickEvents();
        },

        isDirectImagePage() {
            return document.contentType && document.contentType.startsWith('image/');
        },

        openDirectImage() {
            HydrogenCore.api.openImages([window.location.href, 0]);
            HydrogenCore.api.finishPage();
        },

        getImagesInContext() {
            switch (this.pageType) {
                case 'pin':
                    return document.querySelectorAll('.pin-header-image');
                case 'answer':
                case 'article':
                    const richtext = document.querySelector('.RichText');
                    return richtext ? richtext.querySelectorAll('img') : [];
                default:
                    return document.querySelectorAll('img');
            }
        },

        getImageSrc(img) {
            const token = img.getAttribute('data-original-token');
            return token ? `https://pic1.zhimg.com/${token}` : img.src;
        },

        replaceSrcWithGif(src) {
            // 如果已经有 .gif 后缀或没有后缀，直接加 .gif
            if (!src.match(/\.(jpg|jpeg|png|webp|gif)/i)) {
                return src + '.gif';
            }
            // 有图片后缀，直接替换
            return src.replace(/\.(jpg|jpeg|png|webp)/i, '.gif');
        },

        isGifPlayerAllowed() {
            return this.ALLOWED_GIF_TYPES.includes(this.pageType);
        },

        findImageAtPoint(clientX, clientY) {
            // 只查找可见图片
            const allImages = document.querySelectorAll('img:not([style*="display:none"]):not([style*="visibility:hidden"])');

            for (let img of allImages) {
                const rect = img.getBoundingClientRect();
                // 检查点击坐标是否在图片范围内
                if (clientX >= rect.left && clientX <= rect.right &&
                    clientY >= rect.top && clientY <= rect.bottom) {
                    console.log(`命中图片: ${img.src.substring(0, 50)}...`);
                    return img;
                }
            }

            return null;
        },

        isGifPlayer(img) {
            return img.parentNode && img.parentNode.className.includes('GifPlayer');
        },

        // 检查 GIF 是否已经被播放过（已经替换为 .gif）
        isGifPlayed(img) {
            return img.src && img.src.includes('.gif');
        },

        isImageInValidContainer(element) {
            switch (this.pageType) {
                case 'pin': {
                    const container = document.querySelector('.css-0');
                    return container ? container.contains(element) : true;
                }
                case 'answer':
                case 'article': {
                    const richtext = document.querySelector('.RichText');
                    return richtext ? richtext.contains(element) : true;
                }
                default:
                    return true;
            }
        },

        // 播放 GIF（第一次点击）
        playGif(img) {
            const parent = img.parentNode;
            const gifSrc = this.replaceSrcWithGif(this.getImageSrc(img));

            // 替换为 GIF
            img.src = gifSrc;
            img.dataset.original = this.getImageSrc(img);

            // 禁止父元素接受事件
            parent.style.pointerEvents = 'none';

            // 直接删除播放按钮等元素（而不是隐藏）
            Array.from(parent.children).forEach(child => {
                if (child.tagName !== 'IMG') {
                    child.remove(); // 直接删除，知乎无法还原
                }
            });

            // 移除 GifPlayer 类，标记已播放
            parent.className = parent.className.replace('GifPlayer', '');
            parent.classList.add('GifPlayed');

            console.log('GIF 开始播放');
        },

        getVisibleImages() {
            return Array.from(this.getImagesInContext()).filter(img => img.style.display !== 'none');
        },

        bindClickEvents() {
            document.addEventListener('click', (event) => {
                // 只有真实用户点击才触发
                if (!event.isTrusted) return;

                const target = event.target;

                if (!this.isImageInValidContainer(target)) return;

                const img = this.findImageAtPoint(event.clientX, event.clientY);
                if (!img) return;

                // GIF 处理逻辑
                if (this.isGifPlayerAllowed() && this.isGifPlayer(img)) {
                    // 检查是否已经播放过
                    if (!this.isGifPlayed(img)) {
                        // 第一次点击：播放 GIF
                        this.playGif(img);
                        event.stopPropagation();
                        event.preventDefault();
                        return; // 不继续打开图片查看器
                    }
                    // 第二次及以后：已经播放过，继续往下走打开图片查看器
                }

                // 打开图片查看器（普通图片 或 已播放的 GIF）
                const images = this.getVisibleImages();
                const index = images.indexOf(img);
                if (index === -1) return;

                const imageUrls = images.map((i) => {
                    // 对于已播放的 GIF，使用当前 GIF 地址
                    if (this.isGifPlayerAllowed() && this.isGifPlayer(i) && this.isGifPlayed(i)) {
                        return i.src;
                    }
                    return this.getImageSrc(i);
                });

                HydrogenCore.api.openImages([...imageUrls, index]);
            }, true);
        }
    };

    window.ImageViewer = ImageViewer;
})();