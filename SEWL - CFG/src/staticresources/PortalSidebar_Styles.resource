
/* MAIN CONTENT CELL */
.contentCell {
    text-align: left;
    vertical-align: top;
    padding-top:3px;
    width:725px;
}

/* SIDE BAR */
.sideBarCell {
    text-align: left;
    vertical-align: top;
    width: 205px;
}

/* Address cell */
.contentsAddressCell {
    font-size:0.85em;
    font-weight:bold;
    color:#0A3764;
    padding-left:3px;
    padding-right:5px;
    padding-bottom:5px;
}

/* Links */
.contentsLinkCell {
    font-size:10pt;
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
    color: #0072BC !important;
}

a.contentsLink {
    position: relative;
    color: #0072BC !important;
}

.contentsLinkActive {
    height: 100%;
    padding: 5px 3px;
    display: block;
    color: #2B840F !important;
    text-decoration: none;
    border-style: none;
}

a.contentsLinkActive {
    position: relative;
    color: #2B840F !important;
    background-color: #E7E2DE;
}

a.contentsLink:hover {
    z-index:25;
    background-color: #E7E2DE;
    text-decoration: none;
    border-style: none;
    color: #2B840F !important;
}

a.contentsLinkActive:hover {
    z-index:25;
    background-color: #E7E2DE;
    text-decoration: none;
    border-style: none;
    color: #2B840F !important;
}

a.contentsLink span.popup, a.contentsLinkActive span.popup{display: none}

a.contentsLink:hover span.popup,
a.contentsLinkActive:hover span.popup { /*the span will display just on :hover state*/
    font-weight: bold;
    padding-top: 3px;
    padding-bottom: 3px;
    padding-left: 4px;
    padding-right: 4px;
    font-size: 8pt;
    display:block;
    position:absolute;
    top:0em; left:15em;
    background-color: #4E9F27;
    border: 1px solid #4E9F27;
    color: #fff;
    text-align: left;
    border-radius:3px;
    -webkit-border-radius:3px;
    -moz-border-radius:3px;
    -moz-box-shadow: 1px 2px 3px rgba(0, 0, 0, 0.6);
    -webkit-box-shadow: 1px 2px 3px rgba(0, 0, 0, 0.6);
    box-shadow: 1px 2px 3px rgba(0, 0, 0, 0.6);}
    