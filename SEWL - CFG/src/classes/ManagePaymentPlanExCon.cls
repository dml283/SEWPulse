/*
    Type:       Controller Extension
    Purpose:    Controls the ManagePaymentPlan VF page

    Used By:    ManagePaymentPlan 
    ---------------------------------------------------------------
    History:

    16-Nov-2011 J PE   Created

*/
public without sharing class ManagePaymentPlanExCon {

    /* private properties and variables */
    private static final Integer NO_OF_BILLS_FOR_WSDL = 10;
    private static final Integer MAX_NO_OF_BILLS_TO_DISPLAY = 6;
    private static final Decimal BILL_AMOUNT_TO_DISPLAY_IF_OVER = 5.0;
    private static final string SEW_CREDIT_USER_PROFILE_NAME = 'SEW Credit User';
    private static final string SEW_ADMIN_USER_PROFILE_NAME = 'SEW Administrator';
    private static final string SYS_ADMIN_USER_PROFILE_NAME = 'System Administrator';
    private Case currentCase{
        get{
            if (currentCase==null){
                currentCase = new Case();
            }
            if(currentCase.Billing_Account__c != null && (currentCase.Billing_Account__r==null||currentCase.Billing_Account__r.id!=currentCase.Billing_Account__c)){
                currentCase.Billing_Account__r = getBillAcctInfo(currentCase.Billing_Account__c);
            }
            return currentCase;
        }set;
    }
    
    private String currentUserProfileName  {get;set;}
    
    /* public properties and variables */
    
    public boolean isCentrePay {
        get{
            if(isCentrePay==null){
                isCentrePay = false;
                List<Customer_Classification__c> customerClassifications = currentCase.Billing_Account__r.getSObjects('Customer_Classifications__r');
                if(customerClassifications!=null&&!customerClassifications.isEmpty()){
                    for(Customer_Classification__c custClassRec: customerClassifications ){
                        if(custClassRec.Is_Active__c && 'CL'.equals(custClassRec.Class_Code__c)){
                            isCentrePay = true;
                        }
                    } 
                }
            }
            return isCentrePay;
        }private set;
    }
    
    public boolean isSEWCreditUserProfile{
        get{
            return SEW_CREDIT_USER_PROFILE_NAME.equals(currentUserProfileName)
                || SEW_ADMIN_USER_PROFILE_NAME.equals(currentUserProfileName)
                || SYS_ADMIN_USER_PROFILE_NAME.equals(currentUserProfileName);
        }
    }
    
    public boolean isClosedOrAdHoc{
        get{
            if(currentCase.Billing_Account__r == null) return false;
            if('Closed'.equals(currentCase.Billing_Account__r.Status__c)) return true;
            return false;
        }
    }
    
    public String managePaymentPlanMode{
        get;
        set{
            if(managePaymentPlanMode!=null && managePaymentPlanMode.equals(value)) return;
            managePaymentPlanMode = value;
            if(managePaymentPlanMode!=null) managePaymentPlanStepNo = 1;
            else managePaymentPlanStepNo = 0;
        }
    }
    public Integer managePaymentPlanStepNo{
        get{
            if(managePaymentPlanStepNo==null){
                managePaymentPlanStepNo = 0;
            } return managePaymentPlanStepNo;
        }
        set;
    }
    
    public String MANAGE_PAYMENT_PLAN_MODE_ADD {get{return 'Add';}}
    public String MANAGE_PAYMENT_PLAN_MODE_REMOVE {get{return 'Remove';}}
    
    public boolean isModifyPlan{
        get{
            if(isModifyPlan==null){
                isModifyPlan = false;
            }return isModifyPlan;
        }set;
    }
    
    public BillHistoryExCon billHistExCon{
        get{
            if(billHistExCon == null && currentCase.Billing_Account__r!=null && isEstimatedOnce){
                System.debug('NEWBILLHISTEXTCON');
                billHistExCon = new BillHistoryExCon(new ApexPages.StandardController(currentCase.Billing_Account__r));
            }return billHistExCon;
        }private set;
    }
    
    public boolean isEstimatedOnce{
        get{
            if(isEstimatedOnce==null){
                isEstimatedOnce = false;
            }return isEstimatedOnce;
        }set;
    }
    public List<EstimationSummaryTableRow> estimationSummaryTable {
        get{
            if(estimationSummaryTable == null){
                estimationSummaryTable = new List<EstimationSummaryTableRow>();
            }return estimationSummaryTable ;
        }private set;
    }
    public List<EstPaymentAmountTableRow > estPaymentAmountTable {
        get{
            if(estPaymentAmountTable == null){
                estPaymentAmountTable = new List<EstPaymentAmountTableRow>();
            }return estPaymentAmountTable;
        }private set;
    }
    
    public List<WSUtil_Billing.BillDetails> displayBills{ // Controls the displayed bills based on various biz rules
        get{
            if (displayBills != null) return displayBills;
            
            if(billHistExCon==null || billHistExCon.bills==null)return null;
            
            List<WSUtil_Billing.BillDetails> temp = new List<WSUtil_Billing.BillDetails>();
            // rules of what is relevant:
            // 1. only the first 10 bills returned
            // 2. in those first 10 bills:
            //    a. only normal bill
            //    b. that are more than 5 dollars
            //    c. display the latest 6 of those
            Integer countIndex = 0;
            Integer addedCount = 0;
            for(WSUtil_Billing.BillDetails bDetails: billHistExCon.bills){
                if(countIndex == NO_OF_BILLS_FOR_WSDL) break;
                if(addedCount == MAX_NO_OF_BILLS_TO_DISPLAY ) break;
                if(bDetails.isNormalBill && bDetails.BilledAmountDecimal >= BILL_AMOUNT_TO_DISPLAY_IF_OVER ){
                    temp.add(bDetails);
                    addedCount++;
                }
                countIndex ++;
            }
            return temp;
        }
    }
    
    public Integer nbrOfDisplayedBills { // nbr of displayed bills
        get {
            if (DisplayBills != null)
                return displayBills.Size();
            else
                return 0;   
        }
        set;
    }
        
    public String directDebitURLAmendPrefix{ 
        get{
            PageReference pageRef = Page.DirectDebitAmend;
            pageRef.getParameters().putAll(urlDefaultParameters);
            pageRef.getParameters().put('actionType','Add/Amend');
            return pageRef.getURL();
        }
    }
    public String directDebitURLCancelPrefix{ 
        get{
            PageReference pageRef = Page.DirectDebitAmend;
            pageRef.getParameters().putAll(urlDefaultParameters);
            pageRef.getParameters().put('actionType','Cancel');
            return pageRef.getURL();
        }
    }    
    
    private Map<String, String> urlDefaultParameters{
        get{
            PageReference pageRef = new PageReference('');
            if(currentCase.AccountId!=null){
                pageRef.getParameters().put('customerId',currentCase.AccountId);
            }
            if(currentCase.Billing_Account__c!=null){
                pageRef.getParameters().put('billAcctId',currentCase.Billing_Account__c);
            }
            if(currentCase.ContactId!=null){
                pageRef.getParameters().put('contactId',currentCase.ContactId);
            }
            pageRef.getParameters().put('budgets','true');
            return pageRef.getParameters();
        }
    }
    
    /* Constructor */
    
    public ManagePaymentPlanExCon(ApexPages.StandardController controller){
        Profile currentUserProfile = [SELECT Name FROM Profile WHERE Id = :Userinfo.getProfileId()];
        currentUserProfileName = currentUserProfile.Name;
        currentCase = (Case) controller.getRecord();
        if(currentCase.AccountId==null || currentCase.Billing_Account__c==null){
            Map<String, String> param = Apexpages.currentPage().getParameters();
            if(param.get('customerId')!= null) currentCase.AccountId = ((ID)param.get('customerId'));
            if(param.get('contactId')!= null) currentCase.ContactId= ((ID)param.get('contactId'));
            if(param.get('billAcctId')!= null) currentCase.Billing_Account__c = ((ID)param.get('billAcctId'));
            refreshCustomerDetails();
        }
        if(currentCase.Billing_Account__c != null){
            currentCase.Billing_Account__r = getBillAcctInfo(currentCase.Billing_Account__c);
        }  
        currentCase.Category_Level_1__c = 'Account Payment & Collections';
        currentCase.Category_Level_2__c = 'Payments';
        currentCase.Category_Level_3__c = 'Payment Plan';
        currentCase.Mode__c = 'Action';   
    }
    
    /* public methods */
    
    public void refreshCustomerDetails(){
        // to force a query of Billing Account Cases
        Case temp = currentCase;
    }
    
    public void setModeToAdd(){
        managePaymentPlanMode = MANAGE_PAYMENT_PLAN_MODE_ADD;
        isModifyPlan = false;

    }
    public void setModeToModify(){
        managePaymentPlanMode = MANAGE_PAYMENT_PLAN_MODE_ADD;
        isModifyPlan = true;
    }
    public void setModeToRemove(){
        managePaymentPlanMode = MANAGE_PAYMENT_PLAN_MODE_REMOVE;
    }
    
    public void estimatePaymentPlan(){
        estimatePaymentPlanCheckOK();
    }
    
    public void confirmPaymentCalculation(){
        boolean canProceedToNextStep = false;
        if(!isClosedOrAdHoc){
            if(isValidForConfirmNormalPaymentCalculation()){
                canProceedToNextStep = estimatePaymentPlanCheckOK();
            }
        }else{
            if(isValidForConfirmAdhocPaymentCalculation()){            
                if(currentCase.Adhoc_Number_of_Payments__c==1){
                    currentCase.Adhoc_First_Payment_Amount__c = currentCase.Billing_Account__r.Balance__c;
                }else if (currentCase.Adhoc_Number_of_Payments__c>3){
                    currentCase.Adhoc_First_Payment_Amount__c = currentCase.VF_ONLY_Adhoc_First_Payment_Amount__c;
                    currentCase.Adhoc_Last_Payment_Amount__c = currentCase.VF_ONLY_Adhoc_Last_Payment_Amount__c;
                }
                canProceedToNextStep = estimatePaymentPlanCheckOK();
            }
        }
        if(canProceedToNextStep){
            managePaymentPlanStepNo = 2;
            if(currentCase.Payment_Method__c == null && currentCase.Billing_Account__r.Direct_Debit__c){
                currentCase.Payment_Method__c = 'Direct Debit';
            }
        }
    }
    public void confirmPaymentMethod(){
        if(isValidPaymentMethod()){
            if(estimatePaymentPlanCheckOK()){
                managePaymentPlanStepNo = 3;
            }
        }
    }
    public void submitPaymentPlan(){
        boolean isSuccessful = true;
        if(isModifyPlan){
            isSuccessful = removePaymentPlanOK();
        }
        if(isSuccessful ){
            isSuccessful = submitPaymentPlanOK();
        }
        boolean isUpdateBillingAccount = false;
        if(isSuccessful ){
            managePaymentPlanStepNo = 4;
            currentCase.Status = 'Closed';
            refreshBillingAccount();
        }else{
            currentCase.Status = 'In Progress';
        }
        currentCase.RecordTypeId = [Select id from RecordType where DeveloperName = 'Payment_Plan' and SObjectType = 'Case'].id;
        upsert currentCase;
    }
    public void removePaymentPlan(){
        boolean isSuccessful = removePaymentPlanOK();
        boolean isUpdateBillingAccount = false;
        if(isSuccessful ){
            managePaymentPlanStepNo = 2;
            currentCase.Status = 'Closed';
            currentCase.Subject = 'Payment Plan Removed';
            refreshBillingAccount();
        }else{
            currentCase.Status = 'In Progress';
            currentCase.Subject = 'Payment Plan Removal Failed';
        }
        currentCase.RecordTypeId = [Select id from RecordType where DeveloperName = 'Payment_Plan' and SObjectType = 'Case'].id;
        upsert currentCase;
    }
    
    public void backOneStep(){
        managePaymentPlanStepNo--;
    }
    
    /* private methods*/
    
    private void refreshBillingAccount(){
        BillingAccountRefreshExCon refreshExCon = new BillingAccountRefreshExCon(new ApexPages.StandardController(currentCase.Billing_Account__r));
        refreshExCon.refreshBillingAccount();
    }
    
    private boolean estimatePaymentPlanCheckOK(){
        System.debug('**** payment amount: '+currentCase.Payment_Amount__c);
        if(!isValidForEstimate()) return false;
        boolean isSuccessful = false;
        isEstimatedOnce = true;
        try{
            WSUtil_PaymentPlan.PaymentPlanResponse response = WSUtil_PaymentPlan.validatePaymentPlan(currentCase, ((billHistExCon==null)?(null):(billHistExCon.bills)), displayBills);
            isSuccessful = response.isSuccessful ;
            isEstimatedOnce = isSuccessful ;
            estPaymentAmountTable = null;
            estimationSummaryTable = null;
            currentCase.Description = '';
            estPaymentAmountTable.add(new EstPaymentAmountTableRow(response));
            if(!isClosedOrAdHoc){
                String str;
                str = 'Based on the selected bills, the estimated amount to be raised in the next 12 months is: ';
                estimationSummaryTable.add(new EstimationSummaryTableRow(str, response.est12MonthBill) );
                currentCase.Description += str+'$'+((response.est12MonthBill==null)?('0.00'):(response.est12MonthBill.format()))+'\n';
                str = 'Less any concession allowance if newly added concession details: ';
                estimationSummaryTable.add(new EstimationSummaryTableRow(str , response.estConcessionAllowed ) );
                currentCase.Description += str+'$'+((response.estConcessionAllowed==null)?('0.00'):(response.estConcessionAllowed.format()))+'\n';
                str = 'Plus System Factor to allow for price increase: ';
                estimationSummaryTable.add(new EstimationSummaryTableRow(str , response.estLoading ) );
                currentCase.Description += str+'$'+((response.estLoading==null)?('0.00'):(response.estLoading.format())) +'\n';
                str = 'Less any Upfront Payment: ';
                estimationSummaryTable.add(new EstimationSummaryTableRow(str , response.estUpfront ) );
                currentCase.Description += str+'$'+((response.estUpfront==null)?('0.00'):(response.estUpfront.format())) +'\n';
                str = 'Plus any Current Balance: ';
                estimationSummaryTable.add(new EstimationSummaryTableRow(str , response.estCurrentBalance ) );
                currentCase.Description += str+'$'+((response.estCurrentBalance==null)?('0.00'):(response.estCurrentBalance.format())) +'\n';
                str = 'Total Amount the customer will pay: ';
                estimationSummaryTable.add(new EstimationSummaryTableRow(str , response.estTotal ) );
                currentCase.Description += str+'$'+((response.estTotal==null)?('0.00'):(response.estTotal.format())) +'\n';
            }else{
                currentCase.Description +=  'Number of Payments: '+currentCase.Adhoc_Number_of_Payments__c+'\n';
                if(currentCase.Adhoc_Number_of_Payments__c == 1){
                    currentCase.Description += 'First Payment Amount: $'+((currentCase.Billing_Account__r.Balance__c==null)?('0.00'):(currentCase.Billing_Account__r.Balance__c.format()))+', to pay on '+((currentCase.Adhoc_First_Payment_Date__c==null)?(''):(currentCase.Adhoc_First_Payment_Date__c.format()))+'\n';
                }
                else if(currentCase.Adhoc_Number_of_Payments__c == 2){
                    currentCase.Description += 'First Payment Amount: $'+((currentCase.Adhoc_First_Payment_Amount__c==null)?('0.00'):(currentCase.Adhoc_First_Payment_Amount__c.format()))+', to pay on '+((currentCase.Adhoc_First_Payment_Date__c==null)?(''):(currentCase.Adhoc_First_Payment_Date__c.format()))+'\n';
                    currentCase.Description += 'Second Payment Amount: $'+((currentCase.Adhoc_Second_Payment_Amount__c==null)?('0.00'):(currentCase.Adhoc_Second_Payment_Amount__c.format()))+', to pay on '+((currentCase.Adhoc_Second_Payment_Date__c==null)?(''):(currentCase.Adhoc_Second_Payment_Date__c.format()))+'\n';
                }
                else if(currentCase.Adhoc_Number_of_Payments__c == 3){
                    currentCase.Description += 'First Payment Amount: $'+((currentCase.Adhoc_First_Payment_Amount__c==null)?('0.00'):(currentCase.Adhoc_First_Payment_Amount__c.format()))+', to pay on '+((currentCase.Adhoc_First_Payment_Date__c==null)?(''):(currentCase.Adhoc_First_Payment_Date__c.format()))+'\n';
                    currentCase.Description += 'Second Payment Amount: $'+((currentCase.Adhoc_Second_Payment_Amount__c==null)?('0.00'):(currentCase.Adhoc_Second_Payment_Amount__c.format()))+', to pay on '+((currentCase.Adhoc_Second_Payment_Date__c==null)?(''):(currentCase.Adhoc_Second_Payment_Date__c.format()))+'\n';
                    currentCase.Description += 'Last Payment Amount: $'+((currentCase.Adhoc_Last_Payment_Amount__c==null)?('0.00'):(currentCase.Adhoc_Last_Payment_Amount__c.format()))+', to pay on '+((currentCase.Adhoc_Last_Payment_Date__c==null)?(''):(currentCase.Adhoc_Last_Payment_Date__c.format()))+'\n';                    
                }else {
                    currentCase.Description += 'Repayment Frequency: '+currentCase.Repayment_Frequency__c+', starting on '+((currentCase.Adhoc_First_Payment_Date__c==null)?(''):(currentCase.Adhoc_First_Payment_Date__c.format()))+'\n';
                    if(currentCase.VF_ONLY_Adhoc_First_Payment_Amount__c!=null){
                        currentCase.Description += 'First Payment Amount: $'+((currentCase.VF_ONLY_Adhoc_First_Payment_Amount__c==null)?('0.00'):(currentCase.VF_ONLY_Adhoc_First_Payment_Amount__c.format()))+'\n';
                    }
                    currentCase.Description += 'Regular Payment Amount: $'+((currentCase.Adhoc_Regular_Payment_Amount__c==null)?('0.00'):(currentCase.Adhoc_Regular_Payment_Amount__c.format()))+'\n';
                    if(currentCase.VF_ONLY_Adhoc_Last_Payment_Amount__c!=null){
                        currentCase.Description += 'Last Payment Amount: $'+((currentCase.VF_ONLY_Adhoc_Last_Payment_Amount__c==null)?('0.00'):(currentCase.VF_ONLY_Adhoc_Last_Payment_Amount__c.format()))+'\n';
                    }
                }
            }
            for(String msgStr: response.messages){
                ApexPages.addmessage(
                    new ApexPages.message(ApexPages.severity.WARNING,msgStr)
                );
            }
        }catch(System.CalloutException ex){     // SOAP Error
            ApexPages.addmessage(
                new ApexPages.message(ApexPages.severity.ERROR,'Problem with web service - please contact system administrator. Error message:'+ex.getMessage())
            );
            isEstimatedOnce = false;
            return false;
        } catch (WSUtil.MultipleWebServiceBusinessException e) {    // Error return from webservice - Business level
            for (WSUtil.SingleWebServiceBusinessException err: e.multiEx) {
                ApexPages.addmessage(
                    new ApexPages.message(ApexPages.severity.ERROR,err.getMessage())
                );
            }
            isEstimatedOnce = false;
            return false;
        }        
        return isSuccessful ;
    }
    
    private static final String REQUIRED_FIELD_MSG = 'Field is Mandatory';
    private boolean isValidForEstimate(){
        boolean isValid = true;
        if(!isClosedOrAdHoc){
            if(currentCase.Term__c == null){
                isValid = false;
                currentCase.Term__c.addError(REQUIRED_FIELD_MSG);
            }
            if(currentCase.Upfront_Payment__c == null && currentCase.Date_of_Payment__c != null){
                isValid = false;
                currentCase.Upfront_Payment__c.addError(REQUIRED_FIELD_MSG+' if the date is filled in');
            }
            if(currentCase.Upfront_Payment__c != null && currentCase.Date_of_Payment__c == null){
                isValid = false;
                currentCase.Date_of_Payment__c.addError(REQUIRED_FIELD_MSG+' if the amount is filled in');
            }
        }
        return isValid;
    }
    private boolean isValidForConfirmNormalPaymentCalculation(){
        boolean isValid = isValidForEstimate();
        if(currentCase.Repayment_Frequency__c == null){
            isValid = false;
            currentCase.Repayment_Frequency__c.addError(REQUIRED_FIELD_MSG);
        }
        if(currentCase.Payment_Amount__c == null){
            isValid = false;
            currentCase.Payment_Amount__c.addError(REQUIRED_FIELD_MSG);
        }
        if(currentCase.First_Payment_Date__c == null){
            isValid = false;
            currentCase.First_Payment_Date__c.addError(REQUIRED_FIELD_MSG);
        }
        return isValid;
    }
    private boolean isValidForConfirmAdhocPaymentCalculation(){
        boolean isValid = true;
        if(currentCase.Adhoc_Number_of_Payments__c == null || currentCase.Adhoc_Number_of_Payments__c<1){
            isValid = false;
            currentCase.Adhoc_Number_of_Payments__c.addError(REQUIRED_FIELD_MSG+' and must be above 0');
        }else{
            if(currentCase.Adhoc_First_Payment_Date__c == null){
                isValid = false;
                currentCase.Adhoc_First_Payment_Date__c.addError(REQUIRED_FIELD_MSG);
            }
            if(currentCase.Adhoc_Number_of_Payments__c >= 2 && currentCase.Adhoc_Number_of_Payments__c <=3 ){
                if(currentCase.Adhoc_Second_Payment_Amount__c == null || currentCase.Adhoc_Second_Payment_Amount__c <=0.0){
                    isValid = false;
                    currentCase.Adhoc_Second_Payment_Amount__c.addError(REQUIRED_FIELD_MSG+' and must be above 0.0');
                }
                if(currentCase.Adhoc_Second_Payment_Date__c == null){
                    isValid = false;
                    currentCase.Adhoc_Second_Payment_Date__c.addError(REQUIRED_FIELD_MSG);
                }
                if(currentCase.Adhoc_First_Payment_Amount__c == null || currentCase.Adhoc_First_Payment_Amount__c <=0.0){
                    isValid = false;
                    currentCase.Adhoc_First_Payment_Amount__c.addError(REQUIRED_FIELD_MSG+' and must be above 0.0');
                }
            }
            if(currentCase.Adhoc_Number_of_Payments__c ==3 ){
                if(currentCase.Adhoc_Last_Payment_Amount__c== null || currentCase.Adhoc_Last_Payment_Amount__c<=0.0){
                    isValid = false;
                    currentCase.Adhoc_Last_Payment_Amount__c.addError(REQUIRED_FIELD_MSG+' and must be above 0.0');
                }
                if(currentCase.Adhoc_Last_Payment_Date__c== null){
                    isValid = false;
                    currentCase.Adhoc_Last_Payment_Date__c.addError(REQUIRED_FIELD_MSG);
                }
            }
            if(currentCase.Adhoc_Number_of_Payments__c > 3 ){
                if(currentCase.Repayment_Frequency__c == null){
                    isValid = false;
                    currentCase.Repayment_Frequency__c.addError(REQUIRED_FIELD_MSG);
                }
                if(currentCase.Adhoc_Regular_Payment_Amount__c == null || currentCase.Adhoc_Regular_Payment_Amount__c <=0.0){
                    isValid = false;
                    currentCase.Adhoc_Regular_Payment_Amount__c.addError(REQUIRED_FIELD_MSG+' and must be above 0.0');
                }
                if(currentCase.VF_ONLY_Adhoc_First_Payment_Amount__c == null && currentCase.VF_ONLY_Adhoc_Last_Payment_Amount__c == null){
                    isValid = false;
                    currentCase.VF_ONLY_Adhoc_First_Payment_Amount__c.addError('One of either first or last payment amount is mandatory');
                    currentCase.VF_ONLY_Adhoc_Last_Payment_Amount__c.addError('One of either first or last payment amount is mandatory');
                }else{
                    if (currentCase.VF_ONLY_Adhoc_First_Payment_Amount__c != null && currentCase.VF_ONLY_Adhoc_First_Payment_Amount__c <=0.0){
                        isValid = false;
                        currentCase.VF_ONLY_Adhoc_First_Payment_Amount__c.addError('Value must be above 0.0');
                    }
                    if (currentCase.VF_ONLY_Adhoc_Last_Payment_Amount__c != null && currentCase.VF_ONLY_Adhoc_Last_Payment_Amount__c <=0.0){
                        isValid = false;
                        currentCase.VF_ONLY_Adhoc_Last_Payment_Amount__c.addError('Value must be above 0.0');
                    }
                }
            }
        }
        if(isValid){
            Decimal balance;
            if(currentCase.Adhoc_Number_of_Payments__c == 2){
                isValid = checkBalanceMatch(currentCase.Adhoc_First_Payment_Amount__c + currentCase.Adhoc_Second_Payment_Amount__c);
            }else if (currentCase.Adhoc_Number_of_Payments__c == 3){
                isValid = checkBalanceMatch(currentCase.Adhoc_First_Payment_Amount__c + currentCase.Adhoc_Second_Payment_Amount__c + currentCase.Adhoc_Last_Payment_Amount__c);
            }else if (currentCase.Adhoc_Number_of_Payments__c > 3){
                isValid = checkBalanceMatch(((currentCase.VF_ONLY_Adhoc_First_Payment_Amount__c==null)?(0.0):(currentCase.VF_ONLY_Adhoc_First_Payment_Amount__c))
                     + (currentCase.Adhoc_Regular_Payment_Amount__c * (currentCase.Adhoc_Number_of_Payments__c-1))
                     + ((currentCase.VF_ONLY_Adhoc_Last_Payment_Amount__c==null)?(0.0):(currentCase.VF_ONLY_Adhoc_Last_Payment_Amount__c)));
            }
        }
        return isValid;
    }
    private boolean checkBalanceMatch(Decimal balance){
        if(balance != currentCase.Billing_Account__r.Balance__c){
            ApexPages.addmessage(
                new ApexPages.message(ApexPages.severity.ERROR,BALANCE_ERROR_MSG + Math.abs(currentCase.Billing_Account__r.Balance__c-balance ) + '.')
            );
            return false;
        }return true;
    }
    private static final String BALANCE_ERROR_MSG = 'The total of all payments must match with the closed account balance - currently there is a difference of $';
    
    private boolean isValidPaymentMethod(){
        if(currentCase.Payment_Method__c == null){
            currentCase.Payment_Method__c.addError(REQUIRED_FIELD_MSG);
            return false;
        }else{
            currentCase.Billing_Account__r = null;
            if(currentCase.Billing_Account__r.Direct_Debit__c && !'Direct Debit'.equals(currentCase.Payment_Method__c)){
                currentCase.Payment_Method__c.addError('Direct Debit arrangement exists on the account - Payment Method must be Direct Debit.');
                return false;
            }else if (!currentCase.Billing_Account__r.Direct_Debit__c && 'Direct Debit'.equals(currentCase.Payment_Method__c)){
                currentCase.Payment_Method__c.addError('Direct Debit arrangement does not exist on the account - Payment Method cannot be Direct Debit.');
                return false;
            }
        }return true;
    }
    
    private boolean submitPaymentPlanOK(){
        boolean isSuccessful = false;
        try{
            WSUtil_PaymentPlan.PaymentPlanResponse response = WSUtil_PaymentPlan.doPaymentPlan(currentCase);
            isSuccessful = response.isSuccessful ;
            currentCase.Information_Int_Long__c = '';
            currentCase.Alerts_Int_Long__c = '';
            for(String msgStr: response.messages){
                ApexPages.addmessage(
                    new ApexPages.message(ApexPages.severity.WARNING,msgStr)
                );
                if(isSuccessful){
                    currentCase.Information_Int_Long__c += msgStr+'\n';
                }else{
                    currentCase.Alerts_Int_Long__c += msgStr+'\n';
                }
            }
        }catch(System.CalloutException ex){     // SOAP Error
            ApexPages.addmessage(
                new ApexPages.message(ApexPages.severity.ERROR,'Problem with web service - please contact system administrator. Error message:'+ex.getMessage())
            );
            return false;
        } catch (WSUtil.MultipleWebServiceBusinessException e) {    // Error return from webservice - Business level
            for (WSUtil.SingleWebServiceBusinessException err: e.multiEx) {
                ApexPages.addmessage(
                    new ApexPages.message(ApexPages.severity.ERROR,err.getMessage())
                );
            }
            return false;
        }
        return isSuccessful ;
    }
    
    private boolean removePaymentPlanOK(){
        boolean isSuccessful = false;
        try{
            WSUtil_PaymentPlan.PaymentPlanResponse response = WSUtil_PaymentPlan.removePaymentPlan(currentCase);
            isSuccessful = response.isSuccessful ;
            for(String msgStr: response.messages){
                ApexPages.addmessage(
                    new ApexPages.message(ApexPages.severity.WARNING,msgStr)
                );
            }
        }catch(System.CalloutException ex){     // SOAP Error
            ApexPages.addmessage(
                new ApexPages.message(ApexPages.severity.ERROR,'Problem with web service - please contact system administrator. Error message:'+ex.getMessage())
            );
            return false;
        } catch (WSUtil.MultipleWebServiceBusinessException e) {    // Error return from webservice - Business level
            for (WSUtil.SingleWebServiceBusinessException err: e.multiEx) {
                ApexPages.addmessage(
                    new ApexPages.message(ApexPages.severity.ERROR,err.getMessage())
                );
            }
            return false;
        }
        return isSuccessful ;
    }
    
    private static Billing_Account__c getBillAcctInfo(Id billAcctId){
        return [Select id, Name, Payment_Plan_Start_Date__c, Payment_Plan_End_Date__c,Payment_Plan_Frequency__c,
                        Payment_Plan_Number_of_Payments__c,Payment_Plan_Amount__c, Status__c , RecordType.DeveloperName, Balance__c, Risk_Factor__c, 
                        Is_Payment_Plan__c, Property__c, Property__r.CIS_Property_Id__c, HiAF_Account_Number__c, Direct_Debit__c, Recovery_Path__c, 
                        (select Class_Code__c, Is_Active__c from Customer_Classifications__r where (Class_Code__c = 'CL') AND Is_Active__c = true) 
                        from Billing_Account__c where id = :billAcctId];
    }
    
    /* Inner classes */
    
    public class EstPaymentAmountTableRow {
        public Decimal monthlyAmount{get{return response.monthlyAmount;}set;}
        public Decimal fortnightlyAmount{get{return response.fortnightlyAmount;}set;}
        public Decimal weeklyAmount{get{return response.weeklyAmount;}set;}
        private WSUtil_PaymentPlan.PaymentPlanResponse response;
        public EstPaymentAmountTableRow(WSUtil_PaymentPlan.PaymentPlanResponse response){
            this.response = response;
        }
    }
    
    public class EstimationSummaryTableRow {
        public String description{get;set;}
        public Decimal amount{
            get{
                if(amount==null){
                    amount = 0;
                }return amount;
            }
            set;
        }
        public EstimationSummaryTableRow(String description, Decimal amount){
            this.description = description;
            this.amount = amount;
        }
    }
    
    /* Test method */
    
    public static testmethod void test_ManagePaymentPlanExCon(){
        Account customer = new Account(Name = 'test');
        insert customer;
        
        Billing_Account__c billAcct = new Billing_Account__c(Name = 'TBD', Status__c = 'Active', 
                        Balance__c = 50, Risk_Factor__c = 'L', Is_Payment_Plan__c = false,HiAF_Account_Number__c = 'sdfsefr', 
                        Direct_Debit__c = true, Customer__c = customer.id);
        insert billAcct;
        PageReference pageRef = Page.ManagePaymentPlan;
        pageRef.getParameters().put('customerId', customer.id);
        pageRef.getParameters().put('billAcctId', billAcct.id);
        Test.setCurrentPage(pageRef);
        ManagePaymentPlanExCon exCon = new ManagePaymentPlanExCon(new ApexPages.StandardController(new Case()));
        Boolean tempBool = exCon.isSEWCreditUserProfile;
        tempBool = exCon.isModifyPlan;
        tempBool = exCon.isEstimatedOnce;
        exCon.managePaymentPlanMode = null;
        Integer tempInt = exCon.managePaymentPlanStepNo;
        System.AssertEquals(false,exCon.isClosedOrAdHoc);
        exCon.refreshCustomerDetails();
        exCon.setModeToRemove();
        exCon.setModeToAdd();
        exCon.setModeToModify();
        exCon.estimatePaymentPlan();
        exCon.currentCase.Term__c = '24 months';
        exCon.estimatePaymentPlan();
        exCon.confirmPaymentCalculation();
        exCon.currentCase.Repayment_Frequency__c = 'Monthly';
        exCon.currentCase.Payment_Amount__c = 1.0;
        exCon.currentCase.First_Payment_Date__c = Date.today();
        exCon.confirmPaymentCalculation();
        exCon.currentCase.Payment_Method__c = null;
        exCon.confirmPaymentMethod();
        exCon.currentCase.Payment_Method__c = 'test';
        exCon.confirmPaymentMethod();
        exCon.currentCase.Payment_Method__c = 'Direct Debit';
        exCon.confirmPaymentMethod();
        exCon.submitPaymentPlan();
        String tempStr = excon.directDebitURLAmendPrefix;
        tempStr = excon.directDebitURLCancelPrefix;
        exCon.backOneStep();
        exCon.removePaymentPlan();
        
        billAcct.Status__c = 'Closed';
        billAcct.Direct_Debit__c = false;
        update billAcct;
        exCon = new ManagePaymentPlanExCon(new ApexPages.StandardController(new Case()));
        System.AssertEquals(true,exCon.isClosedOrAdHoc);
        exCon.setModeToAdd();
        exCon.confirmPaymentCalculation();
        exCon.currentCase.Adhoc_Number_of_Payments__c = 1;
        exCon.confirmPaymentCalculation();
        exCon.currentCase.Adhoc_First_Payment_Date__c = Date.today();
        exCon.confirmPaymentCalculation();
        exCon.currentCase.Adhoc_Number_of_Payments__c = 2;
        exCon.currentCase.Adhoc_First_Payment_Amount__c = null;
        exCon.confirmPaymentCalculation();
        exCon.currentCase.Adhoc_Second_Payment_Amount__c = 1.0;
        exCon.currentCase.Adhoc_Second_Payment_Date__c = Date.today();
        exCon.currentCase.Adhoc_First_Payment_Amount__c = 1.0;
        exCon.confirmPaymentCalculation();
        exCon.currentCase.Adhoc_Number_of_Payments__c = 3;
        exCon.confirmPaymentCalculation();
        exCon.currentCase.Adhoc_Last_Payment_Amount__c = 1.0;
        exCon.currentCase.Adhoc_Last_Payment_Date__c = Date.today();
        exCon.confirmPaymentCalculation();
        exCon.currentCase.Adhoc_Number_of_Payments__c = 5;
        exCon.confirmPaymentCalculation();
        exCon.currentCase.Repayment_Frequency__c = 'Monthly';
        exCon.currentCase.Adhoc_Regular_Payment_Amount__c = 1.0;
        exCon.confirmPaymentCalculation();
        exCon.currentCase.VF_ONLY_Adhoc_First_Payment_Amount__c = -1.0;
        exCon.confirmPaymentCalculation();
        exCon.currentCase.VF_ONLY_Adhoc_Last_Payment_Amount__c = -1.0;
        exCon.confirmPaymentCalculation();
        exCon.currentCase.VF_ONLY_Adhoc_First_Payment_Amount__c = 1.0;
        exCon.confirmPaymentCalculation();
        exCon.currentCase.VF_ONLY_Adhoc_Last_Payment_Amount__c = 1.0;
        exCon.confirmPaymentCalculation();
        exCon.currentCase.Adhoc_Number_of_Payments__c = 2;
        exCon.confirmPaymentCalculation();
        exCon.currentCase.Adhoc_Second_Payment_Amount__c = 25.0;
        exCon.currentCase.Adhoc_Second_Payment_Date__c = Date.today();
        exCon.currentCase.Adhoc_First_Payment_Amount__c = 25.0;
        exCon.confirmPaymentCalculation();
        exCon.currentCase.Adhoc_Number_of_Payments__c = 3;
        exCon.confirmPaymentCalculation();
        exCon.currentCase.Adhoc_Second_Payment_Amount__c = 20.0;
        exCon.currentCase.Adhoc_First_Payment_Amount__c = 20.0;
        exCon.currentCase.Adhoc_Last_Payment_Amount__c = 10.0;
        exCon.currentCase.Adhoc_Last_Payment_Date__c = Date.today();
        exCon.confirmPaymentCalculation();
        exCon.currentCase.Adhoc_Number_of_Payments__c = 5;
        exCon.confirmPaymentCalculation();
        exCon.currentCase.Repayment_Frequency__c = 'Monthly';
        exCon.currentCase.Adhoc_Regular_Payment_Amount__c = 10.0;
        exCon.confirmPaymentCalculation();
        exCon.currentCase.VF_ONLY_Adhoc_First_Payment_Amount__c = 10.0;
        exCon.confirmPaymentCalculation();
        exCon.currentCase.VF_ONLY_Adhoc_Last_Payment_Amount__c = null;
        exCon.confirmPaymentCalculation();
        exCon.currentCase.Payment_Method__c = null;
        exCon.confirmPaymentMethod();
        exCon.currentCase.Payment_Method__c = 'Direct Debit';
        exCon.confirmPaymentMethod();
        exCon.currentCase.Payment_Method__c = 'test';
        exCon.confirmPaymentMethod();
        tempBool = exCon.isCentrePay;
        
    }
}