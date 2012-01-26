@page {
	size:A4 portrait;
	margin-top: 3.8cm;

	@bottom-right {
		content: "Page " counter(page) " of " counter(pages);
		font-family: "Arial" "Sans-Serif";
		font-size:10px;
		margin-bottom:2em;
	}
}

p {
	margin-bottom:10px;
	margin-top:0px;
	text-align: justify;
}

body {
	font-family: "Arial" "Sans-Serif";
	font-size:12px;
	padding-top:3px;

}

table.detailList td {
	padding-top:3px;
	padding-bottom:3px;
}

.labelCol {
	font-weight:bold;
	vertical-align:top;
	text-align: right;
	padding-right:15px;
	width: 80px;
}

.data2Col {
	vertical-align:top;
}

/* MAIN CONTENT CELL */
.contentCell {
	text-align: left;
	vertical-align: top;
	padding-top:3px;
	padding-left:15px;
}

/* Address cell */
.contentsAddressCell {
	font-size:0.85em;
	font-weight:bold;
	color:#0A3764;
	padding-left:5px;
	padding-bottom:5px;
}

/* Links */
.contentsLinkCell {
	font-size:0.9em;
	display: block;
	text-align: left;
	padding:0px;
}

.contentsLink {
	height: 100%;
	padding: 5px 3px;
	display: block;
	text-decoration: none;
	border-style: none;
	color: #0072BC;
}

a.contentsLink {
	color: #0072BC;
}

.contentsLinkActive {
	height: 100%;
	padding: 5px 3px;
	display: block;
	color: #2B840F;
	text-decoration: none;
	border-style: none;
}

a.contentsLinkActive {
	color: #2B840F;
}

a.contentsLink:hover {
	background-color: #E7E2DE;
	text-decoration: none;
	border-style: none;
	color: #2B840F;
}

a.contentsLinkActive:hover {
	background-color: #E7E2DE;
	text-decoration: none;
	border-style: none;
	color: #2B840F;
}

/* Indicates completion */
.tickIconCell {
	width:16px;
	text-align: center;
	line-height: 15px;
	border-style: none;
	padding-right:3px;
}

/* Light grey background for header row */
.headerRowLGBack {
	background-color: #f7f7f7;
}

/* Tables */
.apexp .detailList .list TD {
	border-bottom: 0;
}

.apexp .detailList .list .headerRow TH {
	border-bottom: 	#595959 1px solid;
	border-top: 	#595959 1px solid;
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
	font-size:24px;
	color: #005f98;
}

	/*** PAGE BLOCK AND SECTION HEADERS ***/

	/* padding around page block headers */
	.bPageHeader .phHeader {
		padding: 5px 0px;
	}

	/* Page Block Header */
	.bPageBlock .pbHeader {
		padding-bottom: 0px;
	}

	.bPageBlock .pbBody {
		padding-top: 0px;
	}

	.pageBlockHeader {
		height: 100%;
		color: #005F98;
		padding-top: 5px;
		font-size: 24px;
	}

	.first.pbSubheader {
		margin-top: 10px;
	}

	.pbSubheader {
		border-bottom: #82C0CB 1px solid;
		color: #464646;
		padding: 0px;
		margin-bottom: 10px;
		font-size: 11px;
		margin-left: 0px;
	}

	.pbSubheader H3 {
		color: #464646;
	}

/* HEADINGS AND SUBHEADINGS */
h1 {
	line-height: 20px;
    font-size:18px;
    color: #005F98;
	display: block;
}
h2 {
	font-size:14px;
	color: #005F98;
	line-height:1;
}

h3 {
	font-weight:bold;
	font-size:10px;
	padding-left: 3px;
	line-height:1;
}

/* TABLES */
.headerRowRight {
	text-align: right;
	padding-right: 5px;
}

.headerRow {
	padding-left: 5px;
	padding-right: 5px;
}

.dataCell {
	padding-left: 5px;
}

.headerRowLGBack {
	background-color: #f7f7f7;
	border-bottom: #595959 1px solid;
	border-top: #595959 1px solid;
}

.headerRowPeriod {
	padding-bottom: 2px;
	padding-top: 2px;
	width: 98px;
	vertical-align: middle;
}

.headerRowCentered {
	padding-bottom: 2px;
	padding-top: 2px;
	vertical-align: middle;
	text-align: center;
}

.dataRowRight {
	padding-bottom: 4px;
	padding-top: 4px;
	padding-right: 5px;
	text-align: right;
}
.dataRowCentered {
	padding-bottom: 4px;
	padding-top: 4px;
	padding-right: 4px;
	text-align: center;
	vertical-align: middle !important;
}

/* MISC */

/* Info box with icon */
.informationBox {
	background-image:url('https://c.ap1.content.force.com/servlet/servlet.ImageServer?id=015900000002SXa&oid=00D90000000KRNM');
	background-repeat:no-repeat;
	background-position: 2px 2px;
	background-color: #E5F1F8;
	border: 1px solid #005F98;
	display: inline-block;
	font-weight: bold;
	padding-top: 3px;
	padding-bottom: 3px;
	padding-left: 20px;
	padding-right: 4px;
	font-size: 0.85em;
	margin-top: 4px;
	color: #005F98;
	border-radius:3px;
	-webkit-border-radius:3px;
	-moz-border-radius:3px;
	-moz-box-shadow: 3px 3px 4px #ccc;
	-webkit-box-shadow: 3px 3px 4px #ccc;
	box-shadow: 3px 3px 4px #ccc;
	display:block;
}

.informationBox ul {
	list-style-type:disc;
	list-style-position:outside;
	margin-left: 0px;
	margin-top: 5px;
	margin-bottom: 5px;
	margin-right: 5px;
	padding-left: 0px;
}

.informationBox li {
	margin:0 0 0 -20;
}