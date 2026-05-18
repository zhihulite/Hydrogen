// features/screenshot.js - 截图功能
(() => {
    window.captureScreen = () => {
        if (typeof html2canvas === 'undefined') {
            HydrogenCore.api.screenshotError('html2canvas not loaded');
            return;
        }

        const maxHeight = Math.min(document.body.scrollHeight, 12000);

        html2canvas(document.body, {
            cacheBust: true,
            useCORS: true,
            allowTaint: true,
            logging: false,
            scale: window.devicePixelRatio || 1,
            scrollX: 0,
            scrollY: 0,
            width: document.documentElement.scrollWidth,
            height: maxHeight,
            onclone(doc) {
                const css = [
                    '* {',
                    '    text-rendering: auto !important;',
                    '    -webkit-font-smoothing: antialiased !important;',
                    '    font-variant-ligatures: none !important;',
                    '}',
                    'b, strong { background-color: transparent !important; }',
                    '.ztext, .RichText, .video-box, .VideoCard, .AnswerVideo,',
                    '.VOT-Container, .AnnotationTag, .LinkCard, .MCNCard, img {',
                    '    opacity: 1 !important;',
                    '    animation: none !important;',
                    '    transition: none !important;',
                    '}'
                ].join('\n');

                const style = doc.createElement('style');
                style.innerHTML = css;
                doc.head.appendChild(style);
            }
        })
            .then(canvas => {
                const base64 = canvas.toDataURL('image/jpeg', 0.92);
                const pureBase64 = base64.split(',')[1] || base64;
                HydrogenCore.api.sendMessage('screenshotResult', pureBase64);
            })
            .catch(e => {
                HydrogenCore.api.screenshotError(String(e));
            });
    };
})();