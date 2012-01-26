/*
    Type:       Controller Extension
    Purpose:    Controls the meter readings history VF page

    Used By:    MeterReadingsHistory
    ---------------------------------------------------------------
    History:

    11-Aug-2011 J.Pe (Davanti Consulting)    Created

*/
public class MeterReadingsHistoryExCon {

    private boolean isTestException {
        get{
            if (isTestException == null){
                isTestException = false;
            }return isTestException;
        }set;
    }

    /* Public Properties */
    public List<WSUtil_Property.MeterReading> meterReadings{
        get{
            if(meterReadings==null){
                try{
                    meterReadings = WSUtil_Property.getMeterReadings(currentMeter.Meter_Type__c, currentMeter.Pit_Reference__c);
                    if(Test.isRunningTest() && isTestException ){
                        WSUtil.MultipleWebServiceBusinessException multiEx = new WSUtil.MultipleWebServiceBusinessException('testing');
                        multiEx.MultiEx.add(new WSUtil.SingleWebServiceBusinessException('test'));
                        throw multiEx;
                    }
                }catch(System.CalloutException ex){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Problem with web service - please contact system administrator. Error message:'+ex.getMessage()));
                }catch(WSUtil.MultipleWebServiceBusinessException ex){
                    //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Error - please contact system administrator. Error message:'));
                    for(WSUtil.SingleWebServiceBusinessException subEx: ex.MultiEx){
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,subEx.getMessageByUserType()));
                    }
                }
            }return meterReadings;
        }private set;
    }

    public String retURL{
        get{
            String temp = Apexpages.currentPage().getParameters().get('retURL');
            if (temp==null) temp = '/'+currentMeter.id;
            return temp;
        }
    }

    /* Private Properties */
    private Meter_Details__c currentMeter{
        get{
            return (Meter_Details__c) stdCon.getRecord();
        }
    }
    private ApexPages.StandardController stdCon;


    /* Constructors */
    public MeterReadingsHistoryExCon(ApexPages.StandardController controller) {
        stdCon = controller;
    }

    /* Test Method */
    public static testmethod void test_MeterReadingsHistoryExCon(){
        Property__c prop = new Property__c();
        prop.Universal_Id_c__c = 'sdgfsdgf';
        prop.Name = 'Test Property';
        insert prop;
        Meter_Details__c meterDetail = new Meter_Details__c(Property__c = prop.id, Meter_Type__c = 'Test', Pit_Reference__c='Test');
        insert meterDetail;
        Test.startTest();
        PageReference pageRef = Page.MeterReadingsHistory;
        ApexPages.StandardController sc = new ApexPages.StandardController(meterDetail);
        Test.setCurrentPage(pageRef);
        MeterReadingsHistoryExCon excon = new MeterReadingsHistoryExCon(sc);
        pageRef.getParameters().put('retURL','/'+meterDetail.id);
        System.assert(excon.meterReadings.size() > 0);
        System.assert(excon.retURL != null);
        excon.meterReadings = null;
        excon.isTestException = true;
        try{
            List<WSUtil_Property.MeterReading> temp = excon.meterReadings;
            //System.assert(false);
        }catch (WSUtil.MultipleWebServiceBusinessException ex){}
        
        TibcoMeterRead_MessageTypes.ProcessInputData_element pid = new TibcoMeterRead_MessageTypes.ProcessInputData_element();
        TibcoMeterRead_MessageTypes.Meter_element  me = new TibcoMeterRead_MessageTypes.Meter_element ();
        TibcoMeterRead_MessageTypes.ErrorStatus_element ee  = new TibcoMeterRead_MessageTypes.ErrorStatus_element ();
        
    }

}