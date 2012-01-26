trigger WaterMAP on WaterMAP__c (after insert, after update) {

    /**************************************************************************/
    /*  Description:
    /*      (1) Denorms the billing account to the consolidated WMAP a/c
    /*          as the primary
    /*      (2) Copies the primary, secondary and site manager as roles of the customer
    /*      (3) If active, create a new watermap if no current one exists
    /*      (4) If inactivated, cancel all in progress watermaps
    /*
    /*  Change History:
    /*      D.Thong     12-May-2011     Created
    /**************************************************************************/

    if (trigger.isAfter) {

        List <Id> changedBAcctWMAPIds = new List <Id>();
        Set <Id> changedContactsAcctIds = new Set<Id>();
        Map <Id, Id> bAcctIdToWMapId = new Map <Id, Id>();
        List <Id> activeWMAPIds = new List<Id>();
        List <Id> inactiveWMAPIds = new List<Id>();

        if (trigger.isInsert || trigger.isUpdate) {
            for (WaterMap__c wmap : trigger.new) {

                if (trigger.isInsert) {
                    if (wmap.Billing_Account__c != null) {
                        // qualifies to be denormed as the primary consolidated acct
                        changedBAcctWMAPIds.add(wmap.id);
                        bAcctIdToWMapId.put(wmap.Billing_Account__c, wmap.id);
                    }

                    // contact details have been added, denorm to account role
                    if (wmap.Primary_Contact__c != null || wmap.Secondary_Contact__c != null ||
                                wmap.Site_Manager__c != null)
                        changedContactsAcctIds.add(wmap.Customer__c);

                    // watermap is now active
                    if (wmap.Status__c == 'Active') activeWMAPIds.add(wmap.id);

                    if (wmap.Status__c == 'Inactive') inactiveWMAPIds.add(wmap.id);

                }
                if (trigger.isUpdate)  {
                    Id oldBAcctId = trigger.oldMap.get(wmap.id).Billing_Account__c;

                    if (wmap.Billing_Account__c != oldBAcctId) {
                        // qualifies to be denormed as the primary consolidated acct
                        changedBAcctWMAPIds.add(wmap.id);

                        if (wmap.Billing_Account__c != null) bAcctIdToWMapId.put(wmap.Billing_Account__c, wmap.id);

                        if (oldBAcctId != null) bAcctIdToWMapId.put(oldBAcctId, null);
                    }

                    // contact details have changed, denorm to account role
                    if (wmap.Primary_Contact__c != trigger.oldMap.get(wmap.id).Primary_Contact__c ||
                                wmap.Secondary_Contact__c != trigger.oldMap.get(wmap.id).Secondary_Contact__c ||
                                wmap.Site_Manager__c != trigger.oldMap.get(wmap.id).Site_Manager__c) {
                        changedContactsAcctIds.add(wmap.Customer__c);
                    }

                    // watermap is changed to active
                    if (wmap.Status__c == 'Active' && trigger.oldmap.get(wmap.id).Status__c != 'Active')
                        activeWMAPIds.add(wmap.id);

                    // watermap is changed to inactive
                    if (wmap.Status__c == 'Inactive' && trigger.oldmap.get(wmap.id).Status__c != 'Inactive')
                        inactiveWMAPIds.add(wmap.id);

                }
            }
        }

        if (!changedBAcctWMAPIds.isEmpty()) WaterMAPUtil.DenormPrimaryConsolidatedAcct(changedBAcctWMAPIds);

        if (!changedContactsAcctIds.isEmpty()) WaterMAPUtil.UpdateContactRoles(changedContactsAcctIds);

        if (!activeWMAPIds.isEmpty()) WaterMAPUtil.ActivateWaterMAPs(activeWMAPIds);

        if (!inactiveWMAPIds.isEmpty()) WaterMAPUtil.InactivateWaterMAPs(inactiveWMAPIds);

    }
}