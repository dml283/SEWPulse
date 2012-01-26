/*
Type: Controller class for RunBatchProcess VF Page
Purpose: Execute batch job and navigate to Apex jobs page
History:
Date            Author                  Changes
----            ------                  -------  
09-Aug-2011     D Enojas(Salesforce)    Created
*/

public class RunBatchProcessController {

    public static PageReference consumptionCurrentYrFlagExecute() {
        database.ExecuteBatch(new ConsumptionSetCurrentYrFlagBatch());
        return getListAsyncApexJobPageRef();
    }
    
    public static PageReference refreshCustomerSegmentExecute() {
        database.ExecuteBatch(new RefreshCustomerSegment_BATCH());
        return getListAsyncApexJobPageRef();
    }
    public static PageReference copyGroupBillingAddressExecute() {
        new CopyGroupBillingAddressScheduler().execute(null);
        return getListAsyncApexJobPageRef();
    }
    
    private static PageReference getListAsyncApexJobPageRef(){
        PageReference pageRef = new PageReference('/apexpages/setup/listAsyncApexJobs.apexp');
        pageRef.setredirect(true);
        return pageRef;
    }
    
    //test
    static testMethod void testBatch() {
        RunBatchProcessController.consumptionCurrentYrFlagExecute();
        RunBatchProcessController.refreshCustomerSegmentExecute();
        RunBatchProcessController.copyGroupBillingAddressExecute();
    }
}