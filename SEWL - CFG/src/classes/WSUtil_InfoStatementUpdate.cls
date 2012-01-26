/*******************************************************************************************
 
 * <Organization>South East Water Limited</Organization>
 * <ClassName>WSUtil_InfoStatementUpdate</ClassName>
 * <ApiVersion>22.0</ApiVersion>
 * <CreatedBy>Gareth Knight</CreatedBy>
 * <CreatedDate>Wed, 14/09/2011</CreatedDate>
 
 * <purpose>
    Call getInfoStatementUpdate Web-service from Tibco
 * </purpose>
    
*******************************************************************************************/


public with sharing class WSUtil_InfoStatementUpdate extends WSUtil{

    /* private static method */
    private static Tibco_InfoStatementUpdate_MessageTypes.Header_element generateWSHeader(){
        Tibco_InfoStatementUpdate_MessageTypes.Header_element header = new Tibco_InfoStatementUpdate_MessageTypes.Header_element();
        header.UserID = Userinfo.getUserName();
        header.UserType = 'Standard';
        header.MessageTimeStamp = datetime.now();
        return header;
    }
    
    /* Error Classes */
    /*
    public class ErrorStatus{
        public String ErrorCode{get;set;}
        public String ErrorSeverity{get;set;}
        public String ErrorDescription{get;set;}
    }
    public class WebServiceBusinessException extends Exception{
        public List<ErrorStatus> errors = new List<ErrorStatus>();
    } 
    */
    public class InfoStatementUpdateResponse{
        public Boolean UpdateGiven{get;set;}
        public String CurrentDrainage{get;set;}
        public Date DrainagePeriodTo{get;set;}
        public String DrainageUnpaid{get;set;}
        public String CurrentParks{get;set;}
        public Date ParksPeriodTo{get;set;}
        public String ParksUnpaid{get;set;}
        public String Pre_01_01_98{get;set;}
        public String LegalCosts{get;set;}
        public String TotalOwning{get;set;}
        public Boolean ManualCheck{get;set;}
        public Boolean noAlerts{
            get{
                if (noAlerts == null){
                    noAlerts = true;
                } return noAlerts;
            } private set;
        }
        public List<SingleWebServiceBusinessException > messages{
            get{
                if (messages == null){
                    messages = new List<SingleWebServiceBusinessException >();
                } return messages;
            } private set;
        }
    }
    
    //public InfoStatementUpdateResponse response = new InfoStatementUpdateResponse();
    
    //public UpdateDetails updateDetail = new UpdateDetails();
    
    public class RequestDetails{
        public String PropertyReference{get;set;}
        public String AccountQuoted{get;set;}
        public String RadioSet{get;set;}
        public String PurchaserName{get;set;}
        public String LineAddress1{get;set;}
        public String LineAddress2{get;set;}
        public String LineAddress3{get;set;}
        public String LineAddress4{get;set;}
    }
    
    public RequestDetails requestDetail = new RequestDetails();
    

    private static InfoStatementUpdateResponse transformInfoStatementUpdateResponse(Tibco_InfoStatementUpdate_MessageTypes.updateDetail_element updateDetail, List<Tibco_InfoStatementUpdate_MessageTypes.ErrorStatus_element> errorStatuses){
        InfoStatementUpdateResponse transformedResponse = new InfoStatementUpdateResponse();
        transformedResponse.UpdateGiven = updateDetail.UpdateGiven;
        transformedResponse.CurrentDrainage = updateDetail.CurrentDrainage;
        transformedResponse.DrainagePeriodTo = updateDetail.DrainagePeriodTo;
        transformedResponse.DrainageUnpaid = updateDetail.DrainageUnpaid;
        transformedResponse.CurrentParks = updateDetail.CurrentParks;
        transformedResponse.ParksPeriodTo = updateDetail.ParksPeriodTo;
        transformedResponse.Pre_01_01_98 = updateDetail.Pre_01_01_98;
        transformedResponse.LegalCosts = updateDetail.LegalCosts;
        transformedResponse.TotalOwning = updateDetail.TotalOwning;
        transformedResponse.ManualCheck = updateDetail.ManualCheck;        

        
        if(errorStatuses != null){
            for(Tibco_InfoStatementUpdate_MessageTypes.ErrorStatus_element errorStatus : errorStatuses){
                SingleWebServiceBusinessException message = new SingleWebServiceBusinessException(errorStatus.ErrorDescription);
                if ('3'.equals(errorStatus.ErrorSeverity) || '4'.equals(errorStatus.ErrorSeverity) || '5'.equals(errorStatus.ErrorSeverity)){
                    transformedResponse.noAlerts = false;
                }
                message.ErrorCode = errorStatus.ErrorCode;
                message.ErrorSeverity = errorStatus.ErrorSeverity;
                transformedResponse.messages.add(message);
            }
        }
        return transformedResponse;
    }
    
    
    
    /* Methods */
    //public Boolean infoStatementUpdate(RequestDetails InfoStatementUpdateDetails){
    //public Boolean infoStatementUpdate(){
    public InfoStatementUpdateResponse infoStatementUpdate(){
        // populate header info
        Tibco_InfoStatementUpdate_MessageTypes.Header_element header = new Tibco_InfoStatementUpdate_MessageTypes.Header_element();

        if (SystemSettings__c.getInstance().BRE_Debug_User__c == null)
            header.UserID = Userinfo.getUserName();
        else
            header.UserID = SystemSettings__c.getInstance().BRE_Debug_User__c;
            
        header.UserType = UserInfo.getUserType();
        header.MessageTimeStamp = datetime.now();
        
        Tibco_InfoStatementUpdate_Service.infoStatementUpdate_xConsumer service = new Tibco_InfoStatementUpdate_Service.infoStatementUpdate_xConsumer();
        service.timeout_x = 60000;
        
        Tibco_InfoStatementUpdate_MessageTypes.infoStatementUpdateResponse_element response = 
            service.infoStatementUpdate(Header, requestDetail.PropertyReference, requestDetail.AccountQuoted, 
                                    requestDetail.RadioSet, requestDetail.PurchaserName, requestDetail.LineAddress1, 
                                    requestDetail.LineAddress2, requestDetail.LineAddress3, requestDetail.LineAddress4);
        
        //if (Boolean.valueOf(response.Header.MessageResponseStatus.MessageSuccessInd)) { //webservice success
        return transformInfoStatementUpdateResponse(response.updateDetail, response.Header.MessageResponseStatus.ErrorStatus);  

    }
       
}