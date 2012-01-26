public without sharing class WaterMAPHistoryController {
/*
    Type:       Controller
    Purpose:    Controller to display the list of historical Watermaps

    Used By:    WaterMAPHistoryPage VF Page
    ---------------------------------------------------------------
    History:

    13-Jun-2011 D.Thong (Salesforce)    Created

*/

    /* PUBLIC PROPERTIES */
    // list of history records
    public List<WMAPHistory> wmapHistoryRecords {
        get {
            // Our return list
            List<WMAPHistory> wmapHistoryRecords = new List<WMAPHistory>();

            // assume that the user is always there!
            User user = [Select ContactId, AccountId
                        From  User
                        Where Id = :UserInfo.getUserId() LIMIT 1];

            // retrieve the historical watermap records
            List <WaterMAP_Submission__c> wmapSubs =
                            [Select Year__c, WaterMAP__r.Billing_Account__r.HiAF_Account_Number_Check_Digit__c,
                                    Site_Address__c,
                                    (Select Id, Name From Attachments
                                            Where Name In ('WaterMAP.pdf', 'Review.pdf'))
                                From WaterMAP_Submission__c
                                Where Customer__c = :user.AccountId
                                And   Status__c = 'Review Completed'
                                Order by Year__c, WaterMAP__r.Billing_Account__r.HiAF_Account_Number_Check_Digit__c];

            for (WaterMAP_Submission__c wmsub : wmapSubs) {
                Attachment wMapAtt;
                Attachment ReviewAtt;

                for (Attachment a : wmsub.Attachments) {
                    if (a.Name == 'WaterMAP.pdf')
                        wMapAtt = a;
                    else
                        ReviewAtt = a;
                }
                wmapHistoryRecords.add(new WMAPHistory(wmsub.Year__c,
                                                        wmsub.WaterMAP__r.Billing_Account__r.HiAF_Account_Number_Check_Digit__c,
                                                        wmsub.Site_Address__c,
                                                        wMapAtt, ReviewAtt));
            }

            return wmapHistoryRecords;
        }
    }

    // count of history records
    public integer wmapHistoryRecordsCount {
        get { return wmapHistoryRecords.size(); }
    }

    /* CONSTRUCTOR */
    public WaterMAPHistoryController() {}

    /* PUBLIC CLASSES */
    // wraps historical watermaps
    public class WMAPHistory {
        public String year {get; set;}
        public String siteAddress {get; set;}
        public String customerNbr {get; set;}
        public Attachment waterMAP {get; set;}
        public Attachment review {get; set;}

        public WMAPHistory(String year, String customerNbr, String siteAddress,
                                Attachment waterMAP, Attachment review) {
            this.year = year;
            this.waterMAP = waterMAP;
            this.review = review;
            this.siteAddress = siteAddress;
            this.customerNbr = customerNbr;
        }
    }

    /* TESTERS */
    private static testmethod void TestMe() {
        // create test data
        Account account = new Account();
        account.name = 'foo';
        insert account;

        Contact contact = new Contact();
        contact.LastName = 'Foo';
        contact.AccountId = account.id;
        contact.Title = 'x';
        contact.Phone = 'x';
        contact.Email = 'x@x.com';
        insert contact;

        Profile p = [select id from profile where name = 'SEW WaterMAP Portal User'];

        String testemail = 'puser000@amamama.com';
        User pu = new User(profileId = p.id, username = testemail, email = testemail,
                           emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                           languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                           alias='cspu', lastname='lastname', contactId = contact.id);

        insert pu;

        Property__c prop = new Property__c();
        prop.Universal_Id_c__c = 'sdgfsdgf';
        prop.Name = 'Test Property';
        insert prop;

        Billing_Account__c billAcc = new Billing_Account__c();
        billAcc.Name = 'asetwetwrt';
        billAcc.Customer__c = account.id;
        billAcc.Property__c = prop.id;
        insert billAcc;

        Watermap__c waterMap = new Watermap__c();
        waterMap.Name = 'Test Me';
        waterMap.Customer__c = account.id;
        waterMap.Status__c = 'Not Started';
        waterMap.Billing_Account__c = billAcc.id;
        waterMAP.KBAI_Type__c = 'Average';
        waterMAP.KBAI_Description__c = 'Widget';
        insert waterMap;

        WaterMAP_Submission__c waterMapSub = new WaterMAP_Submission__c();
        waterMapSub.Customer__c = account.id;
        waterMapSub.Prepared_By__c = contact.id;
        waterMapSub.Prepared_By__r = contact;
        waterMapSub.Authorised_By__c = contact.id;
        waterMapSub.Authorised_By__r = contact;
        waterMapSub.Status__c = 'Review Completed';
        waterMapSub.Watermap__c = waterMap.id;
        waterMapSub.Watermap__r = waterMap;
        waterMapSub.Year__c = '2011/12';
        insert waterMapSub;

        Attachment attachment = new Attachment();
        attachment.ParentId = waterMapSub.id;
        attachment.Description = 'WaterMAP';
        attachment.Body = Blob.valueOf('xyz');
        attachment.Name = 'WaterMAP.pdf';
        insert attachment;

        Attachment attachment2 = new Attachment();
        attachment2.ParentId = waterMapSub.id;
        attachment2.Description = 'Review';
        attachment2.Name = 'Review.pdf';
        attachment2.Body = Blob.valueOf('xyz');
        insert attachment2;

        System.runAs(pu) {

            System.debug([Select ContactId, AccountId
                        From  User
                        Where Id = :UserInfo.getUserId() LIMIT 1]);

            WaterMAPHistoryController controller = new WaterMAPHistoryController();
            System.assertEquals(1, controller.wmapHistoryRecordsCount);
            System.debug(controller.wmapHistoryrecords);
            System.assertEquals(attachment.id, controller.wmapHistoryRecords[0].waterMAP.id);
        }
    }

}