//Generated by wsdl2apex

public class TestoPaymentPlan_Service {
    public class PaymentPlansEndpoint {
        public String endpoint_x = 'http://localhost:18151/PaymentPlans/ServiceAdapter/PaymentPlans_ServiceConsumer.serviceagent/PaymentPlansEndpoint';
        public Map<String,String> inputHttpHeaders_x;
        public Map<String,String> outputHttpHeaders_x;
        public String clientCertName_x;
        public String clientCert_x;
        public String clientCertPasswd_x;
        public Integer timeout_x;
        private String[] ns_map_type_info = new String[]{'http://www.sewl.com.au/esb/schemas/salesforce/paymentplans', 'TestoPaymentPlan_MessageTypes', 'http://www.sewl.com.au/salesforce/paymentplans/ReqRes', 'TestoPaymentPlan_Service'};
        public TestoPaymentPlan_MessageTypes.Header_element deleteBudget(TestoPaymentPlan_MessageTypes.Header_element Header,String CustomerNumber,String B_O_LetterType,String B_O_RecovPath) {
            TestoPaymentPlan_MessageTypes.deleteBudgetRequest_element request_x = new TestoPaymentPlan_MessageTypes.deleteBudgetRequest_element();
            TestoPaymentPlan_MessageTypes.deleteBudgetResponse_element response_x;
            request_x.Header = Header;
            request_x.CustomerNumber = CustomerNumber;
            request_x.B_O_LetterType = B_O_LetterType;
            request_x.B_O_RecovPath = B_O_RecovPath;
            Map<String, TestoPaymentPlan_MessageTypes.deleteBudgetResponse_element> response_map_x = new Map<String, TestoPaymentPlan_MessageTypes.deleteBudgetResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              'deleteBudget',
              'http://www.sewl.com.au/esb/schemas/salesforce/paymentplans',
              'deleteBudgetRequest',
              'http://www.sewl.com.au/esb/schemas/salesforce/paymentplans',
              'deleteBudgetResponse',
              'TestoPaymentPlan_MessageTypes.deleteBudgetResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.Header;
        }
        public TestoPaymentPlan_MessageTypes.Header_element doPaymentPlans(TestoPaymentPlan_MessageTypes.Header_element Header,TestoPaymentPlan_MessageTypes.DoPaymentPlanInputData_element DoPaymentPlanInputData) {
            TestoPaymentPlan_MessageTypes.doPaymentPlanRequest_element request_x = new TestoPaymentPlan_MessageTypes.doPaymentPlanRequest_element();
            TestoPaymentPlan_MessageTypes.doPaymentPlanResponse_element response_x;
            request_x.Header = Header;
            request_x.DoPaymentPlanInputData = DoPaymentPlanInputData;
            Map<String, TestoPaymentPlan_MessageTypes.doPaymentPlanResponse_element> response_map_x = new Map<String, TestoPaymentPlan_MessageTypes.doPaymentPlanResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              'doPaymentPlans',
              'http://www.sewl.com.au/esb/schemas/salesforce/paymentplans',
              'doPaymentPlanRequest',
              'http://www.sewl.com.au/esb/schemas/salesforce/paymentplans',
              'doPaymentPlanResponse',
              'TestoPaymentPlan_MessageTypes.doPaymentPlanResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.Header;
        }
        public TestoPaymentPlan_MessageTypes.validatePaymentPlanResponse_element validatePaymentPlans(TestoPaymentPlan_MessageTypes.Header_element Header,TestoPaymentPlan_MessageTypes.ProcessInputData_element ProcessInputData) {
            TestoPaymentPlan_MessageTypes.validatePaymentPlanRequest_element request_x = new TestoPaymentPlan_MessageTypes.validatePaymentPlanRequest_element();
            TestoPaymentPlan_MessageTypes.validatePaymentPlanResponse_element response_x;
            request_x.Header = Header;
            request_x.ProcessInputData = ProcessInputData;
            Map<String, TestoPaymentPlan_MessageTypes.validatePaymentPlanResponse_element> response_map_x = new Map<String, TestoPaymentPlan_MessageTypes.validatePaymentPlanResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              'validatePaymentPlans',
              'http://www.sewl.com.au/esb/schemas/salesforce/paymentplans',
              'validatePaymentPlanRequest',
              'http://www.sewl.com.au/esb/schemas/salesforce/paymentplans',
              'validatePaymentPlanResponse',
              'TestoPaymentPlan_MessageTypes.validatePaymentPlanResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x;
        }
    }
}