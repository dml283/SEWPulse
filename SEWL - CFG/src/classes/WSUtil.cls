public with sharing virtual class WSUtil {

/*
    Type:       Web Service Utility
    Purpose:    Parent class for web services utility

    Inherited By:    WS_Util***
    ---------------------------------------------------------------
    History:

    22-Nov-2011 Dthong (SFDC)   Created
*/
    /* Default Constructor */
    public WSUtil() {
        
    }
    
    /* Inner classes */
    // error classes
    public class SingleWebServiceBusinessException extends Exception{
        public String errorCode {get;set;}
        public String errorSeverity {get;set;}
        public String getMessageByUserType(){
            if('Standard'.equals(UserInfo.getUserType())) return this.getMessage();
            PortalErrorMessages__c pem = PortalErrorMessages__c.getInstance(errorCode);
            if(pem == null){
                pem = PortalErrorMessages__c.getInstance('default');
                if(pem == null) return this.getMessage();
                else return pem.Portal_Error_Msg__c+'\n'+this.getMessage();
            }
            else {
                return pem.Portal_Error_Msg__c;
            }
        }
    }
    
    public class MultipleWebServiceBusinessException extends Exception{
        public List<SingleWebServiceBusinessException> multiEx {
            get{
                if (multiEx == null){
                    multiEx = new List<SingleWebServiceBusinessException>();
                }return multiEx ;
            }private set;
        }
    }
    public Decimal formatTIBCODecimal(String i) {

        Decimal retVal = 0;

        if(i !=null && i != '' ) {
            // remove commas
            String amt = i.replace(',','');
            
            // move - to the start
            if (amt.endsWith('-')) {
                amt = amt.replace('-','');
                amt = '-' + amt;                                
            }
            
            retVal = Decimal.valueOf(amt.trim());
        } 
        
        return retVal;
        
    }
    private static TestMethod void testMe() {
        WSUtil wsu = new WSUtil();
        System.assertEquals(123123, wsu.formatTIBCODecimal('123,123'));
        System.assertEquals(-123123, wsu.formatTIBCODecimal('123,123-'));
    }

}