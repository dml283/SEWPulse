// Open a popup (child window) which can close itself & refresh the parent afterwards
// (via a page from the correct SF domain)
function QASDisplayPopup(obj) {
	if (!('id' in obj)) {
		alert('You must define an \'id\' parameter when calling PopupWithReloadHelper');
		return;
	}
	if (!('touchpoint' in obj)) {
		alert('You must define a \'touchpoint\' parameter when calling PopupWithReloadHelper');
		return;
	}
	if('autoVerify' in obj){
		//Change the nav URL property so that it now appends the details of the parent url to the end
		popupWin = window.open('/apex/experianqas__QASPopup?id='+obj.id+'&navUrl=x,' + encodeURIComponent(window.location.href)+'&tp='+obj.touchpoint,
			'_blank', 'width=775,height=420,status=yes,toolbar=no,menubar=no');
		
	}
	else
	{
		//Change the nav URL property so that it now appends the details of the parent url to the end
		popupWin = window.open('/apex/experianqas__QASPopup?id='+obj.id+'&navUrl=x,' + encodeURIComponent(window.location.href) +'&isLaunchButton=true' +'&tp='+obj.touchpoint,
			'_blank', 'width=775,height=420,status=yes,toolbar=no,menubar=no');
	}
}

// Old name for QASDisplayPopup
function PopupWithReloadHelper(obj) {
	QASDisplayPopup(obj);
}

// Add a CSS file in dynamically
function loadcssfile(filename){
	var fileref=document.createElement("link");
	fileref.setAttribute("rel", "stylesheet");
	fileref.setAttribute("type", "text/css");
	fileref.setAttribute("href", filename);
	if (typeof fileref != "undefined") {
		document.getElementsByTagName("head")[0].appendChild(fileref);
	}
}

// Open a Thickbox (JavaScript Lightbox) which can close itself & refresh the parent afterwards
function QASDisplayLightbox(obj) {
    if (!('id' in obj)) {
        alert('You must define an \'id\' parameter when calling DisplayQASPopup');
        return;
    }
    if (!('touchpoint' in obj)) {
        alert('You must define a \'touchpoint\' parameter when calling DisplayQASPopup');
        return;
    }
    
    // TODO: Store CSS in VF page or doc?
    loadcssfile('/resource/1250699948000/experianqas__Thickbox31css'); //dynamically load and add this .css file   
    
    if('autoVerify' in obj){
    	tb_show('QAS for salesforce.com - Address Capture', '/apex/experianqas__QASPopup?id='+obj.id+'&tp='+obj.touchpoint+'&navUrl='+
        encodeURIComponent(window.location.href)+'&TB_iframe=true&height=410&width=775&');
    
    	
    }
    else{
    	tb_show('QAS for salesforce.com - Address Capture', '/apex/experianqas__QASPopup?id='+obj.id+'&tp='+obj.touchpoint+'&navUrl='+
        encodeURIComponent(window.location.href)+'&isLaunchButton=true'+'&TB_iframe=true&height=410&width=775');
    }
}