/*
    Type:       Web Service Utility
    Purpose:    Controls the Suspend Recovery Integration Process

    Used By:    
    ---------------------------------------------------------------
    History:

    17-Aug-2011 J.Pe (Davanti Consulting)    Created

*/
public class WSUtil_SuspendRecovery extends WSUtil{

    /* Inner Class */
    public class SuspendRecoveryResponse{
        public boolean isDirectDebit {get;set;}
        public String LastRecoveryAction {get;set;}
        public String LastRecoveryAmount {get;set;}
        public Date LastRecoveryDate {get;set;}
        public Date LastNormalBillDate {get;set;}
        public Date NextBillDate {get;set;}
        public Date suspendDate {get;set;}
        public Boolean isPassed {get;set;}
        public List<String> messages{
            get{
                if(messages == null){
                    messages = new List<String>();
                }return messages;
            }private set;
        }
    }
    /* static methods*/
    public static SuspendRecoveryResponse validateSuspendRecovery(String accNumber){
        TibcoSuspendRecovery_MessageTypes.Header_element header = generateWSHeader();
        // Initialise Web Service
        TibcoSuspendRecovery_Service.SuspendRecoveryEndpoint stub = new TibcoSuspendRecovery_Service.SuspendRecoveryEndpoint();
        stub.timeout_x = 60000;        
        TibcoSuspendRecovery_MessageTypes.validateSuspendRecoveryResponse_element response = stub.validateSuspendRecovery(accNumber, header);
        return transformSuspendRecoveryResponse(response.ProcessOutputData, response.Header.MessageResponseStatus.ErrorStatus);
        /*
        if (Boolean.valueOf(response.header.MessageResponseStatus.MessageSuccessInd)) {  //webservice success
            return transformSuspendRecoveryResponse(response.ProcessOutputData, response.Header.MessageResponseStatus.ErrorStatus);
        }else{
            throw processMultiWSException(response.Header.MessageResponseStatus.ErrorStatus);
        }
        */
    }
    public static SuspendRecoveryResponse performSuspendRecovery(String accNumber,Date suspendDate){
        TibcoSuspendRecovery_MessageTypes.Header_element header = generateWSHeader();
        // Create Suspend Request message
        TibcoSuspendRecovery_MessageTypes.Suspend_element suspendRequest = new TibcoSuspendRecovery_MessageTypes.Suspend_element();
        suspendRequest.SuspendDate = suspendDate;
        // Initialise Web Service
        TibcoSuspendRecovery_Service.SuspendRecoveryEndpoint stub = new TibcoSuspendRecovery_Service.SuspendRecoveryEndpoint();
        stub.timeout_x = 60000;        
        TibcoSuspendRecovery_MessageTypes.performSuspendRecoveryResponse_element response = stub.performSuspendRecovery(accNumber, header, suspendRequest);
        return transformSuspendRecoveryResponse(response.ProcessOutputData, response.Header.MessageResponseStatus.ErrorStatus);
        /*
        if (Boolean.valueOf(response.header.MessageResponseStatus.MessageSuccessInd)) {  //webservice success
            return transformSuspendRecoveryResponse(response.ProcessOutputData, response.Header.MessageResponseStatus.ErrorStatus);
        }else{
            throw processMultiWSException(response.Header.MessageResponseStatus.ErrorStatus);
        }
        */
    }
    
    /* private static method */
    private static TibcoSuspendRecovery_MessageTypes.Header_element generateWSHeader(){
        TibcoSuspendRecovery_MessageTypes.Header_element header = new TibcoSuspendRecovery_MessageTypes.Header_element();
        header.UserID = Userinfo.getUserName();
        header.UserType = 'Standard';
        header.MessageTimeStamp = datetime.now();
        return header;
    }
    private static MultipleWebServiceBusinessException processMultiWSException(List<TibcoSuspendRecovery_MessageTypes.ErrorStatus_element> errorStatuses){
        MultipleWebServiceBusinessException multiWSEx = new MultipleWebServiceBusinessException('Errors returned from Suspend Recovery Web Service');
        for(TibcoSuspendRecovery_MessageTypes.ErrorStatus_element errorStatus: errorStatuses ){
            SingleWebServiceBusinessException ex = new SingleWebServiceBusinessException(errorStatus.ErrorDescription);
            ex.errorCode = errorStatus.ErrorCode;
            ex.errorSeverity = errorStatus.ErrorSeverity;
            multiWSEx.multiEx.add(ex);
        }
        return multiWSEx;
    }
    private static SuspendRecoveryResponse transformSuspendRecoveryResponse(TibcoSuspendRecovery_MessageTypes.ProcessOutputData_element processOutputData, List<TibcoSuspendRecovery_MessageTypes.ErrorStatus_element> errorStatuses){
        SuspendRecoveryResponse transformedResponse = new SuspendRecoveryResponse();
        transformedResponse.isDirectDebit = Boolean.valueOf(processOutputData.DDIndicator);
        transformedResponse.LastRecoveryAction = processOutputData.LastRecoveryAction;
        transformedResponse.LastRecoveryAmount = processOutputData.LastRecoveryAmount;
        transformedResponse.LastRecoveryDate = processOutputData.LastRecoveryDate;
        transformedResponse.LastNormalBillDate = processOutputData.LastNormalBillDate;
        transformedResponse.NextBillDate = processOutputData.NextBillDate;
        transformedResponse.isPassed = true;
        transformedResponse.suspendDate = processOutputData.SuspendDate;
        if(errorStatuses != null){
            for(TibcoSuspendRecovery_MessageTypes.ErrorStatus_element errorStatus: errorStatuses){
                transformedResponse.messages.add(errorStatus.ErrorDescription);
                if('5'.equals(errorStatus.ErrorSeverity)){
                    transformedResponse.isPassed = false;
                }
            }
        }
        return transformedResponse;
    }
}