// pin.js - 想法页面
(() => {
    const PinPage = {
        name: 'PinPage',

        init() {
            this.injectStyles();
            this.initVideo();
        },

        injectStyles() {
            StyleManager.addBatch({
                'pin-fix': [
                    '.css-0 > *:first-child { padding-top: unset !important; }',
                    '.MobileAppHeader { display: none !important; }'
                ].join('\n')
            });
        },

        initVideo() {
            DomHelper.onElement('#js-initialData', (el) => {
                DomHelper.onElement('.RichText', (richtext) => {
                    this.insertVideo(el, richtext);
                });
            });
        },

        insertVideo(initialDataEl, richtext) {
            try {
                const data = JSON.parse(initialDataEl.innerText);
                const briefs = data.initialState?.briefs;
                if (!briefs) return;

                const idMap = briefs.entityId2ContentIdMap || {};
                const ids = Object.values(idMap);
                const id = ids[0];
                const videoData = briefs[id]?.video;

                if (videoData?.playlist) {
                    const playlists = Object.values(videoData.playlist);
                    const videoUrl = playlists[0]?.url;
                    
                    if (videoUrl) {
                        const videoContainer = document.createElement('div');
                        videoContainer.innerHTML = `<video controls style="width:100%" src="${videoUrl}"></video>`;
                        richtext.insertBefore(videoContainer, richtext.firstChild);
                    }
                }
            } catch (e) {
                console.error(`Pin video insert error: ${e.message}`);
            }
        }
    };

    window.PinPage = PinPage;
})();