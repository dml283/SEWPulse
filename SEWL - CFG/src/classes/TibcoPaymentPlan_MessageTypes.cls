//Generated by wsdl2apex

public class TibcoPaymentPlan_MessageTypes {
    public class Header_element {
        public String MessageID;
        public TibcoPaymentPlan_MessageTypes.MessageResponseStatus_element MessageResponseStatus;
        public DateTime MessageTimeStamp;
        public String UserID;
        public String UserType;
        private String[] MessageID_type_info = new String[]{'MessageID','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
        private String[] MessageResponseStatus_type_info = new String[]{'MessageResponseStatus','http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','MessageResponseStatus_element','0','1','false'};
        private String[] MessageTimeStamp_type_info = new String[]{'MessageTimeStamp','http://www.w3.org/2001/XMLSchema','dateTime','1','1','false'};
        private String[] UserID_type_info = new String[]{'UserID','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] UserType_type_info = new String[]{'UserType','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','true','false'};
        private String[] field_order_type_info = new String[]{'MessageID','MessageResponseStatus','MessageTimeStamp','UserID','UserType'};
    }
    public class validatePaymentPlanRequest_element {
        public TibcoPaymentPlan_MessageTypes.Header_element Header;
        public TibcoPaymentPlan_MessageTypes.ProcessInputData_element ProcessInputData;
        private String[] Header_type_info = new String[]{'Header','http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','Header_element','1','1','false'};
        private String[] ProcessInputData_type_info = new String[]{'ProcessInputData','http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','ProcessInputData_element','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','true','false'};
        private String[] field_order_type_info = new String[]{'Header','ProcessInputData'};
    }
    public class ProcessInputData_element {
        public String CustomerNumber;
        public String PropertyReference;
        public String UserId;
        public String B_LBA_RECPATHSELECT;
        public Decimal B_LBA_UpfrontPaymt;
        public Date B_LBA_UPFRONTPDATE;
        public Boolean B_LBA_EST_12MTH;
        public Boolean B_LBA_EST_6MTH;
        public Boolean B_LBA_EST_24MTH;
        public Boolean B_O_SHOWBILLS;
        public String B_O_LBA_SELECTBILL1;
        public String B_O_LBA_SELECTBILL2;
        public String B_O_LBA_SELECTBILL3;
        public String B_O_LBA_SELECTBILL4;
        public String B_O_LBA_SELECTBILL5;
        public String B_O_LBA_SELECTBILL6;
        public String B_O_LBA_SELECTBILL7;
        public String B_O_LBA_SELECTBILL8;
        public String B_O_LBA_SELECTBILL9;
        public String B_O_LBA_SELECTBILL10;
        public String B_O_LBA_PMTFREQ;
        public Decimal B_LBA_BudgetPaymtAmt;
        public Date B_LBA_FirstpaymtDate;
        private String[] CustomerNumber_type_info = new String[]{'CustomerNumber','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] PropertyReference_type_info = new String[]{'PropertyReference','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
        private String[] UserId_type_info = new String[]{'UserId','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
        private String[] B_LBA_RECPATHSELECT_type_info = new String[]{'B-LBA-RECPATHSELECT','http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','B-LBA-RECPATHSELECT_element','0','1','false'};
        private String[] B_LBA_UpfrontPaymt_type_info = new String[]{'B-LBA-UpfrontPaymt','http://www.w3.org/2001/XMLSchema','decimal','0','1','false'};
        private String[] B_LBA_UPFRONTPDATE_type_info = new String[]{'B-LBA-UPFRONTPDATE','http://www.w3.org/2001/XMLSchema','date','0','1','false'};
        private String[] B_LBA_EST_12MTH_type_info = new String[]{'B-LBA-EST-12MTH','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] B_LBA_EST_6MTH_type_info = new String[]{'B-LBA-EST-6MTH','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] B_LBA_EST_24MTH_type_info = new String[]{'B-LBA-EST-24MTH','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] B_O_SHOWBILLS_type_info = new String[]{'B-O-SHOWBILLS','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] B_O_LBA_SELECTBILL1_type_info = new String[]{'B-O-LBA-SELECTBILL1','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
        private String[] B_O_LBA_SELECTBILL2_type_info = new String[]{'B-O-LBA-SELECTBILL2','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
        private String[] B_O_LBA_SELECTBILL3_type_info = new String[]{'B-O-LBA-SELECTBILL3','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
        private String[] B_O_LBA_SELECTBILL4_type_info = new String[]{'B-O-LBA-SELECTBILL4','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
        private String[] B_O_LBA_SELECTBILL5_type_info = new String[]{'B-O-LBA-SELECTBILL5','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
        private String[] B_O_LBA_SELECTBILL6_type_info = new String[]{'B-O-LBA-SELECTBILL6','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
        private String[] B_O_LBA_SELECTBILL7_type_info = new String[]{'B-O-LBA-SELECTBILL7','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
        private String[] B_O_LBA_SELECTBILL8_type_info = new String[]{'B-O-LBA-SELECTBILL8','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
        private String[] B_O_LBA_SELECTBILL9_type_info = new String[]{'B-O-LBA-SELECTBILL9','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
        private String[] B_O_LBA_SELECTBILL10_type_info = new String[]{'B-O-LBA-SELECTBILL10','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
        private String[] B_O_LBA_PMTFREQ_type_info = new String[]{'B-O-LBA-PMTFREQ','http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','B-O-LBA-PMTFREQ_element','0','1','false'};
        private String[] B_LBA_BudgetPaymtAmt_type_info = new String[]{'B-LBA-BudgetPaymtAmt','http://www.w3.org/2001/XMLSchema','decimal','0','1','false'};
        private String[] B_LBA_FirstpaymtDate_type_info = new String[]{'B-LBA-FirstpaymtDate','http://www.w3.org/2001/XMLSchema','date','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','true','false'};
        private String[] field_order_type_info = new String[]{'CustomerNumber','PropertyReference','UserId','B_LBA_RECPATHSELECT','B_LBA_UpfrontPaymt','B_LBA_UPFRONTPDATE','B_LBA_EST_12MTH','B_LBA_EST_6MTH','B_LBA_EST_24MTH','B_O_SHOWBILLS','B_O_LBA_SELECTBILL1','B_O_LBA_SELECTBILL2','B_O_LBA_SELECTBILL3','B_O_LBA_SELECTBILL4','B_O_LBA_SELECTBILL5','B_O_LBA_SELECTBILL6','B_O_LBA_SELECTBILL7','B_O_LBA_SELECTBILL8','B_O_LBA_SELECTBILL9','B_O_LBA_SELECTBILL10','B_O_LBA_PMTFREQ','B_LBA_BudgetPaymtAmt','B_LBA_FirstpaymtDate'};
    }
    public class ProcessOutputData_element {
        public Decimal B_LBA_EST_WEEK;
        public Decimal B_LBA_EST_FNT;
        public Decimal B_LBA_EST_MTH;
        public Decimal B_LBA_EST12MTHSBILLS;
        public Decimal B_LBA_EST_CON_ALLOW;
        public Decimal B_LBA_EST_LOADING;
        public Decimal B_LBA_EST_UPFRONT;
        public Decimal B_LBA_EST_CURRBAL;
        public Decimal B_LBA_EST_TOTAL;
        private String[] B_LBA_EST_WEEK_type_info = new String[]{'B-LBA-EST-WEEK','http://www.w3.org/2001/XMLSchema','decimal','0','1','false'};
        private String[] B_LBA_EST_FNT_type_info = new String[]{'B-LBA-EST-FNT','http://www.w3.org/2001/XMLSchema','decimal','0','1','false'};
        private String[] B_LBA_EST_MTH_type_info = new String[]{'B-LBA-EST-MTH','http://www.w3.org/2001/XMLSchema','decimal','0','1','false'};
        private String[] B_LBA_EST12MTHSBILLS_type_info = new String[]{'B-LBA-EST12MTHSBILLS','http://www.w3.org/2001/XMLSchema','decimal','0','1','false'};
        private String[] B_LBA_EST_CON_ALLOW_type_info = new String[]{'B-LBA-EST-CON-ALLOW','http://www.w3.org/2001/XMLSchema','decimal','0','1','false'};
        private String[] B_LBA_EST_LOADING_type_info = new String[]{'B-LBA-EST-LOADING','http://www.w3.org/2001/XMLSchema','decimal','0','1','false'};
        private String[] B_LBA_EST_UPFRONT_type_info = new String[]{'B-LBA-EST-UPFRONT','http://www.w3.org/2001/XMLSchema','decimal','0','1','false'};
        private String[] B_LBA_EST_CURRBAL_type_info = new String[]{'B-LBA-EST-CURRBAL','http://www.w3.org/2001/XMLSchema','decimal','0','1','false'};
        private String[] B_LBA_EST_TOTAL_type_info = new String[]{'B-LBA-EST-TOTAL','http://www.w3.org/2001/XMLSchema','decimal','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','true','false'};
        private String[] field_order_type_info = new String[]{'B_LBA_EST_WEEK','B_LBA_EST_FNT','B_LBA_EST_MTH','B_LBA_EST12MTHSBILLS','B_LBA_EST_CON_ALLOW','B_LBA_EST_LOADING','B_LBA_EST_UPFRONT','B_LBA_EST_CURRBAL','B_LBA_EST_TOTAL'};
    }
    public class validatePaymentPlanResponse_element {
        public TibcoPaymentPlan_MessageTypes.Header_element Header;
        public TibcoPaymentPlan_MessageTypes.ProcessOutputData_element ProcessOutputData;
        private String[] Header_type_info = new String[]{'Header','http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','Header_element','1','1','false'};
        private String[] ProcessOutputData_type_info = new String[]{'ProcessOutputData','http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','ProcessOutputData_element','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','true','false'};
        private String[] field_order_type_info = new String[]{'Header','ProcessOutputData'};
    }
    public class doPaymentPlanResponse_element {
        public TibcoPaymentPlan_MessageTypes.Header_element Header;
        private String[] Header_type_info = new String[]{'Header','http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','Header_element','1','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','true','false'};
        private String[] field_order_type_info = new String[]{'Header'};
    }
    public class DoPaymentPlanInputData_element {
        public String CustomerNumber;
        public String PropertyReference;
        public String UserId;
        public Decimal B_LBA_UpfrontPaymt;
        public Date B_LBA_UPFRONTPDATE;
        public Boolean B_LBA_EST_12MTH;
        public Boolean B_LBA_EST_6MTH;
        public Boolean B_LBA_EST_24MTH;
        public String B_O_LBA_PMTFREQ;
        public Decimal B_LBA_BudgetPaymtAmt;
        public Date B_LBA_FirstpaymtDate;
        public Integer B_LBA_noofpayments;
        public Date B_O_FIRSTDATE;
        public Date B_O_SECONDDATE;
        public Date B_O_LASTDATE;
        public Decimal B_O_FIRSTVALUE;
        public Decimal B_O_SECONDVALUE;
        public Decimal B_O_LASTVALUE;
        public Decimal B_O_OTHERVALUE;
        public String B_O_LBA_STUBFREQ;
        public String B_O_PAYMENTOPTIONS;
        private String[] CustomerNumber_type_info = new String[]{'CustomerNumber','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] PropertyReference_type_info = new String[]{'PropertyReference','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
        private String[] UserId_type_info = new String[]{'UserId','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
        private String[] B_LBA_UpfrontPaymt_type_info = new String[]{'B-LBA-UpfrontPaymt','http://www.w3.org/2001/XMLSchema','decimal','0','1','false'};
        private String[] B_LBA_UPFRONTPDATE_type_info = new String[]{'B-LBA-UPFRONTPDATE','http://www.w3.org/2001/XMLSchema','date','0','1','false'};
        private String[] B_LBA_EST_12MTH_type_info = new String[]{'B-LBA-EST-12MTH','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] B_LBA_EST_6MTH_type_info = new String[]{'B-LBA-EST-6MTH','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] B_LBA_EST_24MTH_type_info = new String[]{'B-LBA-EST-24MTH','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] B_O_LBA_PMTFREQ_type_info = new String[]{'B-O-LBA-PMTFREQ','http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','B-O-LBA-PMTFREQ_element','0','1','false'};
        private String[] B_LBA_BudgetPaymtAmt_type_info = new String[]{'B-LBA-BudgetPaymtAmt','http://www.w3.org/2001/XMLSchema','decimal','0','1','false'};
        private String[] B_LBA_FirstpaymtDate_type_info = new String[]{'B-LBA-FirstpaymtDate','http://www.w3.org/2001/XMLSchema','date','0','1','false'};
        private String[] B_LBA_noofpayments_type_info = new String[]{'B-LBA-noofpayments','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] B_O_FIRSTDATE_type_info = new String[]{'B-O-FIRSTDATE','http://www.w3.org/2001/XMLSchema','date','0','1','false'};
        private String[] B_O_SECONDDATE_type_info = new String[]{'B-O-SECONDDATE','http://www.w3.org/2001/XMLSchema','date','0','1','false'};
        private String[] B_O_LASTDATE_type_info = new String[]{'B-O-LASTDATE','http://www.w3.org/2001/XMLSchema','date','0','1','false'};
        private String[] B_O_FIRSTVALUE_type_info = new String[]{'B-O-FIRSTVALUE','http://www.w3.org/2001/XMLSchema','decimal','0','1','false'};
        private String[] B_O_SECONDVALUE_type_info = new String[]{'B-O-SECONDVALUE','http://www.w3.org/2001/XMLSchema','decimal','0','1','false'};
        private String[] B_O_LASTVALUE_type_info = new String[]{'B-O-LASTVALUE','http://www.w3.org/2001/XMLSchema','decimal','0','1','false'};
        private String[] B_O_OTHERVALUE_type_info = new String[]{'B-O-OTHERVALUE','http://www.w3.org/2001/XMLSchema','decimal','0','1','false'};
        private String[] B_O_LBA_STUBFREQ_type_info = new String[]{'B-O-LBA-STUBFREQ','http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','B-O-LBA-STUBFREQ_element','0','1','false'};
        private String[] B_O_PAYMENTOPTIONS_type_info = new String[]{'B-O-PAYMENTOPTIONS','http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','B-O-PAYMENTOPTIONS_element','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','true','false'};
        private String[] field_order_type_info = new String[]{'CustomerNumber','PropertyReference','UserId','B_LBA_UpfrontPaymt','B_LBA_UPFRONTPDATE','B_LBA_EST_12MTH','B_LBA_EST_6MTH','B_LBA_EST_24MTH','B_O_LBA_PMTFREQ','B_LBA_BudgetPaymtAmt','B_LBA_FirstpaymtDate','B_LBA_noofpayments','B_O_FIRSTDATE','B_O_SECONDDATE','B_O_LASTDATE','B_O_FIRSTVALUE','B_O_SECONDVALUE','B_O_LASTVALUE','B_O_OTHERVALUE','B_O_LBA_STUBFREQ','B_O_PAYMENTOPTIONS'};
    }
    public class ErrorStatus_element {
        public String ErrorCode;
        public String ErrorSeverity;
        public String ErrorDescription;
        private String[] ErrorCode_type_info = new String[]{'ErrorCode','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] ErrorSeverity_type_info = new String[]{'ErrorSeverity','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] ErrorDescription_type_info = new String[]{'ErrorDescription','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','true','false'};
        private String[] field_order_type_info = new String[]{'ErrorCode','ErrorSeverity','ErrorDescription'};
    }
    public class deleteBudgetResponse_element {
        public TibcoPaymentPlan_MessageTypes.Header_element Header;
        private String[] Header_type_info = new String[]{'Header','http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','Header_element','1','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','true','false'};
        private String[] field_order_type_info = new String[]{'Header'};
    }
    public class deleteBudgetRequest_element {
        public TibcoPaymentPlan_MessageTypes.Header_element Header;
        public String CustomerNumber;
        public String B_O_LetterType;
        public String B_O_RecovPath;
        private String[] Header_type_info = new String[]{'Header','http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','Header_element','1','1','false'};
        private String[] CustomerNumber_type_info = new String[]{'CustomerNumber','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] B_O_LetterType_type_info = new String[]{'B-O-LetterType','http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','B-O-LetterType_element','0','1','false'};
        private String[] B_O_RecovPath_type_info = new String[]{'B-O-RecovPath','http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','B-O-RecovPath_element','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','true','false'};
        private String[] field_order_type_info = new String[]{'Header','CustomerNumber','B_O_LetterType','B_O_RecovPath'};
    }
    public class doPaymentPlanRequest_element {
        public TibcoPaymentPlan_MessageTypes.Header_element Header;
        public TibcoPaymentPlan_MessageTypes.DoPaymentPlanInputData_element DoPaymentPlanInputData;
        private String[] Header_type_info = new String[]{'Header','http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','Header_element','1','1','false'};
        private String[] DoPaymentPlanInputData_type_info = new String[]{'DoPaymentPlanInputData','http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','DoPaymentPlanInputData_element','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','true','false'};
        private String[] field_order_type_info = new String[]{'Header','DoPaymentPlanInputData'};
    }
    public class MessageResponseStatus_element {
        public String MessageSuccessInd;
        public String ResponseUniqueID;
        public TibcoPaymentPlan_MessageTypes.ErrorStatus_element[] ErrorStatus;
        private String[] MessageSuccessInd_type_info = new String[]{'MessageSuccessInd','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] ResponseUniqueID_type_info = new String[]{'ResponseUniqueID','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
        private String[] ErrorStatus_type_info = new String[]{'ErrorStatus','http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','ErrorStatus_element','0','-1','false'};
        private String[] apex_schema_type_info = new String[]{'http://www.sewl.com.au/esb/schemas/salesforce/paymentplans','true','false'};
        private String[] field_order_type_info = new String[]{'MessageSuccessInd','ResponseUniqueID','ErrorStatus'};
    }
}