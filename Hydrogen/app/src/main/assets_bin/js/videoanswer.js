function setmyvideo() {
	var videotext = document.createElement('div')
	videotext.className = "ExtraInfo"
	videotext.innerText = "该回答为视频回答"
	document.getElementsByClassName("ExtraInfo")[0].insertBefore(videotext, document.getElementsByClassName("ExtraInfo")[0].firstChild);
	var videourl = document.createElement('div')
	videourl.className = "video-box"
	videourl.innerHTML = '<video style="margin: auto;width: 100%;".." src="'+myvideourl+'" controls=""></video>'
	document.getElementsByClassName("RichText ztext")[0].insertBefore(videourl, document.getElementsByClassName("RichText ztext")[0].firstChild);
}
waitForKeyElements('.ExtraInfo', setmyvideo);