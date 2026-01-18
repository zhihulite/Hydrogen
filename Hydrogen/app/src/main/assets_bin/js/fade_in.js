(function() {
    if (window.fade_in_injected) return;
    window.fade_in_injected = true;
    var style = document.createElement('style');
    style.innerHTML = `
        @keyframes customFadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        /* 文字、视频、卡片等组件的极速淡入 */
        .ztext, .RichText, .video-box, .VideoCard, .AnswerVideo, .VOT-Container, .AnnotationTag, .LinkCard, .MCNCard {
            animation: customFadeIn 0.1s ease-out !important;
        }
        /* 图片加载时的淡入效果 */
        img {
            animation: customFadeIn 0.2s ease-in-out !important;
        }
    `;
    document.head.appendChild(style);
})();