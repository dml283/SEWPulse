trigger WaterMAP_Submission on WaterMAP_Submission__c (before insert, before update, after update) {

    /**************************************************************************/
    /*  Description:
    /*      (1) Denorms Customer__c from WaterMAP__c.Customer__c;
    /*      (2) Creates a new submission on completion or not required and rollover
    /*          the forecast % to prior %
    /*  Change History:
    /*      D.Thong     12-May-2011     Created
    /**************************************************************************/

    /* BEFORE INSERT BEFORE UPDATE */
    if (trigger.isBefore) {
        if (trigger.isInsert || trigger.isUpdate) {
            // (1) Denorms Customer__c from WaterMAP__c.Customer__c;
            for (WaterMAP_Submission__c sub : trigger.new) {
                sub.Customer__c = sub.WaterMAP_Customer_Id__c;
            }
        }
    }

    /* AFTER UPDATE */
    if (trigger.isAfter) {
        if (trigger.isUpdate) {
            // (1) if watermap becomes approved - generate pdf
            // REMOVED
            /*List<Id> newSubsChangedToApprovedIds = new List<Id>();

            for(WaterMAP_Submission__c newSub : trigger.new) {
                if('Approved by SEW'.equals(newSub.Status__c) && !newSub.Is_waterMAP_PDF_Generated__c){
                    if(!'Approved by SEW'.equals((Trigger.oldMap.get(newSub.id)).Status__c)){
                        newSubsChangedToApprovedIds.add(newSub.id);
                    }
                }
            }*/

            //if (!newSubsChangedToApprovedIds.isEmpty()) {
                // execute a batch with scope of 1 to create the PDF
                //WaterMAP_CreatePDF_Batch pdfBatch = new WaterMAP_CreatePDF_Batch();
                //pdfBatch.wmapSubIds = newSubsChangedToApprovedIds;
                //Database.executeBatch(pdfBatch, 1);
            //}

            // (2) creates a new watermap submission if review completed or not required
            List <Id> createNextYearSubIds = new List <Id> ();

            for (WaterMAP_Submission__c sub : trigger.new) {
                if (sub.Active__c == 'N' && !sub.Rolled_Over_Flag__c)
                    createNextYearSubIds.add(sub.id);
            }

            if (!createNextYearSubIds.isEmpty())
                WaterMAPUtil.CreateNextYearsSubmissions(createNextYearSubIds);
        }
    }
}