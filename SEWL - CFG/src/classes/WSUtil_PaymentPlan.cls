/*
    Type:       Web Service Utility
    Purpose:    Controls the Payment Plan Integration Process

    Used By:    
    ---------------------------------------------------------------
    History:

    28-Nov-2011 J.Pe (Davanti Consulting)    Created

*/
public class WSUtil_PaymentPlan extends WSUtil{
    public static final Integer DEFAULT_NO_OF_SELECTED_BILLS = 4;

    /* Inner Class */
    public class PaymentPlanResponse{
        public Decimal weeklyAmount {get;set;}
        public Decimal fortnightlyAmount {get;set;}
        public Decimal monthlyAmount {get;set;}
        public Decimal est12MonthBill {get;set;}
        public Decimal estConcessionAllowed {get;set;}
        public Decimal estLoading {get;set;}
        public Decimal estUpfront {get;set;}
        public Decimal estCurrentBalance {get;set;}
        public Decimal estTotal {get;set;}
        public Boolean isSuccessful {get;set;}
        public List<String> messages{
            get{
                if(messages == null){
                    messages = new List<String>();
                }return messages;
            }private set;
        }
    }
    
    public static PaymentPlanResponse validatePaymentPlan(Case caseRec, List<WSUtil_Billing.BillDetails> allBills,  List<WSUtil_Billing.BillDetails> displayBills){
        TibcoPaymentPlan_MessageTypes.Header_element header = generateWSHeader();
        // Initialise Web Service
        TibcoPaymentPlan_Service.PaymentPlansEndpoint stub = new TibcoPaymentPlan_Service.PaymentPlansEndpoint();
        stub.timeout_x = 60000;   
        TibcoPaymentPlan_MessageTypes.ProcessInputData_element request = transformPaymentPlanValidateRequest(caseRec, allBills, displayBills);  
        TibcoPaymentPlan_MessageTypes.validatePaymentPlanResponse_element response = stub.validatePaymentPlans(header, request);
        return transformPaymentPlanResponse(response.ProcessOutputData, response.Header.MessageResponseStatus.ErrorStatus);
    }
    public static PaymentPlanResponse doPaymentPlan(Case caseRec){
        TibcoPaymentPlan_MessageTypes.Header_element header = generateWSHeader();
        // Initialise Web Service
        TibcoPaymentPlan_Service.PaymentPlansEndpoint stub = new TibcoPaymentPlan_Service.PaymentPlansEndpoint();
        stub.timeout_x = 60000;   
        TibcoPaymentPlan_MessageTypes.DoPaymentPlanInputData_element request = transformPaymentPlanDoRequest(caseRec);  
        TibcoPaymentPlan_MessageTypes.Header_element responseHeader = stub.doPaymentPlans(header,  request);
        return transformPaymentPlanResponse(null, responseHeader.MessageResponseStatus.ErrorStatus);
    }
    public static PaymentPlanResponse removePaymentPlan(Case caseRec){
        TibcoPaymentPlan_MessageTypes.Header_element header = generateWSHeader();
        // Initialise Web Service
        TibcoPaymentPlan_Service.PaymentPlansEndpoint stub = new TibcoPaymentPlan_Service.PaymentPlansEndpoint();
        stub.timeout_x = 60000;   
        TibcoPaymentPlan_MessageTypes.Header_element responseHeader = stub.deleteBudget(header, caseRec.Billing_Account__r.HiAF_Account_Number__c, caseRec.RemovePaymentPlan_Letter_Type__c, caseRec.Recovery_Path__c); // TODO clarify!!!
        return transformPaymentPlanResponse(null, responseHeader.MessageResponseStatus.ErrorStatus);
    }
    
    private static TibcoPaymentPlan_MessageTypes.Header_element generateWSHeader(){
        TibcoPaymentPlan_MessageTypes.Header_element header = new TibcoPaymentPlan_MessageTypes.Header_element();
        header.UserID = getUserId();
        header.UserType = Userinfo.getUserType();
        header.MessageTimeStamp = datetime.now();
        return header;
    }
    
