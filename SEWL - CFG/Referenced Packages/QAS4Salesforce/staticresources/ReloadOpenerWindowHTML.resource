<html>
<head><title>Pasting...</title>
<script language="javascript">

function ReloadOpener() {
    try {
        // Seems slow when refreshing with reload, but setting to itself seems better...
    	//self.opener.location.reload();
    	//self.opener.location.reload(true);
    	//self.opener.location.reload(false);

    	self.opener.location.href = self.opener.location.href;
    }
    catch(e) {
        alert('Please refresh the original Salesforce page so it displays the new address.\r\n' + e);
    }
	self.close();
}

</script>
</head>
<body onload="ReloadOpener();">
</body>
</html>
