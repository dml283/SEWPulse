/*
    Type:       Web Service Utility
    Purpose:    Controls the Special Meter Read Integration Process

    Used By:
    ---------------------------------------------------------------
    History:

    23-Sep-2011 J.Pe (Davanti Consulting)    Created

*/
public class WSUtil_SpecialMeterRead extends WSUtil{

    public class SMRResponse{
        public string actionName{get;set;}
        public boolean isSuccessful{get;set;}
        public boolean isSMRClosed {
            get{
                if (isSMRClosed == null){
                    isSMRClosed = false;
                }return isSMRClosed ;
            }set;
        }
        public Case caseRec{get;set;}
    }

    public static SMRResponse validateSpecialMeterRead(Case caseRec, String action){
        Tibco_SMR_Message_Type.Header_element header = generateWSHeader();
        Tibco_SMR_Message_Type.validateSpecialMeterReadInputData_element validateSMRInputData = new Tibco_SMR_Message_Type.validateSpecialMeterReadInputData_element();

        validateSMRInputData.PropertyReference = caseRec.Property__r.CIS_Property_Id__c;
        validateSMRInputData.Action = action;
        validateSMRInputData.ContactType = caseRec.Contact_Method__c;
        validateSMRInputData.ReadType = caseRec.Type_of_Read_INTEGRATION__c;
        validateSMRInputData.Contact =  caseRec.Contact_Type__c;
        validateSMRInputData.TenantAction = caseRec.Tenant_Action__c;
        validateSMRInputData.ApptDate = caseRec.Move_In_Out_Date__c;
        validateSMRInputData.ReadDate = caseRec.Reading_Date__c;
        validateSMRInputData.BillingAccountNumber = caseRec.Billing_Account__r.HiAF_Account_Number__c;
        validateSMRInputData.StatusBEnd = caseRec.Is_Done_at_the_Back_End__c;
        validateSMRInputData.AmendRead = caseRec.Amend_Read_Used__c;

        // Initialise Web Service
        Tibco_SMR_Service.MeterReadEndpoint  stub = new Tibco_SMR_Service.MeterReadEndpoint ();
        stub.timeout_x = 60000;
        TIBCO_SMR_Message_Type.validateSpecialMeterReadResponse_element  response = stub.validateSpecialMeterRead(header, validateSMRInputData);

        System.debug('ResponseMe');
        System.debug(response);

        if (Boolean.valueOf(response.header.MessageResponseStatus.MessageSuccessInd)) {  //webservice success
            return transformValidateSMRResponse(action, response, caseRec);
        }else{
            throw processMultiWSException(response.Header.MessageResponseStatus.ErrorStatus);
        }
    }

    public static SMRResponse performSpecialMeterRead(Case caseRec, String action){
        Tibco_SMR_Message_Type.Header_element header = generateWSHeader();
        Tibco_SMR_Message_Type.doSpecialMeterReadInputdata_element doSMRInputData = new Tibco_SMR_Message_Type.doSpecialMeterReadInputdata_element();

        doSMRInputData.PropertyReference = caseRec.Property__r.CIS_Property_Id__c;
        doSMRInputData.Action = action;
        doSMRInputData.ContactType = caseRec.Contact_Method__c;
        doSMRInputData.Contact = caseRec.Contact_Type__c;
        doSMRInputData.TenantAction = caseRec.Tenant_Action__c;
        doSMRInputData.BillingAccountNumber = caseRec.Billing_Account__r.HiAF_Account_Number__c;
        doSMRInputData.SFDCCase = caseRec.CaseNumber;
        doSMRInputData.ExistingRead = caseRec.Existing_Reading__c;
        doSMRInputData.ReadType = caseRec.Type_of_Read_INTEGRATION__c;
        doSMRInputData.ReadDate = caseRec.Reading_Date__c;
        doSMRInputData.SMRCurrAddress1 = caseRec.Street__c;
        doSMRInputData.SMRCurrAddress2 = caseRec.City__c;
        doSMRInputData.SMRCurrAddress3 = caseRec.State__c;
        doSMRInputData.Status_BEnd = caseRec.Is_Done_at_the_Back_End__c;
        doSMRInputData.AmendRead = caseRec.Amend_Read_Used__c;
        doSMRInputData.ApptDate = caseRec.Move_In_Out_Date__c;
        doSMRInputData.LetterToAgent = caseRec.Is_Letter_to_Agent__c;
        doSMRInputData.LetterToOwner = caseRec.Is_Letter_to_Owner__c;
        doSMRInputData.TenantName = caseRec.Tenant_Name__c;
        doSMRInputData.AgentName = caseRec.Agent_Name__c;
        doSMRInputData.AgentAddress1 = caseRec.Agent_Address_1__c;
        doSMRInputData.AgentAddress2 = caseRec.Agent_Address_2__c;

        // Initialise Web Service
        Tibco_SMR_Service.MeterReadEndpoint stub = new Tibco_SMR_Service.MeterReadEndpoint();
        stub.timeout_x = 60000;
        Tibco_SMR_Message_Type.doSpecialMeterReadResponse_element response = stub.doSpecialMeterRead(header, doSMRInputData);

        System.debug('ResponseMe');
        System.debug(response);

        if (Boolean.valueOf(response.header.MessageResponseStatus.MessageSuccessInd)) {  //webservice success
            return transformPerformSMRResponse(action, response, caseRec);
        }else{
            throw processMultiWSException(response.Header.MessageResponseStatus.ErrorStatus);
        }
    }

