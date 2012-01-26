public with sharing class CustomerSegmentEntryController {

    /*
        Type:       Controller Extension
        Purpose:    Segment Questionaire controller
    
        Used By:    Segments
        ---------------------------------------------------------------
        History:
    
        9-Nov-2011 D.Thong          Created
        8-Dec-2011 M.Watson         Added age bracket check, bulkified methods 
                                                    (and move them to SegmentUtil class)
    
    */

    /* Public Properties */
    // List of questions and answers
    public List<QuestionAndAnswer> questionAndAnswers {
        get {
            if (questionAndAnswers == null)
                PopulateQuestionAndAnswers();
                return questionAndAnswers;
            }
        private set;
    }

    // Customer Type
    public String customerType {
        get {
            if(customer.RecordType != null) {
                if (customer.RecordType.DeveloperName.startsWith('Residential')) {
                        customerType = 'Residential';
                }
                else customerType = 'Business';
            }
            return customerType;
        }
        private set;
    }
        
    /* Private Properties */
    private Account customer{
        get{
            return (Account) stdCon.getRecord();
        }
    }

    private ApexPages.StandardController stdCon;

    /* Controller */
    public CustomerSegmentEntryController(ApexPages.StandardController controller) {
        // add the dynamic fields
        stdCon = controller;    
                                
        // add the dynamic fields to the controller
        Set <String> fieldSet = new Set<String>();
        
        for (Question__c q : [select api_field__c, type__c 
                                    from question__c 
                                    where active__c = true and api_field__c != null]) {
            fieldSet.add(q.api_field__c);
        }
        List <String> fieldList = new List<String>();
        fieldList.addAll(fieldSet);
                
        if (!Test.isRunningTest() && fieldList.size() > 0)
                        controller.addFields(fieldList);
                        
        // Populate the usage quartile
        SegmentUtil.PopulateUsageQuartiles(new Account[]{customer});

        // Populate the primary person/contact age bracket, for residential customers
        SegmentUtil.PopulateAgeBrackets(new Account[]{customer});
    }
        
    /* Public Methods */
    public PageReference Save() {

        SegmentationAllocator alloc = new SegmentationAllocator();
        alloc.Allocate(customer);
                
        // populate segment__r and update timestamps
        if (customer.segment__c != null) {
            customer.segment__r = [select profile__c, offer__c, background_colour__c, text_colour__c, name,
                                            Image__c, Segment_Name_Image_URL__c 
                                            from segment__c
                                            where id = :customer.segment__c];
            customer.Segment_Profile_Last_Updated__c = system.now();
            customer.Segment_Profile_Next_Review_Date__c = system.today().addDays(SegmentationAllocator.NEXT_REVIEW_OFFSET_DAYS);
        }
                        
        try {
            update customer;
        } catch (Exception e) {
            ApexPages.addMessages(e);
        }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
                                        'Save Successful'));

        return null;
    }
        
    /* Private Methods */
    // populate the question and answers
    private void PopulateQuestionAndAnswers() {
        questionAndAnswers = new List <QuestionAndAnswer>();

        for (Question__c question : [Select q.Type__c, q.Question__c, q.Order__c, 
                                            q.Name, q.Is_Group_Question__c,
                                            q.Group_Question__c, q.API_Field__c 
                                    From Question__c q
                                    Where Type__c = :customerType and Active__c = true
                                    and Internal_Visible__c = true
                                    Order By q.Order__c, q.Is_Group_Question__c DESC        ]) {
                
            QuestionAndAnswer qAndA = new QuestionAndAnswer(question, customer);    
            questionAndAnswers.add(qAndA);                                                          
        }
    }
        
    /* Inner classes */
    // Represets the question and its corresponding answer
    public class QuestionAndAnswer {
        private Account customer;
        public Question__c question {get; set;}
                
        public Integer answer {
            get {
                Integer answer = 0;
                if (question != null && question.api_field__c != null) {
                sObject cust = (sObject) customer;
                // get the first number from the picklist value
                String answerString = (String) cust.get(question.api_field__c);
                if (answerString != null) {
                        Pattern MyPattern = Pattern.compile('\\d+');
                        Matcher MyMatcher = MyPattern.matcher(answerString);
                        if (MyMatcher.find()) 
                                answer = Integer.valueOf(MyMatcher.group());
                }
            }
                return answer;
            } 
            private set;
        }               
                
        /* Constructor */
        public QuestionAndAnswer(Question__c question, Account customer) {
            this.question   = question;
            this.customer   = customer;
        }       
    }
}