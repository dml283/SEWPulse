
.bodyDiv {
	background: #F2F2F2 !important;
}

/* DIV STYLES TO CENTER PAGE CONTENTS */
.shell900 {
   	overflow:visible;
    margin:auto;
    width:900px;
    font-family:Arial,Helvetica,Geneva,sans-serif;
    padding:0px;
    text-align:left;
    display:block;
}

.shell950 {
	overflow:visible;
    margin:auto;
    width:950px;
    font-family:Arial,Helvetica,Geneva,sans-serif;
    padding:0px;
    text-align:left;
    display:block;
}

.secondaryPalette.bPageBlock {
	border-left: 1px solid #C3C3C3;
	border-right: 1px solid #B9B9B9;
	border-bottom: 1px solid #B9B9B9;
	border-top: 1px solid #B9B9B9;
	padding-left: 10px;
	padding-right: 10px;
	padding-bottom: 15px;
	-moz-border-radius: 4px;
	-webkit-border-radius: 4px;
	border-radius: 4px;
	-moz-box-shadow: 1px 2px 2px rgba(0, 0, 0, 0.6);
	-webkit-box-shadow: 1px 2px 2px rgba(0, 0, 0, 0.6);
	box-shadow: 1px 2px 2px rgba(0, 0, 0, 0.6);
}

/* SECTION DIVIDER */
.pbSectionDivider {
	border-bottom: 1px #82c0cb solid;
	width: 100%;
	height: 2px;
	overflow: hidden;
}

/* PAGE BLOCK TITLE */
.pageBlockTitle {
	font-size:17pt;
	color: #005f98;
}

/*** PAGE BLOCK AND SECTION HEADERS ***/

/* padding around page block headers */
.bPageHeader .phHeader {
	padding: 5px 10px;
}

/* Page Block Header */
.bPageBlock .pbHeader {
	padding-bottom: 0px;
}

.bPageBlock .pbBody {
	padding-top: 10px;
    padding-left: 5px;
    padding-right: 0px;
}

.pageBlockHeader {
	height: 100%;
	color: #005F98;
	font-family: Arial, Helvetica, sans-serif;
	padding: 8px 5px;
	font-size: 17pt;
}

.first.pbSubheader {
	margin-top: 10px !important;
}

.pbSubheader {
	border-bottom: #82C0CB 1px solid !important;
	color: #464646 !important;
	padding: 0px !important;
	margin-bottom: 10px !important;
	font-size: 11pt !important;
	margin-left: 0px !important;
}

.pbSubheader H3 {
	color: #464646 !important;
}

/* HEADINGS AND SUBHEADINGS */
h1 {
	line-height: 25px;
    font-family:Arial,Helvetica,Geneva,sans-serif !important;
    font-weight:normal !important;
    font-size:14pt !important;
    color: #005F98 !important;
	border-bottom: #82C0CB 1px solid;
	display: block !important;
}

h2 {
	font-family:Arial,Helvetica,Geneva,sans-serif !important;
	font-weight:bold;
	font-size:10pt !important;
	padding-left: 3px;
	line-height:1.5;
}

/* TABLES */
.headerRowRight {
	text-align: right !important;
}

.headerRowLGBack {
	background-color: #f7f7f7;
}

.headerRowPeriod {
	padding-bottom: 2px !important;
	padding-top: 2px !important;
	width: 98px !important;
	vertical-align: middle !important;
}

.headerRowCentered {
	padding-bottom: 2px !important;
	padding-top: 2px !important;
	vertical-align: bottom !important;
	text-align: center !important;
}

.dataRowRight {
	padding-bottom: 4px !important;
	padding-top: 4px !important;
	padding-right: 5px !important;
	text-align: right !important;
}

.dataRowCentered {
	padding-bottom: 4px !important;
	padding-top: 4px !important;
	padding-right: 4px !important;
	text-align: center !important;
	vertical-align: middle !important;
}

/* MISC */

/* Info box with icon */
.informationBox,
.informationBoxRed,
.informationBoxNoIcon
 {
	background-repeat:no-repeat;
	background-position: 2px 2px;
	display: inline-block;
	font-weight: bold;
	padding-top: 3px;
	padding-bottom: 3px;
	padding-left: 20px;
	padding-right: 4px;
	font-size: 0.85em;
	margin-top: 4px;
	border-radius:3px;
	-webkit-border-radius:3px;
	-moz-border-radius:3px;
	-moz-box-shadow: 1px 2px 3px rgba(0, 0, 0, 0.4);
	-webkit-box-shadow: 1px 2px 3px rgba(0, 0, 0, 0.4);
	box-shadow: 1px 2px 3px rgba(0, 0, 0, 0.4);
	display:block;
	text-align: justify;
}

.informationBoxNoIcon { padding-left: 4px }

.informationBoxNoIcon,
.informationBox {
	background-color: #E5F1F8;
	border: 1px solid #005F98;
	color: #005F98;
}

.informationBox {
	background-image:url('https://c.ap1.content.force.com/servlet/servlet.ImageServer?id=015900000002SXa&oid=00D90000000KRNM');
}

.informationBoxRed {
	background-image:url('https://c.ap1.content.force.com/servlet/servlet.ImageServer?id=015900000002ZGI&oid=00D90000000KRNM');
	background-color: #FFC7CE;
	border: 1px solid #9C0006;
	color: #9C0006;
}

.informationBox ul,
.informationBoxNoIcon ul,
.informationBoxRed ul {
	list-style-type:disc;
	list-style-position:outside;
	margin-left: 0px;
	margin-top: 5px;
	margin-bottom: 5px;
	margin-right: 5px;
	padding-left: 0px;
}

.informationBox li,
.informationBoxNoIcon li,
.informationBoxRed li {
	margin:0 0 0 -20;
}

.btnLink {
	color: #fff !important;
	text-decoration: none !important;
	vertical-align: text-top !important;
	padding: 3px 12px 3px 12px !important;
}

.btnLink2 {
	color: #fff !important;
	text-decoration: none !important;
	vertical-align: text-top !important;
	padding: 4px 12px 5px 12px !important;
}

.exportToolbarContainer {
	float:right;
	margin-top:5px
}

.exportToolbarItem {
	margin-right:5px;
}
