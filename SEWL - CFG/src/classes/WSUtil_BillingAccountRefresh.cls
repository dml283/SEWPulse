/*
    Type:       Webservice Utility
    Purpose:    Calls TIBCO to refresh billing account

    Used By:    BillingAccountRefreshExCon
    ---------------------------------------------------------------
    History:

    15-Nov-2011 J.Pe (Davanti Consulting)    Created

*/
public class WSUtil_BillingAccountRefresh extends WSUtil{
    
    /* PUBLIC METHOD */
    public  void refreshBillingAccount(Billing_Account__c billAcct){
        
         // populate header info
        TibcoBillingAccountRefresh_MessageTypes.Header_element header = new TibcoBillingAccountRefresh_MessageTypes.Header_element();

        if (SystemSettings__c.getInstance().BRE_Debug_User__c == null)
            header.UserID = Userinfo.getUserName();
        else
            header.UserID = SystemSettings__c.getInstance().BRE_Debug_User__c;
            
        header.UserType = UserInfo.getUserType();
        header.MessageTimeStamp = datetime.now();

        // call webserive to get bill history
        TibcoBillingAccountRefresh_Service.refreshBillingAccount_xConsumer stub = new TibcoBillingAccountRefresh_Service.refreshBillingAccount_xConsumer();
        stub.timeout_x = 60000;
        TibcoBillingAccountRefresh_MessageTypes.refreshBillingAccountResponse_element response = stub.refreshBillingAccount(billAcct.HiAf_Account_Number__c, header);
        
        if (!Boolean.valueOf(response.header.MessageResponseStatus.MessageSuccessInd)){
            if(response.header.MessageResponseStatus.ErrorStatus.size()==0) throw new SingleWebServiceBusinessException('Unknown Error - please contact the system administrator');
            else throw new SingleWebServiceBusinessException(response.header.MessageResponseStatus.ErrorStatus[0].ErrorSeverity +' - '+response.header.MessageResponseStatus.ErrorStatus[0].ErrorDescription+' (Please contact the system administrator)');
        }
        
        if (response.ProcessOutputData.B_Balance != null && response.ProcessOutputData.B_Balance != '')
            billAcct.Balance__c = formatTibcoDecimal(response.ProcessOutputData.B_Balance);
        else
            billAcct.Balance__c = 0;
        
        billAcct.Billed__c = response.ProcessOutputData.B_BilledInd;
        billAcct.Concession_Number__c = response.ProcessOutputData.B_CONC_CardRef;
        billAcct.Card_Type__c = response.ProcessOutputData.B_CONC_CardType;
        billAcct.Card_Firstname__c = response.ProcessOutputData.B_CONC_FIRST_NAME;
        billAcct.Card_Lastname__c = response.ProcessOutputData.B_CONC_SURNAME;
        billAcct.Concession_End_Date__c = response.ProcessOutputData.B_ConcessEnd;
        billAcct.Valid_Concession__c = response.ProcessOutputData.B_ConcessPrincipal;
        billAcct.Concession_Start_Date__c = response.ProcessOutputData.B_CONCESSSTART;
        billAcct.Direct_Debit__c = response.ProcessOutputData.B_DD_Indicator;
        billAcct.Payment_Plan_Frequency__c = response.ProcessOutputData.B_Frequency;
        if(response.ProcessOutputData.B_NoPayments==null)
            billAcct.Payment_Plan_Number_of_Payments__c = null;
        else
            billAcct.Payment_Plan_Number_of_Payments__c = Decimal.valueOf(response.ProcessOutputData.B_NoPayments.replace(',',''));
        billAcct.Clerical__c = response.ProcessOutputData.B_O_Clerical;
        billAcct.Is_Payment_Plan__c = response.ProcessOutputData.B_PaymentPlan;
        billAcct.Last_Read_Date__c = response.ProcessOutputData.B_ReadDate;
        billAcct.Payment_Plan_End_Date__c = response.ProcessOutputData.B_ReviewDate;
        billAcct.Risk_Factor__c = response.ProcessOutputData.B_RiskIndicator;
        billAcct.Recovery_Last_Action__c = response.ProcessOutputData.B_SFLastAct;
        billAcct.Recovery_Last_Action_Date__c = response.ProcessOutputData.B_SFLastDate;
        billAcct.Recovery_Next_Action__c = response.ProcessOutputData.B_SFNextAct;
        billAcct.Recovery_Next_Action_Date__c = response.ProcessOutputData.B_SFNextDate;
        billAcct.Recovery_Path__c = response.ProcessOutputData.B_SFRecovPath;
        billAcct.Recovery_Suspended_Date__c = response.ProcessOutputData.B_SFSuspDate;
        billAcct.Payment_Plan_Start_Date__c = response.ProcessOutputData.B_StartDate;
        billAcct.Payment_Plan_Amount__c = formatTIBCODecimal(response.ProcessOutputData.B_StdPayment);

        update billAcct;
    }



}