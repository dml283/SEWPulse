public with sharing class QASiFrame {
/*
    Type:       Web Service Delegator
    Purpose:    Gets the iFrame URL and DPID
    Used By:    
    Description:
    			getUrl() - 	gets the QAS iFrame URL to use for the 
    					   	QAS Intuitive Search iFrame
    					   
    			getDPID()-	gets the DPID based on the address string
    						String needs to be "," delimited		
    
    ---------------------------------------------------------------
    History:

*/

	private final static String endpoint;
	private final static String userid;
	private final static String password;
	private final static String layout;
	private final static String dataset;
	private final static String searchengine;

	/* PUBLIC METHODS */
	public static String getURL() {
		// Gets the session id and url for QAS iFrame
		QAS_iFrame_Service.BasicHttpBinding_IIFrameService  qasiFrameSvc = new QAS_iFrame_Service.BasicHttpBinding_IIFrameService ();
		QAS_iFrame_Service.IFrameInfo iFrameInfo = qasiFrameSvc.GetIFrameUrlAndSessionId(userid, password, searchengine, 600, 'en-GB');
		
		if (iFrameInfo.ErrorCode == 0) {
			String qasurl = iFrameInfo.IFrameUrl + '?sessionid=' + iFrameInfo.sessionId + '&dataset='+dataset+'&layout='+layout;
			qasurl += '&proxyurl=' + EncodingUtil.urlEncode(getProxyPageFullUrl(), 'UTF-8');
			return qasurl;
		} else {
			throw new QASiFrameException(iFrameInfo.errorCode + ' - ' + iFrameInfo.errorMessage);
		}
		
		return null;	
	}

	public static String getDPID(String searchAddress) {
		String dpid;
		
		// calls the QAS on demand service to get the DPID
		QAS_OnDemand_Service.QAPortType ProOnDemandService = new QAS_OnDemand_Service.QAPortType();
		//QAS_OnDemand_Service.EngineType engineType = new QAS_OnDemand_Service.EngineType();
		ProOnDemandService.query_header = new QAS_OnDemand_Service.QAQueryHeader();
		ProOnDemandService.query_header.QAAuthentication  = new QAS_OnDemand_Service.QAAuthentication();
		ProOnDemandService.query_header.QAAuthentication.Username = userid;
		ProOnDemandService.query_header.QAAuthentication.Password = password;
		QAS_OnDemand_Service.QASearchResult_element searchResponse = ProOnDemandService.DoSearch('AUS', 'Verification',  layout, searchAddress, false); 

		if (searchResponse != null) {
			// check that verificaiton level is verified
			if (searchResponse.VerifyLevel == 'Verified' 
					&& searchResponse.QAAddress != null 
					&& searchResponse.QAAddress.AddressLine != null) {
				for (QAS_OnDemand_Service.AddressLineType line : searchResponse.QAAddress.AddressLine) {
					// get the DPID
					if (line.label == 'DPID/DID')
						dpid = line.Line;						
				}
			}			
		}
		
		return dpid;
	}
/*	
	public static String getDPID2(String searchAddress) {
	
		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setEndpoint(endpoint + '/ProOnDemand/V3/ProOnDemandService.asmx');
		req.setMethod('POST');
		
		if (searchAddress == null || searchAddress == '') return null;

		String reqBody = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ond="http://www.qas.com/OnDemand-2011-03">' +
			   '<soapenv:Header>' +
			      '<ond:QAQueryHeader>' +
			         '<ond:QAAuthentication>' +
			            '<ond:Username>' + userid + '</ond:Username>' +
			            '<ond:Password>' + password + '</ond:Password>' +
			         '</ond:QAAuthentication>' +
			      '</ond:QAQueryHeader>' +
			   '</soapenv:Header>' +
			   '<soapenv:Body>' +
			      '<ond:QASearch>' +
			         '<ond:Country>AUS</ond:Country>' +
			         '<ond:Engine>Verification</ond:Engine>' +
			         '<ond:Layout>' + layout + '</ond:Layout>' +
			         '<ond:Search>' + searchAddress + '</ond:Search>' +
			         '<ond:FormattedAddressInPicklist>false</ond:FormattedAddressInPicklist>' +
			      '</ond:QASearch>' +
			   '</soapenv:Body>' +
			'</soapenv:Envelope>';
			
			System.debug(reqBody);
		
		req.setBody(reqBody);		
		req.setHeader('Content-Type', 'text/xml; charset=utf-8');
		req.setHeader('SOAPAction', 'http://www.qas.com/OnDemand-2011-03/DoSearch');
		
		Dom.Document doc; 
		HttpResponse res;
		
		if (!Test.isRunningTest()) {
			res = h.send(req);
		} else {
			res = new HttpResponse();
			String body = '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">' +
   							'<soap:Header>' +
   							'      <QAInformation xmlns="http://www.qas.com/OnDemand-2011-03">' +
   							'         <StateTransition>SearchResults</StateTransition>' +
   							'         <CreditsUsed>1</CreditsUsed>' +
   							'      </QAInformation>' +
   							'   </soap:Header>' +
   							'   <soap:Body>' +
   							'      <QASearchResult VerifyLevel="Verified" xmlns="http://www.qas.com/OnDemand-2011-03">' +
   							'         <QAAddress DPVStatus="DPVNotConfigured">' +
    							'           <AddressLine LineContent="None">' +
    							'              <Label/>' +
    							'              <Line>World Square</Line>' +
    							'           </AddressLine>' +
    							'           <AddressLine LineContent="None">' +
    							'              <Label/>' +
    							'              <Line>Se 2  650 George St</Line>' +
   							'            </AddressLine>' +
   							'            <AddressLine>' +
   							'               <Label>Locality</Label>' +
   							'               <Line>SYDNEY</Line>' +
   							'            </AddressLine>' +
   							'            <AddressLine>' +
   							'               <Label>State code</Label>' +
   							'               <Line>NSW</Line>' +
   							'            </AddressLine>' +
   							'            <AddressLine>' +
   							'               <Label>Postcode</Label>' +
    							'              <Line>2000</Line>' +
    							'           </AddressLine>' +
    							'           <AddressLine>' +
    							'              <Label>Country</Label>' +
    							'              <Line>AUSTRALIA</Line>' +
    							'           </AddressLine>' +
    							'           <AddressLine LineContent="Ancillary">' +
    							'              <Label>DPID/DID</Label>' +
    							'              <Line>99611311</Line>' +
    							'           </AddressLine>' +
   							'         </QAAddress>' +
   							'      </QASearchResult>' +
   							'   </soap:Body>' +
   							'</soap:Envelope>';
			res.setBody(body);
		}	
		
		doc = res.getBodyDocument();
		System.debug(res.getBody());
		Dom.XMLNode root = doc.getRootElement();

		if (root != null) {
			Dom.XMLNode resBody = root.getChildElement('Body', root.getNameSpace());
			
			if (resBody != null) {
				System.debug('here');

				// Get the QASearchResult node
				Dom.XMLNode QASearchResult = resBody.getChildElements()[0];
				// Get the body namespace
				String ns = QASearchResult.getNameSpace();

				// Check if it has been successfully verified
				String verifyLevel = QASearchResult.getAttributeValue('VerifyLevel', null);
				
				// If verified
				if (verifyLevel == 'Verified') {
					// Loop through the addressLine elements and find the DPID
					for (Dom.XMLNode addressLine : QASearchResult.getChildElements()[0].getChildElements()) {
						if(addressLine.getChildElement('Label', ns).getText() == 'DPID/DID') {
							return (addressLine.getChildElement('Line', ns).getText());
						}
					}
				}
			}
		}
		
		return null;
	}

	public static String getURL2() {
		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setEndpoint('https://int2.ondemand.qas.com/iframeservice/V1/iframeservice.svc');
		req.setMethod('POST');
		
		String reqBody = '<s:Envelope xmlns:s = "http://www.w3.org/2003/05/soap-envelope" xmlns:a = "http://www.w3.org/2005/08/addressing">' +
							'<s:Header>' + 
								'<a:Action s:mustUnderstand = "1">http://www.qas.com/IFrameService-2011-06/IIFrameService/GetIFrameUrlAndSessionId</a:Action>' + 
							'</s:Header>' + 
							'<s:Body>' + 
								'<GetIFrameUrlAndSessionId xmlns = "http://www.qas.com/IFrameService-2011-06">' + 
									'<userName>' + userid + '</userName>' + 
									'<password>' + password + '</password>' + 
									'<searchEngine>IntuitiveSearchV1</searchEngine>' +
									'<expirySeconds>600</expirySeconds>' +
								'</GetIFrameUrlAndSessionId>' + 
							'</s:Body>' + 
						'</s:Envelope>';
							
		
		req.setBody(reqBody);		
		req.setHeader('Content-Type', 'application/soap+xml; charset=utf-8');
		
		Dom.Document doc; 
		HttpResponse res;
		
		if (!Test.isRunningTest()) {
			res = h.send(req);
		} else {
			res = new HttpResponse();
			String body = '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:a="http://www.w3.org/2005/08/addressing">';
			body += '<s:Header>';
			body += '<a:Action s:mustUnderstand="1">http://www.qas.com/IFrameService-2011-06/IIFrameService/GetIFrameUrlAndSessionIdResponse</a:Action>';
			body += '</s:Header>';
			body += '<s:Body>';
			body += '<GetIFrameUrlAndSessionIdResponse xmlns="http://www.qas.com/IFrameService-2011-06">';
			body += '<GetIFrameUrlAndSessionIdResult xmlns:i="http://www.w3.org/2001/XMLSchema-instance">';
			body += '<ErrorCode>0</ErrorCode>';
			body += '<ErrorMessage/>';
			body += '<IFrameUrl>https://int2.ondemand.qas.com/intuitivesearch/v1/intuitive.aspx</IFrameUrl>';
			body += '<SessionId>4304d8f6-d94c-88f0-784e-7a8dd075501a</SessionId>';
			body += '</GetIFrameUrlAndSessionIdResult></GetIFrameUrlAndSessionIdResponse></s:Body></s:Envelope>';
			res.setBody(body);
		}	
		
		doc = res.getBodyDocument();
		Dom.XMLNode root = doc.getRootElement();

		if (root != null) {
			Dom.XMLNode resBody = root.getChildElement('Body', root.getNameSpace());
			
			if (resBody != null) {
				Dom.XMLNode response = resBody.getChildElements()[0].getChildElements()[0];
				String errorCode = response.getChildElement('ErrorCode', response.getNamespace()).getText();
				String errorMessage = response.getChildElement('ErrorMessage', response.getNamespace()).getText();
				String iFrameURL = response.getChildElement('IFrameUrl', response.getNamespace()).getText();
				String sessionId = response.getChildElement('SessionId', response.getNamespace()).getText();
				
				if (errorCode == '0') {
					String qasurl = iFrameURL + '?sessionid=' + sessionId + '&dataset='+dataset+'&layout='+layout;
					qasurl += '&proxyurl=' + EncodingUtil.urlEncode(getProxyPageFullUrl(), 'UTF-8');
					return qasurl;
				} else {
					throw new QASiFrameException(errorCode + ' - ' + errorMessage);
				}
			}
		}

		throw new QASiFrameException('An unknown exception occurred retrieving the QAS iFrame URL details');

		return null;
	} */

	/* PUBLIC INNER CLASSES */
	public class QASiFrameException extends Exception {}

	/* PRIVATE METHODS */
	private static String getProxyPageFullUrl() {
		
		String siteUrl = Site.getCurrentSiteUrl();
		String proxyUrl;
		
		if (siteUrl != null)
			proxyUrl = siteUrl + 'QASProxy';
		else
			proxyUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/apex/QASProxy';		
	
		return proxyUrl;
	}
	
	/* STATIC INITS */
	static {
		QASOnDemand__c q = QASOnDemand__c.getInstance();
		if (q != null) {
			endpoint = q.Ondemand_Endpoint__c;
			userid = q.userid__c;
			password = q.password__c;
			layout = q.layout__c;
			dataset = q.dataset__c;
			searchengine = q.searchengine__c;
		} else {
			endpoint = 'https://ws2.ondemand.qas.com';
			userid = 'ws_993_ext';
			password = 'S3w@t20!1';
			layout = 'AUS5Line';
			dataset = 'AUS';	
			searchengine = 'IntuitiveSearchV1';		
		}
	}
	
	/* TEST METHODS */
	private static TestMethod void testMe() {
		String qasurl = QASiFrame.getURL();
		String dpid = QASiFrame.getDPID('Address');
		QAS_iFrame_MessageTypes QASiFrameMsgType = new QAS_iFrame_MessageTypes();
		System.assertEquals(dpid, '123456');
		
		QAS_iFrame_MessageTypes qmt = new QAS_iFrame_MessageTypes();
		
		// code coverage
		QAS_OnDemand_Service.PicklistEntryType pet = new QAS_OnDemand_Service.PicklistEntryType();
		QAS_OnDemand_Service.VerificationFlagsType vft = new QAS_OnDemand_Service.VerificationFlagsType();
		QAS_OnDemand_Service.QAPicklistType qpt = new QAS_OnDemand_Service.QAPicklistType();
		QAS_OnDemand_Service.Address_element ae = new QAS_OnDemand_Service.Address_element();
		QAS_OnDemand_Service.DataplusGroupType dpgt = new QAS_OnDemand_Service.DataplusGroupType();
		QAS_OnDemand_Service.QAInformation qi = new QAS_OnDemand_Service.QAInformation();
	}
}