    /* private static method */
    private static TIBCO_SMR_Message_Type.Header_element generateWSHeader(){
        TIBCO_SMR_Message_Type.Header_element header = new TIBCO_SMR_Message_Type.Header_element();
        header.UserID = Userinfo.getUserName();
        header.UserType = 'Standard';
        header.MessageTimeStamp = datetime.now();
        return header;
    }

    private static SMRResponse transformValidateSMRResponse(String actionName, TIBCO_SMR_Message_Type.validateSpecialMeterReadResponse_element response, Case caseRec){

        caseRec.Existing_Order_1__c = response.validateSpecialMeterReadOutputData.UseOrder1Date;
        caseRec.Existing_Order_2__c = response.validateSpecialMeterReadOutputData.UseOrder2Date;
        caseRec.Last_Billed_Reading__c = response.validateSpecialMeterReadOutputData.LastBillDate;
        caseRec.Scheduled_Reading__c = response.validateSpecialMeterReadOutputData.SchedDate;
        caseRec.UnBilled_Reading__c= response.validateSpecialMeterReadOutputData.LastUnBillDate;

        //caseRec.Private_Extension_Flag__c = response.validateSpecialMeterReadOutputData.PrivateExtensionFlag;
        return transformSMRResponseStatusMessage(actionName, response.Header.MessageResponseStatus.ErrorStatus, caseRec);
    }

    private static SMRResponse transformPerformSMRResponse(String actionName, TIBCO_SMR_Message_Type.doSpecialMeterReadResponse_element response, Case caseRec){
        SMRResponse smrResponse = transformSMRResponseStatusMessage(actionName, response.Header.MessageResponseStatus.ErrorStatus, caseRec);
        smrResponse.isSMRClosed = response.SMRCloseCase;
        return smrResponse;
    }

    private static SMRResponse transformSMRResponseStatusMessage(String actionName, TIBCO_SMR_Message_Type.ErrorStatus_element[] errorStatuses, Case caseRec){
        SMRResponse smrResponse = new SMRResponse();
        smrResponse.actionName = actionName;
        smrResponse.isSuccessful = true;
        if(errorStatuses != null){
            for(TIBCO_SMR_Message_Type.ErrorStatus_element errorStatus: errorStatuses){
                if(Integer.valueOf(errorStatus.ErrorSeverity)>=4){
                    caseRec.Alerts_Int_Long__c += errorStatus.ErrorCode + '-' + errorStatus.ErrorDescription+'\n';
                    smrResponse.isSuccessful = false;
                } else {
                    caseRec.Information_Int_Long__c += errorStatus.ErrorCode + '-' + errorStatus.ErrorDescription+'\n';
                }
            }
        }
        smrResponse.caseRec = caseRec;
        return smrResponse;
    }
    private static MultipleWebServiceBusinessException processMultiWSException(List<Tibco_SMR_Message_Type.ErrorStatus_element> errorStatuses){
        MultipleWebServiceBusinessException multiWSEx = new MultipleWebServiceBusinessException('Errors returned from Special Meter Read Web Service');
        for(Tibco_SMR_Message_Type.ErrorStatus_element errorStatus: errorStatuses ){
            SingleWebServiceBusinessException ex = new SingleWebServiceBusinessException(errorStatus.ErrorDescription);
            ex.errorCode = errorStatus.ErrorCode;
            ex.errorSeverity = errorStatus.ErrorSeverity;
            multiWSEx.multiEx.add(ex);
        }
        return multiWSEx;
    }
}