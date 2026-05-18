// image-viewer.js - 图片查看器
(() => {
    const ImageViewer = {
        name: 'ImageViewer',
        ALLOWED_GIF_TYPES: ['pin', 'answer', 'article'], // 'p' mapped to 'article' in Core

        init() {
            this.pageType = HydrogenCore.getPageType();
            this.bindClickEvents();
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
            return src.replace(/(\.\w+)(\?.*)?$/, '.gif$2');
        },

        isGifPlayerAllowed() {
            return this.ALLOWED_GIF_TYPES.includes(this.pageType);
        },

        bindClickEvents() {
            document.addEventListener('click', (event) => {
                const target = event.target;
                if (!this.isImageInValidContainer(target)) return;

                let img = target.tagName === 'IMG' ? target : this.findImageInParent(target);
                if (!img || img.tagName !== 'IMG') return;

                // GIF播放器处理
                if (this.isGifPlayerAllowed() && this.isGifPlayer(img)) {
                    this.handleGifPlayer(img);
                }

                // 获取图片列表
                const images = this.getVisibleImages();
                const index = images.indexOf(img);
                if (index === -1) return;

                const imageUrls = images.map((i) => {
                    return this.isGifPlayer(i) ? this.replaceSrcWithGif(this.getImageSrc(i)) : this.getImageSrc(i);
                });

                HydrogenCore.api.openImages([...imageUrls, index]);
            }, true);
        },

        getVisibleImages() {
            return Array.from(this.getImagesInContext()).filter(img => img.style.display !== 'none');
        },

        isGifPlayer(img) {
            return img.parentNode && img.parentNode.className.includes('GifPlayer');
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

        handleGifPlayer(img) {
            const parent = img.parentNode;
            parent.style.pointerEvents = 'none';
            img.src = this.replaceSrcWithGif(img.src);
            img.dataset.original = img.src;

            Array.from(parent.children).forEach(child => {
                if (child.tagName !== 'IMG') {
                    child.style.display = 'none';
                    child.style.pointerEvents = 'none';
                }
            });

            parent.className = parent.className.replace('GifPlayer', '');
        },

        findImageInParent(target) {
            while (target && target.tagName !== 'BODY') {
                const parent = target.parentElement;
                if (parent &&
                    Math.abs(target.clientWidth - parent.clientWidth) <= 5 &&
                    Math.abs(target.clientHeight - parent.clientHeight) <= 5) {

                    const img = parent.querySelector('img:first-child');
                    if (img && Math.abs(img.clientHeight - parent.clientHeight) <= 5) {
                        return img;
                    }
                }
                target = parent;
            }
            return null;
        }
    };

    window.ImageViewer = ImageViewer;
})();