    private static String getUserId(){
        if (SystemSettings__c.getInstance().BRE_Debug_User__c == null)
            return Userinfo.getUserName();
        else
            return SystemSettings__c.getInstance().BRE_Debug_User__c;    
    }
    
    private static TibcoPaymentPlan_MessageTypes.ProcessInputData_element transformPaymentPlanValidateRequest(Case caseRec, List<WSUtil_Billing.BillDetails> allBills,  List<WSUtil_Billing.BillDetails> displayBills){
        TibcoPaymentPlan_MessageTypes.ProcessInputData_element request = new TibcoPaymentPlan_MessageTypes.ProcessInputData_element(); 
        request.CustomerNumber = caseRec.Billing_Account__r.HiAF_Account_Number__c;
        if('Active'.equals(caseRec.Billing_Account__r.Status__c)){
            request.PropertyReference = caseRec.Billing_Account__r.Property__r.CIS_Property_Id__c;
        }
        request.UserId = getUserId();
        request.B_LBA_RECPATHSELECT = caseRec.Recovery_Path__c;
        request.B_LBA_UpfrontPaymt = caseRec.Upfront_Payment__c;
        request.B_LBA_UPFRONTPDATE = caseRec.Date_of_Payment__c;
        request.B_LBA_EST_12MTH = '12 months'.equals(caseRec.Term__c);
        request.B_LBA_EST_6MTH = '6 months'.equals(caseRec.Term__c);
        request.B_LBA_EST_24MTH = '24 months'.equals(caseRec.Term__c);
        request.B_LBA_RECPATHSELECT = caseRec.Recovery_Path__c;
        if(caseRec.Payment_Amount__c !=null){
            request.B_O_LBA_PMTFREQ = caseRec.Repayment_Frequency__c;       
            request.B_LBA_BudgetPaymtAmt = caseRec.Payment_Amount__c ;
            System.debug('*** Validate Payment Amount: ' + request.B_LBA_BudgetPaymtAmt);
            request.B_LBA_FirstpaymtDate = caseRec.First_Payment_Date__c;
        }
        request.B_O_SHOWBILLS = (allBills!=null);
        if(request.B_O_SHOWBILLS){
            List<WSUtil_Billing.BillDetails> selectedBills = new List<WSUtil_Billing.BillDetails>();
            for(WSUtil_Billing.BillDetails billRec: displayBills){
                if(billRec.selected) selectedBills.add(billRec);
            }
            List<WSUtil_Billing.BillDetails> specifiedBills = new List<WSUtil_Billing.BillDetails>();
            if(!selectedBills.isEmpty()){
                for(Integer i = 0; i < selectedBills.size() ; i++){
                    if(i<DEFAULT_NO_OF_SELECTED_BILLS ){
                        specifiedBills.add(selectedBills[i]);
                    }else{
                        selectedBills[i].selected = false;
                    }
                }
            }else{
                for(Integer i = 0 ; i < DEFAULT_NO_OF_SELECTED_BILLS ; i++){
                    if(i < displayBills.size()){
                        displayBills[i].selected = true;
                        specifiedBills.add(displayBills[i]);
                    }
                    else{
                        break;
                    }
                }
            }
            setSpecifiedBillInRequest(request, allBills, specifiedBills);
        }
        return request;
    }
    
