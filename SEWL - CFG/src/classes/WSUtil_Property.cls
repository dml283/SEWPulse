/*
    Type:       Web Service Utility
    Purpose:    Controls the mass Billing Account Address Flag Update

    Used By:    AccountMassBAcctAddressFlagUpdate
    ---------------------------------------------------------------
    History:

    09-Aug-2011 J.Pe (Davanti Consulting)    Created
    10-Jan-2011 Ji Zhang (Coretec Solutions) Add averageConsumption

*/
public class WSUtil_Property extends WSUtil {

    /* Inner Class */
    public class MeterReading{
        public Date readDate {get;set;}
        public String reading {get;set;}
        public String consumption {get;set;}
        public String noOfDays {get;set;}
        public String readingMethod {get;set;}
        public String estimated {get;set;}
        public String averageConsumption {get;set;}
    }


    /* static methods*/
    public static List<MeterReading> getMeterReadings(String meterType,String meterRef) {
        // Construct Request - Header
        TibcoMeterRead_MessageTypes.Header_element header = new TibcoMeterRead_MessageTypes.Header_element();
        header.UserID = Userinfo.getUserName();
        header.UserType = Userinfo.getUserType();
        header.MessageTimeStamp = datetime.now();
        // Initialise Web Service
        TibcoMeterRead_Service.SOAPEventSource stub = new TibcoMeterRead_Service.SOAPEventSource ();
        stub.timeout_x = 60000;
        TibcoMeterRead_MessageTypes.getMeterReadResponse_element response = stub.getMeterRead(header, meterType, meterRef);
        if (Boolean.valueOf(response.header.MessageResponseStatus.MessageSuccessInd)) {  //webservice success
	        List<MeterReading> meterReadings = new List<MeterReading>();
			if (response.ProcessOutputData != null &&
						response.ProcessOutputData.MeterReads != null &&
						response.ProcessOutputData.MeterReads.Read != null) {	
	            List<TibcoMeterRead_MessageTypes.Read_element> readings = response.ProcessOutputData.MeterReads.Read;
	            for(TibcoMeterRead_MessageTypes.Read_element read: readings){
	                meterReadings.add(transformMeterReading(read));
	            }
			}
            return meterReadings ;
        }else{
            throw processMultiWSException(response.Header.MessageResponseStatus.ErrorStatus);
        }
    }

    /* private static methods */
    private static MeterReading transformMeterReading(TibcoMeterRead_MessageTypes.Read_element read){
        MeterReading meterRead = new MeterReading();
        meterRead.readDate = read.ReadDate;
        meterRead.reading = read.reading;
        meterRead.consumption = read.consumption;
        meterRead.noOfDays = read.noOfDays;
        meterRead.readingMethod = read.readingMethod;
        meterRead.estimated = read.estimated;
        try {
	        if (read.Consumption != null && read.NoOfDays != null && double.valueOf(read.noOfDays) != 0)
		        meterRead.averageConsumption = String.valueOf(((double.valueOf(read.Consumption) * 100000.00 / double.valueOf(read.noOfDays)).round()) / 100);
        } catch (TypeException te) {}
        
        return meterRead;
    }
    private static MultipleWebServiceBusinessException processMultiWSException(List<TibcoMeterRead_MessageTypes.ErrorStatus_element> errorStatuses){
        MultipleWebServiceBusinessException multiWSEx = new MultipleWebServiceBusinessException('Errors returned from Meter Read Web Service');
        for(TibcoMeterRead_MessageTypes.ErrorStatus_element errorStatus: errorStatuses ){
            SingleWebServiceBusinessException ex = new SingleWebServiceBusinessException(errorStatus.ErrorDescription);
            ex.errorCode = errorStatus.ErrorCode;
            ex.errorSeverity = errorStatus.ErrorSeverity;
            multiWSEx.multiEx.add(ex);
        }
        return multiWSEx;
    }
    
    private static TestMethod void TestMe() {
    	// test the error handler
    	List<TibcoMeterRead_MessageTypes.ErrorStatus_element> errorStatuses = new List<TibcoMeterRead_MessageTypes.ErrorStatus_element>();
    	TibcoMeterRead_MessageTypes.ErrorStatus_element err = new TibcoMeterRead_MessageTypes.ErrorStatus_element();
		err.ErrorCode='000';
		err.ErrorSeverity='1';
		err.ErrorDescription='ABC';
    						
    	errorStatuses.add(err);
    	processMultiWSException(errorStatuses);
    }
}