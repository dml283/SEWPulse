trigger LiveLinkTrigger on Livelink__c (before insert) {

/*
    Type:       Trigger
    Purpose:    (i)     Defaults customer and property from billing account if not supplied

    ---------------------------------------------------------------
    History:
        27-Sep-2011 - D.Thong (SFDC)    Created
*/

	List<Livelink__c> liveLinkRecordsToDefault = new List<Livelink__c> ();

	if (trigger.isBefore && trigger.isInsert) {
		for (Livelink__c ll : trigger.new) {
			if (ll.Billing_Account__c != null &&
					(ll.Customer__c == null || ll.Property__c == null)) {
				liveLinkRecordsToDefault.add(ll);
			}
		}
	}

	if (!liveLinkRecordsToDefault.isEmpty()) LiveLink.DefaultFieldsFromBAcct(liveLinkRecordsToDefault);

}