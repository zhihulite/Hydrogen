// features/video-answer.js - 视频回答处理
(() => {
    const VideoAnswer = {
        name: 'VideoAnswer',
        videoUrl: null,

        init() {
            if (HydrogenCore.getConfig('videoAnswer') === false) return;
            if (!this.videoUrl) return;

            DomHelper.onElement('.ExtraInfo', (extraInfo) => this.process(extraInfo));
        },

        setVideoUrl(url) {
            this.videoUrl = url;
        },

        process(extraInfo) {
            if (extraInfo.querySelector('.video-answer-tip')) return;

            // 插入提示文本
            const tip = document.createElement('div');
            tip.className = 'ExtraInfo video-answer-tip';
            tip.innerText = '该回答为视频回答';
            extraInfo.insertBefore(tip, extraInfo.firstChild);

            // 插入视频播放器
            const videoHtml = document.createElement('div');
            videoHtml.className = 'video-box';
            videoHtml.innerHTML = `<video style="width:100%" src="${this.videoUrl}" controls></video>`;

            const richtext = document.querySelector('.RichText.ztext');
            if (richtext && richtext.firstChild) {
                richtext.insertBefore(videoHtml, richtext.firstChild);
            }
        }
    };

    window.VideoAnswer = VideoAnswer;
})();