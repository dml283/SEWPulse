public without sharing class WaterMAP_View_Extension {
/*
    Type:       Controller Extension
    Purpose:    Controller to display the WMAP Submission
                and to approve watermaps. The latter will archive
                the submission in PDF format as WaterMAP.pdf.

    Used By:    WaterMAP_View VF Page
                WaterMAP_Approve VF Page
    ---------------------------------------------------------------
    History:

    16-Jun-2011 D Thong Created

*/

    /* PUBLIC GETTERS/SETTERS */
    public WaterMAP_Submission__c waterMAPSub {get; set;}
    public String approvedStr {get;set;}
    public String APPROVAL_YES {get{return 'Yes';}}
    public String APPROVAL_NO {get{return 'No';}}

    public String DEFAULT_EMAIL_MSG_YES{
        get{
            if (DEFAULT_EMAIL_MSG_YES == null){
                DEFAULT_EMAIL_MSG_YES = 'Your Key Customer Manager has reviewed your WaterMAP, entitling you to apply for potential funding assistance proposals outlined in your WaterMAP proposal.';
            }return DEFAULT_EMAIL_MSG_YES;
        }set;
    }

    public String DEFAULT_EMAIL_MSG_NO{
        get{
            if (DEFAULT_EMAIL_MSG_NO == null){
                DEFAULT_EMAIL_MSG_NO = 'Your Key Customer Manager still requires further information for the satisfactory completion of your WaterMAP and/or potential funding assistance:';
            }return DEFAULT_EMAIL_MSG_NO;
        }set;
    }

    /* CONSTANTS */
    private static final String ATTACHMENT_CONTENTTYPE_PDF = 'application/pdf';


    /* CONSTRUCTORS */
    public WaterMAP_View_Extension(ApexPages.StandardController controller) {
        waterMapSub = (WaterMAP_Submission__c) controller.getRecord();
    }

    /* PUBLIC METHODS */
    public void updateDefaultEmailWordings(){
        if( APPROVAL_YES.equals(approvedStr)){
            waterMapSub.HIDDEN_Approval_Email_Message__c = DEFAULT_EMAIL_MSG_YES+'\n';
        }else if ( APPROVAL_NO.equals(approvedStr)){
            waterMapSub.HIDDEN_Approval_Email_Message__c = DEFAULT_EMAIL_MSG_NO+'\n';
        }
    }
    public PageReference Preview() {
        try {
            Id attachId;
            attachId = WaterMAPAttachment.upsertVfAttachment(Page.WaterMAP_PDF, waterMAPSub.Id, 'WaterMAP_Preview.pdf');
            PageReference pdfPage = new PageReference('/servlet/servlet.FileDownload?file=' + attachId);
            pdfPage.setRedirect(true);
            return pdfPage;

        } catch (Exception e){
            ApexPages.addMessages(e);
        }
        return null;
    }

    // Approves the watermap submission
    // and creates a new archive of it
    public PageReference Approve() {
        if (waterMAPSub.Status__c == 'Submitted for Approval') {
            if( APPROVAL_YES.equals(approvedStr)){
                waterMAPSub.Status__c = 'Approved by SEW';
                waterMAPSub.Approvable__c = true;
            }else if ( APPROVAL_NO.equals(approvedStr)){
                waterMAPSub.Status__c = 'In Progress';
            }
        }
        try {
            if( APPROVAL_YES.equals(approvedStr)){
                WaterMAPAttachment.upsertVfAttachment(Page.WaterMAP_PDF, waterMAPSub.Id, 'WaterMAP.pdf');
            }
            update waterMAPSub;
        } catch (Exception e) {
            ApexPages.addMessages(e);
            return null;
        }
        return new PageReference('/' + waterMAPSub.id);
    }

    private static testmethod void testme () {

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

        Watermap__c waterMap = new Watermap__c();
        waterMap.Name = 'Test Me';
        waterMap.Customer__c = account.id;
        waterMap.Status__c = 'Not Started';
        insert waterMap;

        WaterMAP_Submission__c waterMapSub = new WaterMAP_Submission__c();
        waterMapSub.Customer__c = account.id;
        waterMapSub.Prepared_By__c = contact.id;
        waterMapSub.Prepared_By__r = contact;
        waterMapSub.Authorised_By__c = contact.id;
        waterMapSub.Authorised_By__r = contact;
        waterMapSub.Status__c = 'In Progress';
        waterMapSub.Watermap__c = waterMap.id;
        insert waterMapSub;

        PageReference pageRef = Page.WaterMAP_View;
        ApexPages.StandardController sc = new ApexPages.StandardController(waterMapSub);
        Test.setCurrentPage(pageRef);
        WaterMAP_View_Extension controller = new WaterMAP_View_Extension (sc);
        controller.Preview();

        List<Attachment> attachments = [Select id, Body, Name, IsPrivate, ParentId
                                            from Attachment
                                            where ParentId = :waterMapSub.id and Name = 'WaterMAP_Preview.pdf'];

        System.assertequals(1,attachments.size());

        waterMapSub.Status__c = 'Submitted for Approval';
        controller.approvedStr = controller.APPROVAL_YES;
        controller.updateDefaultEmailWordings();
        controller.Approve();
        System.assertequals('Approved by SEW', [select status__c from watermap_submission__c where id = :waterMapSub.id LIMIT 1][0].status__c);
        waterMapSub.Status__c = 'Submitted for Approval';
        controller.approvedStr = controller.APPROVAL_NO;
        controller.updateDefaultEmailWordings();
        controller.Approve();
        System.assertequals('In Progress', [select status__c from watermap_submission__c where id = :waterMapSub.id LIMIT 1][0].status__c);



    }

}