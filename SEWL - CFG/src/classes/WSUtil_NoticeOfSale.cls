/*******************************************************************************************
 
 * <Organization>South East Water Limited</Organization>
 * <ClassName>WSUtil_InfoStatementUpdate</ClassName>
 * <ApiVersion>23.0</ApiVersion>
 * <CreatedBy>Gareth Knight</CreatedBy>
 * <CreatedDate>Wed, 23/09/2011</CreatedDate>
 
 * <purpose>
    Call Tibco Notice of Sale
 * </purpose>
    
*******************************************************************************************/

public with sharing class WSUtil_NoticeOfSale extends WSUtil{
    
    public class NoticeOfSaleResponse{
        public Boolean NOSComplete{get;set;}
        public String NOSExceptionCode{get;set;}
        public String NOSExceptionMsg{get;set;}
        public String PurchaserRole{get;set;} 
        public Boolean noAlerts{
            get{
                if (noAlerts == null){
                    noAlerts = true;
                } return noAlerts;
            } private set;
        }
        public List<SingleWebServiceBusinessException> messages{
            get{
                if (messages == null){
                    messages = new List<SingleWebServiceBusinessException>();
                } return messages;
            } private set;
        }
    }
    
    private static NoticeOfSaleResponse transformNOSResponse(TibcoNoticeOfSale_MessageTypes.ProcessOutputData_element outputData, List<TibcoNoticeOfSale_MessageTypes.ErrorStatus_element> errorStatuses){
        NoticeOfSaleResponse transformedResponse = new NoticeOfSaleResponse();
        transformedResponse.NOSComplete = outputData.NOSComplete;
        transformedResponse.NOSExceptionCode = outputData.NOSExceptionCode;
        transformedResponse.NOSExceptionMsg = outputData.NOSExceptionMsg;
        transformedResponse.PurchaserRole = outputData.PurchaserRole;
        
        if(errorStatuses != null){            
            for(TibcoNoticeOfSale_MessageTypes.ErrorStatus_element errorStatus : errorStatuses){                
                SingleWebServiceBusinessException message = new SingleWebServiceBusinessException(errorStatus.ErrorDescription);                
                if ('3'.equals(errorStatus.ErrorSeverity) || '4'.equals(errorStatus.ErrorSeverity) || '5'.equals(errorStatus.ErrorSeverity)){                    
                    transformedResponse.noAlerts = false;                
                }                
                message.ErrorCode = errorStatus.ErrorCode;                              
                message.ErrorSeverity = errorStatus.ErrorSeverity;                
                transformedResponse.messages.add(message);            
            }        
        }
        system.debug('### Transformed Response = ' +transformedResponse);
        return transformedResponse;        
    }
    
    public NoticeOfSaleResponse performNoticeOfSale(Case NOSCase){
        // populate header info

        TibcoNoticeOfSale_MessageTypes.Header_element header = new TibcoNoticeOfSale_MessageTypes.Header_element();

        if (SystemSettings__c.getInstance().BRE_Debug_User__c == null){
            header.UserID = Userinfo.getUserName();
        } else {
            header.UserID = SystemSettings__c.getInstance().BRE_Debug_User__c;
        }
            
        header.UserType = UserInfo.getUserType();
        header.MessageTimeStamp = datetime.now();
        
        TibcoNoticeOfSale_Service.noticeOfSale_xConsumer  service = new TibcoNoticeOfSale_Service.noticeOfSale_xConsumer ();
        service.timeout_x = 60000;
        
        TibcoNoticeOfSale_MessageTypes.ProcessInputData_element requestDetails = new TibcoNoticeOfSale_MessageTypes.ProcessInputData_element();
        requestDetails.PropertyReference = NOSCase.Property__r.CIS_Property_Id__c;
        requestDetails.SFDCCaseNumber = NOSCase.CaseNumber;
        requestDetails.VendorAccount = NOSCase.Vendor_Billing_Account__r.HiAF_Account_Number__c;
        requestDetails.PurchaserAccount = NOSCase.Purchaser_Billing_Account__r.HiAF_Account_Number__c;
        requestDetails.TenantAccount = NOSCase.Tenant_Billing_Account__r.HiAF_Account_Number__c;
        requestDetails.TransactionType = NOSCase.Type_of_Sale__c;
        requestDetails.SettlementDate = NOSCase.Settlement_Date__c;
        requestDetails.ChequeIncluded = NOSCase.Cheque_Included__c;
        requestDetails.ChequeAmount = String.valueOf(NOSCase.Cheque_Amount__c);
        requestDetails.ChequeNumber = NOSCase.Cheque_Number__c;
        requestDetails.ChequeBank = NOSCase.Bank__c;
        requestDetails.DialysisCustomerFlag = NOSCase.Dialysis_Customer__c;
        requestDetails.CaveatCustomerFlag = NOScase.Caveat_Customer__c;
        requestDetails.LegalCustomerFlag = NOSCase.Legal_Customer__c;
        requestDetails.BNSMManual = NOSCase.BNSM_ADC_Manual_Update__c;
        
        TibcoNoticeOfSale_MessageTypes.noticeOfSaleResponse_element response = service.noticeOfSale(Header, requestDetails);
        system.debug('### Response Process OutputData = ' +response.processOutputData);
        system.debug('### Response Header Message = ' + response.Header.MessageResponseStatus);
        
        //List<TibcoNoticeOfSale_MessageTypes.
        if (response.Header.MessageResponseStatus != null){
            return transformNOSResponse(response.processOutputData, response.Header.MessageResponseStatus.ErrorStatus);  
        } else {
            return transformNOSResponse(response.processOutputData, null);
        }
        
    }        
}