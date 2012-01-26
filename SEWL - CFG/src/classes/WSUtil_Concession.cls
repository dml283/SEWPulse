/*
    Type:       Web Service Utility
    Purpose:    Call xxx webservice from Tibco

    Used By:    ConcessionExCon
    ---------------------------------------------------------------
    History:

    19-Sep-2011 L.Tan (Coretec Solutions)   Created
*/
public with sharing class WSUtil_Concession extends WSUtil{

    // concession response class
    public class ConcessionUpdateResponse {
        public Boolean Rebilled {get;set;}
        public String RebillAmount {get;set;}
        //public Boolean ValidConcession {get;set;}
        public String ConcessionReason {get;set;}     
        public List<SingleWebServiceBusinessException> errors {
            get{
                if(errors == null){
                    errors = new List<SingleWebServiceBusinessException>(); 
                }return errors; 
            }set;
        }
    } 
    public ConcessionUpdateResponse concessionResponse = new ConcessionUpdateResponse();

    // methods
    public Boolean concessionUpdate(Case c, String billingAccNo){
        // populate header info
        TibcoConcession_MessageTypes.Header_element header = new TibcoConcession_MessageTypes.Header_element();

        if (SystemSettings__c.getInstance().BRE_Debug_User__c == null)
            header.UserID = Userinfo.getUserName();
        else
            header.UserID = SystemSettings__c.getInstance().BRE_Debug_User__c;
            
        header.UserType = UserInfo.getUserType();
        header.MessageTimeStamp = datetime.now();

        // populate concession details inputs
        TibcoConcession_MessageTypes.concessoinsDetails_element cDetails = new TibcoConcession_MessageTypes.concessoinsDetails_element();
        
        cDetails.AccountNumber = billingAccNo;
        
        cDetails.AccountHolder = (c.Concession_Holder__c == 'Account Holder');
        cDetails.ACHolderPartner = (c.Concession_Holder__c == 'A/C Holder Partner');
        cDetails.ThirdParty = (c.Concession_Holder__c == 'Third Party'); 
        
        cDetails.FirstName = c.Concession_Card_Firstname__c;
        cDetails.Surname = c.Concession_Card_Lastname__c;
        cDetails.CardNumber = c.Concession_Card_Number__c;
        cDetails.CardType = c.Concession_Card_Type__c;
        cDetails.PrintBill = c.Print_Bill__c;
        cDetails.ApplicationQuestion = (c.Received_Application_Form__c == 'Yes');        
        cDetails.Contact = c.Concession_Contact_Point__c;        
        /*if(cDetails.Contact != null){
        	cDetails.Contact = cDetails.Contact.substring(0,1) + '-' + cDetails.Contact;	
        }*/
        cDetails.Evidence = c.Concession_Evidence__c;
        cDetails.CustomerType = c.Concession_Customer_Type__c;
        
        // application form
        cDetails.ApprovalForm = (c.Send_Application_Form__c == 'Yes');
        if (cDetails.ApprovalForm) {
            cDetails.ApprovalFormName = c.Contact_Person_Name__c;
            cDetails.ApprovalFormPropAddr = (c.Send_Application_Form_To__c == 'Property Address');
        }else{
            cDetails.ApprovalFormPropAddr = false;
        }
        
        // is this required?
        //cDetails.AlternatePostCode;
        
        cDetails.ConfirmationLetter = c.Send_Confirmation_Letter__c;        
        cDetails.DeleteReason = c.Delete_Reason__c;

        // call webserive to update concession
        TibcoConcession_Service.SOAPEventSource stub = new TibcoConcession_Service.SOAPEventSource();
        stub.timeout_x = 60000;
        TibcoConcession_MessageTypes.concessionsUpdateResponse_element response = stub.concessionsUpdate(header, cDetails);
        // check if there is an error
        boolean isError = false;
        MultipleWebServiceBusinessException ex = new MultipleWebServiceBusinessException();         
        List<TibcoConcession_MessageTypes.ErrorStatus_element> errorElements = response.Header.MessageResponseStatus.ErrorStatus;            
        if (errorElements != null) {
            for (TibcoConcession_MessageTypes.ErrorStatus_element error: errorElements) {
                SingleWebServiceBusinessException errObj = new SingleWebServiceBusinessException(error.ErrorDescription);             
                errObj.ErrorCode = error.ErrorCode;             
                errObj.ErrorSeverity = error.ErrorSeverity;
                if(Integer.valueOf(errObj.ErrorSeverity) > 2)isError = true;      
                ex.multiEx.add(errObj);
                concessionResponse.errors.add(errObj);
            }
        } 
        if(isError ) throw ex;
        if (Boolean.valueOf(response.header.MessageResponseStatus.MessageSuccessInd)) { //webservice success
            concessionResponse.Rebilled = response.Rebilled;
            concessionResponse.RebillAmount = response.RebillAmount;
            concessionResponse.ConcessionReason = response.ConcessionReason;                                
        } else {    // webservice error
            // throw error exception
            ex = new MultipleWebServiceBusinessException();         
            errorElements = response.Header.MessageResponseStatus.ErrorStatus;
            if (errorElements==null || errorElements.size()==0) {
                    SingleWebServiceBusinessException errObj = new SingleWebServiceBusinessException('Unknown Error');             
                    errObj.ErrorCode = '0000';             
                    errObj.ErrorSeverity = 'High';                          
                    ex.multiEx.add(errObj);
            } else {            
                for (TibcoConcession_MessageTypes.ErrorStatus_element error: errorElements) {
                    SingleWebServiceBusinessException errObj = new SingleWebServiceBusinessException(error.ErrorDescription);             
                    errObj.ErrorCode = error.ErrorCode;             
                    errObj.ErrorSeverity = error.ErrorSeverity;            
                    ex.multiEx.add(errObj);
                }
            }        
            throw ex;           
        }
        return Boolean.valueOf(response.header.MessageResponseStatus.MessageSuccessInd);
    }
}