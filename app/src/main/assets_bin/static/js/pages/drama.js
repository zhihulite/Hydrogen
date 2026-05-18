// drama.js - 直播页面
(() => {
    const DramaPage = {
        name: 'DramaPage',

        init() {
            this.injectStyles();
            this.initVideoControls();
            this.initActorEvents();
        },

        injectStyles() {
            StyleManager.addBatch({
                'drama-fix': [
                    '.TheaterRoomHeader-temperature { pointer-events: none !important; }',
                    '.TheaterToolbar { display: none !important; }',
                    '.TheaterMessageList { margin-bottom: 10px !important; }',
                    '.TheaterMessage { pointer-events: none !important; }',
                    '.Theater-core { max-height: unset !important; height: 100vh !important; }',
                    '.MobileAppHeader, .Sticky--holder { display: none !important; }'
                ].join('\n')
            });
        },

        initVideoControls() {
            const video = document.querySelector('.LiveStreamPlayer-video');
            if (video) video.controls = true;
        },

        initActorEvents() {
            const actorElement = document.querySelector('.TheaterRoomHeader-actor');
            if (!actorElement) return;

            // 重新渲染以解绑原有事件
            actorElement.outerHTML = actorElement.outerHTML;
            
            const newActor = document.querySelector('.TheaterRoomHeader-actor');
            if (newActor && newActor.childNodes[1]) {
                newActor.childNodes[1].addEventListener('click', (e) => {
                    e.stopPropagation();
                    console.log('查看用户');
                });
            }
        }
    };

    window.DramaPage = DramaPage;
})();