    private static TibcoPaymentPlan_MessageTypes.DoPaymentPlanInputData_element transformPaymentPlanDoRequest(Case caseRec){
        TibcoPaymentPlan_MessageTypes.DoPaymentPlanInputData_element request = new TibcoPaymentPlan_MessageTypes.DoPaymentPlanInputData_element(); 
        request.CustomerNumber = caseRec.Billing_Account__r.HiAF_Account_Number__c;
        if('Active'.equals(caseRec.Billing_Account__r.Status__c)){
            request.PropertyReference = caseRec.Billing_Account__r.Property__r.CIS_Property_Id__c;
        }
        request.UserId = getUserId();
        request.B_LBA_UpfrontPaymt = caseRec.Upfront_Payment__c;
        request.B_LBA_UPFRONTPDATE = caseRec.Date_of_Payment__c;
        request.B_LBA_EST_12MTH = '12 months'.equals(caseRec.Term__c);
        request.B_LBA_EST_6MTH = '6 months'.equals(caseRec.Term__c);
        request.B_LBA_EST_24MTH = '24 months'.equals(caseRec.Term__c);
        System.debug('***** payment amount tibco : '+request.B_LBA_BudgetPaymtAmt);
        if(caseRec.Payment_Amount__c !=null){
            request.B_O_LBA_PMTFREQ = caseRec.Repayment_Frequency__c;       
            request.B_LBA_BudgetPaymtAmt = caseRec.Payment_Amount__c ;
            request.B_LBA_FirstpaymtDate = caseRec.First_Payment_Date__c;
        }
        System.debug('***** payment amount tibco after : '+request.B_LBA_BudgetPaymtAmt);
        request.B_LBA_noofpayments = Integer.valueOf(caseRec.Adhoc_Number_of_Payments__c) ;
        request.B_O_FIRSTVALUE = caseRec.Adhoc_First_Payment_Amount__c ;
        request.B_O_FIRSTDATE = caseRec.Adhoc_First_Payment_Date__c ;
        request.B_O_SECONDVALUE = caseRec.Adhoc_Second_Payment_Amount__c ;
        request.B_O_SECONDDATE = caseRec.Adhoc_Second_Payment_Date__c ;
        request.B_O_LASTVALUE = caseRec.Adhoc_Last_Payment_Amount__c;
        request.B_O_LASTDATE = caseRec.Adhoc_Last_Payment_Date__c;
        request.B_O_LBA_STUBFREQ = caseRec.Repayment_Frequency__c ;
        request.B_O_OTHERVALUE = caseRec.Adhoc_Regular_Payment_Amount__c ;
        request.B_O_PAYMENTOPTIONS = caseRec.Payment_Method__c ;
        return request;
    }
    
    private static void setSpecifiedBillInRequest(TibcoPaymentPlan_MessageTypes.ProcessInputData_element request, List<WSUtil_Billing.BillDetails> allBills,  List<WSUtil_Billing.BillDetails> specifiedBills){
        Integer checkSpecifiedBillIndex = 0;
        Integer checkAllBillIndex = 0;
        if(allBillMatchSpecifiedBill(checkAllBillIndex, checkSpecifiedBillIndex , allBills, specifiedBills)){
            request.B_O_LBA_SELECTBILL1='1';
            checkSpecifiedBillIndex ++;
        }else{
            request.B_O_LBA_SELECTBILL1='0';
        }
        checkAllBillIndex++;
        if(allBillMatchSpecifiedBill(checkAllBillIndex, checkSpecifiedBillIndex , allBills, specifiedBills)){
            request.B_O_LBA_SELECTBILL2='1';
            checkSpecifiedBillIndex ++;
        }else{
            request.B_O_LBA_SELECTBILL2='0';
        }
        checkAllBillIndex++;
        if(allBillMatchSpecifiedBill(checkAllBillIndex, checkSpecifiedBillIndex , allBills, specifiedBills)){
            request.B_O_LBA_SELECTBILL3='1';
            checkSpecifiedBillIndex ++;
        }else{
            request.B_O_LBA_SELECTBILL3='0';
        }
        checkAllBillIndex++;
        if(allBillMatchSpecifiedBill(checkAllBillIndex, checkSpecifiedBillIndex , allBills, specifiedBills)){
            request.B_O_LBA_SELECTBILL4='1';
            checkSpecifiedBillIndex ++;
        }else{
            request.B_O_LBA_SELECTBILL4='0';
        }
        checkAllBillIndex++;
        if(allBillMatchSpecifiedBill(checkAllBillIndex, checkSpecifiedBillIndex , allBills, specifiedBills)){
            request.B_O_LBA_SELECTBILL5='1';
            checkSpecifiedBillIndex ++;
        }else{
            request.B_O_LBA_SELECTBILL5='0';
        }
        checkAllBillIndex++;
        if(allBillMatchSpecifiedBill(checkAllBillIndex, checkSpecifiedBillIndex , allBills, specifiedBills)){
            request.B_O_LBA_SELECTBILL6='1';
            checkSpecifiedBillIndex ++;
        }else{
            request.B_O_LBA_SELECTBILL6='0';
        }
        checkAllBillIndex++;
        if(allBillMatchSpecifiedBill(checkAllBillIndex, checkSpecifiedBillIndex , allBills, specifiedBills)){
            request.B_O_LBA_SELECTBILL7='1';
            checkSpecifiedBillIndex ++;
        }else{
            request.B_O_LBA_SELECTBILL7='0';
        }
        checkAllBillIndex++;
        if(allBillMatchSpecifiedBill(checkAllBillIndex, checkSpecifiedBillIndex , allBills, specifiedBills)){
            request.B_O_LBA_SELECTBILL8='1';
            checkSpecifiedBillIndex ++;
        }else{
            request.B_O_LBA_SELECTBILL8='0';
        }
        checkAllBillIndex++;
        if(allBillMatchSpecifiedBill(checkAllBillIndex, checkSpecifiedBillIndex , allBills, specifiedBills)){
            request.B_O_LBA_SELECTBILL9='1';
            checkSpecifiedBillIndex ++;
        }else{
            request.B_O_LBA_SELECTBILL9='0';
        }
        checkAllBillIndex++;
        if(allBillMatchSpecifiedBill(checkAllBillIndex, checkSpecifiedBillIndex , allBills, specifiedBills)){
            request.B_O_LBA_SELECTBILL10='1';
            checkSpecifiedBillIndex ++;
        }else{
            request.B_O_LBA_SELECTBILL10='0';
        }
        checkAllBillIndex++;
    }
    
