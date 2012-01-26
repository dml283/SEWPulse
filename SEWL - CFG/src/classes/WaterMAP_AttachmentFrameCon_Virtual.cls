public without sharing virtual class WaterMAP_AttachmentFrameCon_Virtual {
/*
    Type:       Virtual Controller Extension
    Purpose:    queries, updates and deletes attachments based on the
                description. Includes abstract method for validation

    Used By:    WaterMAP_Pg0_CompanyLogoFrameController
                WaterMAP_Pg3_MajorWaterAreaFrameCon
    ---------------------------------------------------------------
    History:

    23-Jun-2011 D.Thong (Salesforce)    Created

*/
    /* PUBLIC PROPERTIES */
    public WaterMAP_Submission__c waterMapSub {get; set;}

    // existing attachment is kept separate
    public Attachment attachment {get; set;}
    public Attachment existingAttachment {get; set;}

    /* PRIVATE PROPERTIES */
    // overriden in the specific class
    protected String attachmentDescription {get; set;}

    /* CONSTRUCTOR */
    // constructor is passed in the description of the attachment
    public WaterMAP_AttachmentFrameCon_Virtual(ApexPages.StandardController controller, String attachmentDescription) {
        waterMapSub = (WaterMAP_Submission__c) controller.getRecord();
        this.attachmentDescription = attachmentDescription;
        queryAttachment();
        attachment = new Attachment();
    }

    /* PUBLIC METHODS */
    // uploads the attachment
    public virtual PageReference UploadAttachment() {

        // first validate the sucker to make sure its there and a valid attachment
        if (attachment.Name == null ) {
            apexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'No document selected.');
            apexPages.addMessage(msg);
            attachment.body = null; // avoids view state issues
            return null;
        }

        attachment.ParentId = waterMapSub.waterMap__c;
        attachment.Description = attachmentDescription;

        try {

            // insert and delete the attachment
            insert attachment;

            if (existingAttachment != null)
                delete existingAttachment;

            queryAttachment();

        } catch (Exception e) {
            ApexPages.addMessages(e);
        } finally {

            attachment.body = null; // avoids view state issues
            attachment = new Attachment();
        }
        return null;
    }

    // deletes the attachment
    public PageReference DeleteAttachment() {
        if (existingAttachment != null) {
            delete existingAttachment;
            existingAttachment = null;
        }
        return null;
    }

    /* PRIVATE METHODS */
    // retrieves the attachment based on the description
    private void queryAttachment() {
        List<Attachment> attachments = [select id, name, description from Attachment
                                    where ParentId=:waterMapSub.waterMap__c
                                    and   Description=:attachmentDescription
                                    order by lastmodifieddate desc
                                    LIMIT 1];

        if (!attachments.isEmpty())
            this.existingAttachment = attachments[0];
    }

}