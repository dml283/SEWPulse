
function ManageClearButtonR(targetID) {
	var target = document.getElementById(targetID);
	if (target != null) {
		FindSetClearButtonVisibility(target, target.value != null && target.value.length > 0);
	}
}

function CopyListValueToTargetR(inputListID, targetID) {
	var inputList = document.getElementById(inputListID);
	var target = document.getElementById(targetID);
	if (inputList != null && target != null && inputList.value != null && inputList.value.length > 0) {
		var newText = inputList.value;
		if (newText == null || newText.length == 0) {
			return;
		}

		var text = target.value;
		if (text == null) {
			text = '';
		} else if (text.length > 0) {
			text += ',';
		}

		var posColon = newText.indexOf(':');
		if (posColon > 0) {
			newText = newText.substring(0, posColon);
		}
		text += newText;
		target.value = text;
		FindSetClearButtonVisibility(target, true);
	}
}

function DoClearR(targetID) {
	var target = document.getElementById(targetID);
	if (target != null) {
		target.value = ''; 
		FindSetClearButtonVisibility(target, false);
	}
}

function FindSetClearButtonVisibility(target, tobeVisibile) {
	while ((target = target.nextSibling) != null) {
		if (target.tagName != null && target.tagName.toLowerCase() == "input" && target.type.toLowerCase() == "button" && target.id == "clearbtn") {
			var vis = tobeVisibile ? 'visible' : 'hidden';
			target.style.visibility = vis;
			break;
		}
	}
}

function endsWith(testString, endingString){
      if(endingString.length > testString.length) return false;
      return testString.lastIndexOf(endingString)==(testString.length-endingString.length);
}

function initial_setup() {
	var sels = document.getElementsByTagName("SELECT");
	for (var i = 0; i < sels.length; ++i) {
		var sel = sels[i];
		if (sel != null && (endsWith(sel.id, ':im__isf') || endsWith(sel.id, ':om__ptof'))) {
			sel.selectedIndex = 0;
		}
	}
	
	var inps = document.getElementsByTagName("INPUT");
	for (var i = 0; i < inps.length; ++i) {
		var inp = inps[i];
		if (inp != null && inp.type == "text" && (endsWith(inp.id, ':im__isfdc') || endsWith(inp.id, ':om__ptdc'))) {
			FindSetClearButtonVisibility(inp, inp.value != null && inp.value.length > 0);
		}
	}
}

	//Popup on load
	// for Mozilla browsers
	if (this.addEventListener) 
	{
	  this.addEventListener("load", initial_setup, false);
	}
	else if (document.addEventListener) 
	{
	  document.addEventListener("load", initial_setup, false);
	}	
	// IE
	else if (window.attachEvent)
	{
		window.attachEvent("onload", initial_setup);
		window.attachEvent("unload", function()
			{
				window.detachEvent("onload", initial_setup);
			});
	}
	else
		document.onload = initial_setup;