    private static boolean allBillMatchSpecifiedBill(Integer checkAllBillIndex , Integer checkSpecifiedBillIndex, List<WSUtil_Billing.BillDetails> allBills,  List<WSUtil_Billing.BillDetails> specifiedBills){
        return checkSpecifiedBillIndex < specifiedBills.size() 
            && checkAllBillIndex < allBills.size() 
            && allBills[checkAllBillIndex].BillNumber == specifiedBills[checkSpecifiedBillIndex].BillNumber;
    }
    
    private static PaymentPlanResponse transformPaymentPlanResponse(TibcoPaymentPlan_MessageTypes.ProcessOutputData_element processOutputData, List<TibcoPaymentPlan_MessageTypes.ErrorStatus_element> errorStatuses){
        PaymentPlanResponse transformedResponse = new PaymentPlanResponse();
        if(processOutputData!=null){
            transformedResponse.weeklyAmount = processOutputData.B_LBA_EST_WEEK;
            transformedResponse.fortnightlyAmount = processOutputData.B_LBA_EST_FNT;
            transformedResponse.monthlyAmount = processOutputData.B_LBA_EST_MTH;
            transformedResponse.est12MonthBill = processOutputData.B_LBA_EST12MTHSBILLS;
            transformedResponse.estConcessionAllowed = processOutputData.B_LBA_EST_CON_ALLOW;
            transformedResponse.estLoading = processOutputData.B_LBA_EST_LOADING;
            transformedResponse.estUpfront = processOutputData.B_LBA_EST_UPFRONT;
            transformedResponse.estCurrentBalance = processOutputData.B_LBA_EST_CURRBAL;
            transformedResponse.estTotal = processOutputData.B_LBA_EST_TOTAL;
        }
        transformedResponse.isSuccessful = true;
        if(errorStatuses != null){
            for(TibcoPaymentPlan_MessageTypes.ErrorStatus_element errorStatus: errorStatuses){
                transformedResponse.messages.add(errorStatus.ErrorDescription);
                if('4'.equals(errorStatus.ErrorSeverity)||'5'.equals(errorStatus.ErrorSeverity)){
                    transformedResponse.isSuccessful = false;
                }
            }
        }
        return transformedResponse;
    }
}