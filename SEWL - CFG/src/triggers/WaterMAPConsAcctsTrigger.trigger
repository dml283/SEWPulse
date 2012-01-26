trigger WaterMAPConsAcctsTrigger on WaterMAP_Consolidated_Accounts__c (after delete, after insert) {

    /**************************************************************************/
    /*  Description:
    /*      (1) Denorms the watermap id to billing account on insert and delete
    /*
    /*  Change History:
    /*      D.Thong     23-May-2011     Created
    /**************************************************************************/


    if (trigger.isAfter) {

        Map <Id, Id> bAcctIdToWMapId = new Map <Id, Id>();

        if (trigger.isDelete) {
            for (WaterMAP_Consolidated_Accounts__c cons : trigger.old) {
                bAcctIdToWMapId.put(cons.Billing_Account__c, null);
            }
        }

        if (trigger.isInsert) {
            for (WaterMAP_Consolidated_Accounts__c cons : trigger.new) {
                bAcctIdToWMapId.put(cons.Billing_Account__c, cons.WaterMap__c);
            }
        }

        if (!bAcctIdToWMapId.isEmpty()) WaterMAPUtil.UpdateBAcctWMAPIds(bAcctIdToWMapId);

    }

}