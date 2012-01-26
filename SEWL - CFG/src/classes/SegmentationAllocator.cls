public with sharing class SegmentationAllocator {

/*
    Type:       Utility Class
    Purpose:    Calculates the segment basedon
                (i)     List of customers
                (ii)    Segment questions

    Used By:    CustomerSegmentEntry_Controller
    ---------------------------------------------------------------
    History:
        13-Sep-2011 - D.Thong (SFDC)    Created
*/

    /* Public Properties */
    //public List <Account> customers {get; set;}
    
    /* Private Properties */

    /* Static */
    private final static Map<Id, Segment__c> segments {get; private set; }
    private final static Map<String, Map<Id, Segment__c>> segmentsByType { get; private set; }
    private final static Map<Id, Map<Id, Segment_Question__c>> segmentQuestions { get; private set; }
    private final static Map<String, List<Question__c>> questionsByType {get; private set; }
    public final static Integer NEXT_REVIEW_OFFSET_DAYS = 547;

    /* Constructor */
    //public SegmentationAllocator (List <Account> customers) {
    //  this();
    //  this.customers = customers;
    //}

    public SegmentationAllocator() {}
    
    /* Public Methods */
    public Map<Id, Account> Allocate(List<Account> customers) {
      Map<Id, Account> custsUpdatedMap = new Map<Id, Account>();
      for (Account customer : customers) {
          if(Allocate(customer)){
              custsUpdatedMap.put(customer.id,customer);
          }
      }
      return custsUpdatedMap;
    }
    
    public boolean Allocate(Account customer) {
        boolean isChanged = false;
        // THIS DOES A TWO-TIER CHECK. IF THERE ARE CHILD SEGMENTS
        // IT WILL CALL THE SEGMENTATION PROCESS AGAIN
        
        // Get the Parent Segment score
        Map<Id, Double> segmentScores = GetSegmentScoresForCustomer(customer, null);
        
        // get the segment with the highest score
        Double highestScore= ((Decimal)(2)).pow(63).doubleValue() * -1;
        Id highestSegmentId;

        if (segmentScores == null) return isChanged ;

        for (Id segmentId : segmentScores.keySet()) {
            if (segmentScores.get(segmentId) > highestScore) {
                highestScore = segmentScores.get(segmentId);
                highestSegmentId = segmentId;
            }   
        }

        System.debug('##PARENTSCORES');
        System.debug(highestSegmentId);
        System.debug(segmentScores);    
        
        if (highestSegmentId != null) {
            // Are there child segments to check?
            List<Segment__c> childSegments = segments.get(highestSegmentId).Sub_Segments__r;
            if (childSegments != null && !childSegments.isEmpty()) {
                segmentScores = GetSegmentScoresForCustomer(customer, highestSegmentId);

                if (segmentScores == null) return isChanged ;

                highestScore= ((Decimal)(2)).pow(63).doubleValue() * -1;

                for (Id segmentId : segmentScores.keySet()) {
                    if (segmentScores.get(segmentId) > highestScore) {
                        highestScore = segmentScores.get(segmentId);
                        highestSegmentId = segmentId;
                    }   
                }               
                System.debug('##CHILDSCORES');
                System.debug(highestSegmentId);
                System.debug(segmentScores);    

            }
        }
        if(customer.segment__c != highestSegmentId){
            isChanged = true;
            // Populate the customer segment and related fields
            customer.segment__c = highestSegmentId;
        }
        return isChanged;
    }
    
    private Map<Id, Double> GetSegmentScoresForCustomer(Account customer, Id parentSegmentId) {
        // scores
        Map<Id, Double> segmentScores = new Map<Id, Double>();

        // get the segment type
        String segmentType;

        if(customer.RecordType!=Null){
            if (customer.RecordType.DeveloperName.startsWith('Residential')) 
                segmentType = 'Residential';
            else
                segmentType = 'Business';
        } else { // not found
            customer.Segment__c = null;
            return null;
        }

        // the segment that apply to this record type
        
        Map<Id, Segment__c> segmentsForRecordType = segmentsByType.get(segmentType);
        Map<Id, Segment__c> applicableSegments = new Map<Id, Segment__c>();
        
        if (segmentsForRecordType == null) {
            customer.Segment__c = null;
            return null;            
        }
        
        // build a list of segments specific to the parent (if applicable)
        for (Segment__c segment : segmentsForRecordType.values()) {
            if (segment.Parent_Segment__c == parentSegmentId ||
                    (parentSegmentId == null && segment.Parent_Segment__c == null)) {
                applicableSegments.put(segment.id, segment);            
            }
        }
        
        System.debug('##APPLICABLESEGMENTS');
        System.debug(applicableSegments);
        
        // initialise segment score with the intercept
        for (Segment__c segment : applicableSegments.values()) {
            segmentScores.put(segment.id, segment.Intercept__c != null ? segment.Intercept__c : 0); 
        }
        
        List<Question__c> questions = questionsByType.get(segmentType);
        
//      for (Integer i=1; i <= numberOfQuestions; i++) {
        for (Question__c q : questions) {   
            sObject cust = (sObject) customer;
            Integer answer;

            /*
            try {
                answer = Integer.valueOf(cust.get('Segment_Answer_' + i.format() + '__c')); 
            } catch (TypeException e) {
                answer=0;
            }
            if (answer == null) answer = 0;
            */
            
            // get the first number from the picklist value
            String answerString = (String) cust.get(q.api_field__c);
            if (answerString != null) {
                Pattern MyPattern = Pattern.compile('\\d+');
                Matcher MyMatcher = MyPattern.matcher(answerString);
                if (MyMatcher.find()) 
                    answer = Integer.valueOf(MyMatcher.group());
            }
            
            if (answer == null) return null; // not found, therefore drop out
            
            // score the sucker
            for (Segment__c segment : applicableSegments.values()) {
                Map<Id, Segment_Question__c> weights = segmentQuestions.get(segment.id);
                if (weights != null) {
                    Segment_Question__c segmentQuestion = weights.get(q.id);
                    if (segmentQuestion != null) {
                        Double totalScore = segmentScores.get(segment.id);
                        Double weight = segmentQuestion.Weight__c != null ? segmentQuestion.Weight__c : 0;
                        if (totalScore == null) totalScore = 0; 
                        totalScore += weight * answer;
                        segmentScores.put(segment.id, totalScore);
                    }
                }               
            }
        }       
        return segmentScores;
    }
    
    /* Static Initializers */
    static {
        // populate segment static information
        segments = new Map<Id, Segment__c>();
        segmentsByType = new Map<String, Map<Id, Segment__c>>();
        segmentQuestions = new Map<Id, Map<Id, Segment_Question__c>>(); 
        
        for (Segment__c segment : [select id, type__c, intercept__c, parent_segment__c,
                                                (select weight__c, question__r.api_field__c, question__r.order__c from
                                                    Segment_Questions__r
                                                    where question__r.Is_Group_Question__c = false
                                                    and question__r.Active__c = true),
                                                (select id from Sub_Segments__r)
                                                from Segment__c]) {
            // Populate segments map
            segments.put(segment.id, segment);
            
            // Populate the segments map by type map
            Map<Id, Segment__c> segmentsMap = segmentsByType.get(segment.type__c);
            if (segmentsMap == null) {
                segmentsMap = new Map<Id, Segment__c>();
                segmentsByType.put(segment.type__c, segmentsMap);
            }   
            segmentsMap.put(segment.id, segment);
            
            // populate segment questions
            Map<Id, Segment_Question__c> segmentQuestionsByOrder = new Map<Id, Segment_Question__c>();

            for (Segment_Question__c segmentQuestion : segment.Segment_Questions__r) {
                segmentQuestionsByOrder.put(segmentQuestion.question__c, segmentQuestion);
            }
                    
            segmentQuestions.put(segment.Id, segmentQuestionsByOrder);
        }   

        // populate question static information
        questionsByType = new Map<String, List<Question__c>> ();
        for (Question__c q : [select id, api_field__c, type__c from question__c 
                                where active__c = true and api_field__c != null
                                order by type__c, order__c]) {
            List<Question__c> questions = questionsByType.get(q.type__c);
            if (questions == null) {
                questions = new List<Question__c>();
                questionsByType.put(q.type__c, questions);
            }
            questions.add(q);
        }
    }

    public static testmethod void testme() {
        SegmentationAllocator alloc = new SegmentationAllocator();
    }

}