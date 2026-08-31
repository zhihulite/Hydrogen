// fade-animation.js - 淡入动画
(() => {
    const FadeAnimation = {
        name: 'FadeAnimation',

        init() {
            if (window.__fadeAnimationInited) return;
            window.__fadeAnimationInited = true;

            const css = [
                '@keyframes customFadeIn {',
                '    from { opacity: 0; }',
                '    to { opacity: 1; }',
                '}',
                '.ztext, .RichText, .video-box, .VideoCard, .AnswerVideo {',
                '    animation: customFadeIn 0.1s ease-out !important;',
                '}',
                'img {',
                '    animation: customFadeIn 0.2s ease-in-out !important;',
                '}'
            ].join('\n');

            StyleManager.add('fade-animation', css);
        }
    };

    window.FadeAnimation = FadeAnimation;
})();