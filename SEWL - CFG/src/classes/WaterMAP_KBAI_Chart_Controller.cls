public with sharing class WaterMAP_KBAI_Chart_Controller {

/*
    Type:       Controller Extension
    Purpose:    Controller to display the KBAI Chart

    Used By:    WaterMAP_KBAI_Preview_Chart Component
    ---------------------------------------------------------------
    History:

    07-Jun-2011 D.Thong (Salesforce)    Created

*/

    /* PUBLIC PROPERTIES */

    // Current Year KBAIs - should only be populated via a component
    // resets orderKBAILines and kbaiSummaryTable when set, so it forces update
    public List <Key_Business_Activity_Indicator__c> recentYrKBAIs { 
        get; 
        set{
            recentYrKBAIs = value;
            orderedKBAILines = null;
            kbaiSummaryTable = null;
        } 
    }

    // the submission
    public WaterMAP_Submission__c wmapSub {get; set;}

    // the most recent year
    public String recentYear {
        get {
            if (wmapSub != null ) return WaterMAPUtil.getYearBeforePeriod(wmapSub.Year__c);
            return null;
        }
    }

    // number of years to display KBAI
    public Integer noOfYearsToDisplayForKBAI{
        get{
            if(noOfYearsToDisplayForKBAI==null){
                noOfYearsToDisplayForKBAI = 3; // default to past 3 years
            }return noOfYearsToDisplayForKBAI;
        }set;
    }
    // number of years to display KBAI Graph
    public Integer noOfYearsToDisplayForKBAIGraph{
        get{
            if(noOfYearsToDisplayForKBAIGraph==null){
                noOfYearsToDisplayForKBAIGraph = 2; // default to past 2 years
            }return noOfYearsToDisplayForKBAIGraph;
        }set;
    }

    // List of ordered KBAI Lines ordered by period Name
    public List<WaterMAPUtil.KBAILine> orderedKBAILines {
        get {
            if(orderedKBAILines == null){
                orderedKBAILines = getOrderedKBAILines();
            }return orderedKBAILines;
        } private set;
    }
    public List<KBAISummaryTableRow> kbaiSummaryTable{
        get{
            if(kbaiSummaryTable == null){
                kbaiSummaryTable = getKBAISummaryTable();
            }return kbaiSummaryTable;
        }private set;
    }

    // generates the chart data for GoogleViz
/*  public String KBAIJSONChartData {
        get {
            GoogleViz gv = new GoogleViz();

            // build the column
            gv.cols = new list<GoogleViz.col> {
                new GoogleViz.Col('col1', 'Period','string'), // x-axis
                new GoogleViz.Col('col2', 'kL per ' + wmapSub.WaterMAP__r.KBAI_Description__c, 'number') // y-axis
            };

            for (WaterMAPUtil.KBAILine line : orderedKBAILines) {
                GoogleViz.row r = new GoogleViz.row();

                r.cells.add ( new GoogleViz.cell( line.periodName ) );
                r.cells.add ( new GoogleViz.cell( line.klperkbai ) );

                gv.addRow( r );
            }

            return gv.toJsonString();
        }
    } */
/*
    public Decimal recentYearWaterConsumption {
        get {
            // summarise prior year stats
            List<WaterMAP_Consolidated_Accounts__c> waterMAPConsolAccs = [Select Watermap__c, Id, Billing_Account__c
                                                                                From WaterMAP_Consolidated_Accounts__c
                                                                                where WaterMAP__c = :wmapSub.watermap__c];
            Set<Id> billingAccIds = new Set<Id>();
            for(WaterMAP_Consolidated_Accounts__c acc: waterMAPConsolAccs){
                billingAccIds.add(acc.Billing_Account__c);
            }

            AggregateResult[] groupedResults
                    = [SELECT SUM(Water_Volume__c) watervolumesum FROM Consumption_and_Charge__c
                        WHERE Financial_Year__c =: recentYear and Billing_Account__c in :billingAccIds];

            Decimal waterConsumption=0;
            if (groupedResults != null && !groupedResults.isEmpty())
                waterConsumption = (Decimal) groupedResults[0].get('watervolumesum');

            return waterConsumption;
        }
    }

    // get the total of the recent year KBAI
    public Decimal recentYearKBAITotal {
        get {
            if (recentYrKBAIs != null) {
                // sum or average based on passed in KBAI
                Decimal sum=0;
                String recentYear = this.recentYear;
                for (Key_Business_Activity_Indicator__c kbai : recentYrKBAIs) {
                    if (kbai.Year__c == recentYear )
                        sum+= kbai.count__c != null ? kbai.count__c : 0;
                }

                return sum;
            } else {
                // sum based on selected KBAI in DB
            }
            return 0;
        }
    }

    // average of recent year kbais
    public Decimal recentYearKBAIAverage {
        get {
            if (recentYrKBAIs != null) {
                // sum or average based on passed in KBAI
                Decimal sum=0;
                Integer kbaicount = 0;
                String recentYear = this.recentYear;

                for (Key_Business_Activity_Indicator__c kbai : recentYrKBAIs) {
                    if (kbai.Year__c == recentYear ) {
                        sum+=kbai.count__c;
                        kbaicount++;
                    }
                }

                if (kbaicount != 0)
                    return (sum / kbaicount).setScale(2);
                else
                    return 0;
            } else {
                // sum based on selected KBAI in DB
            }
            return 0;
        }
    }

    // get the average kl per kbai for year ( recentYearWaterConsumption / KBAI Total)
    public Decimal recentYearKLPerKBAI {
        get {
            Decimal watertotal=recentYearWaterConsumption;
            Decimal kbaitotal;
            if (wmapsub.WaterMAP__r.KBAI_Type__c == 'Average')
                kbaitotal = recentYearKBAIAverage;
            else
                kbaitotal = recentYearKBAITotal;

            if (kbaitotal <> 0)
                return watertotal / kbaitotal;
            return 0;
        }
    }
*/
    // Generates chart data for Google Charts
    public String googleChartURL {
        get {
            return GetChartURL();
        }
    }

    /* PRIVATE PROPERTIES */
    // which years are we displaying
    private String[] yearsToDisplay {
        get {
            return WaterMAPUtil.getLastNYearsInOrder(recentYear, noOfYearsToDisplayForKBAI);
        }
    }    
    // which years are we displaying for the graph
    private String[] yearsToDisplayForGraph {
        get {
            return WaterMAPUtil.getLastNYearsInOrder(recentYear, noOfYearsToDisplayForKBAIGraph);
        }
    }

    // the chart data
    private List<ChartSeries> chartSeriesData {
        get {
//          if (chartSeriesData == null) {
                // initialise based on yearsToDisplay
                List<ChartSeries> chartSeriesDataTemp = InitChartSeries();
                // populate with the information
                PopulateChartSeriesData(chartSeriesDataTemp);
                this.ChartSeriesData = chartSeriesDataTemp;
//          }
            return chartSeriesData;
        }
        set;
    }

    /* CONSTANTS */
    private static String[] MONTHSLABEL = new String[] {'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'};

    /* CONSTRUCTOR */
    public WaterMAP_KBAI_Chart_Controller () {}

    /* PUBLIC METHODS */
    // no op
    public PageReference NoOp() {return null;}

    // class to represent a chart line
    private class ChartLine {
        public String x { get; set; }
        public Decimal y { get; set; }

        public ChartLine(){}
        public ChartLine(String x, Decimal y) {
            this.x = x;
            this.y = y;
        }
    }

    // represents a whole series of data
    private class ChartSeries {
        public String serieslabel { get; set; }
        public List<ChartLine> chartdata { get; set; }

        public ChartSeries(String serieslabel){ this.serieslabel = serieslabel;}
        public ChartSeries(String serieslabel, List<ChartLine> chartdata){
            this.serieslabel = serieslabel;
            this.chartdata = chartdata;
        }
    }


    /* PRIVATE METHODS */
    private List<WaterMAPUtil.KBAILine> GetOrderedKBAILines() {
        // gets an ordered list of kbai lines by
        // 1. Getting all consumption
        // 2. Matching the consumption period to the kbai line
        // 3. Creating a KBAI line entry
        // n.b. if recent year KBAIs is populated, then it is taken from there
        // rather than queried. This allows the page to not be saved before
        // generating the graph
        // assumes: that if no conumption is there, the kbai is not valid!!

        // our final output
        List<WaterMAPUtil.KBAILine> KBAILines = new List<WaterMAPUtil.KBAILine>();

        // get ordered consumption
        List <Consumption_and_Charge__c> orderedCharges = WaterMAPUtil.getWaterMAPAllChargesInOrder(wmapSub.WaterMAP__c, yearsToDisplay);

        // get the map of KBAIs. If recent yr KBAI is present, then that is added
        // but not queried in SOQL
        Map<String, Key_Business_Activity_Indicator__c> KBAIMapByPeriod = new Map<String, Key_Business_Activity_Indicator__c>();

        for (Key_Business_Activity_Indicator__c kbai :
                                [Select id, Year__c, Name, Period__c, End_Date__c, Count__c, WaterMAP__c
                                            from Key_Business_Activity_Indicator__c
                                            where WaterMAP__c = :wmapsub.Watermap__c
                                            and   Year__c in :yearsToDisplay]) {
            if (kbai.Year__c != recentYear || recentYrKBAIs == null) {
                // not the same as the recent year or recent year kbai is not populated
                KBAIMapByPeriod.put(kbai.period__c, kbai);
            }
        }

        // append the recent years KBAI
        for(Key_Business_Activity_Indicator__c kbai : recentYrKBAIs) {
                KBAIMapByPeriod.put(kbai.period__c, kbai);
        }

        // loop through the charges in order, matching the kbai and building
        // the line as we go through
        for (Consumption_and_Charge__c charge : orderedCharges) {
            Decimal kbaicount = 0;
            Key_Business_Activity_Indicator__c kbai = KBAIMapByPeriod.get(charge.Name);

            if (kbai != null) kbaicount = (kbai.count__c != null ? kbai.count__c : 0);

            WaterMAPUtil.KBAILine line = new WaterMAPUtil.KBAILine(charge.Name, charge.Financial_Year__c, kbaicount, charge.Water_Volume__c != null ? charge.Water_Volume__c : 0);
            KBAILines.add(line);
        }

        return KBAILines;
    }
    private List<KBAISummaryTableRow> getKBAISummaryTable(){
        List<KBAISummaryTableRow> tempList = new List<KBAISummaryTableRow>();
        Map<String, List<WaterMAPUtil.KBAILine>> kbaiLineMapByYear = new Map<String, List<WaterMAPUtil.KBAILine>>();
        for(WaterMAPUtil.KBAILine kbaiLine: orderedKBAILines){
            List<WaterMAPUtil.KBAILine> kbaiLines;
            if(kbaiLineMapByYear.containsKey(kbaiLine.year)){
                kbaiLines = kbaiLineMapByYear.get(kbaiLine.year);
            }else{
                kbaiLines = new List<WaterMAPUtil.KBAILine>();
                kbaiLineMapByYear.put(kbaiLine.year,kbaiLines);
            }
            kbaiLines.add(kbaiLine);
        }
        for(String year: yearsToDisplay){
            tempList.add(new KBAISummaryTableRow(year, kbaiLineMapByYear.get(year), wmapSub.waterMAP__r.KBAI_Type__c));
        }
        return tempList;
    }
    // builds the google chart URL
    private String GetChartURL() {

        // base url
        String url = 'https://chart.googleapis.com/chart?';
        // chart size & type
        url += 'chs=500x300&cht=lc';

        String seriesLabel;
        String ydata;
        Decimal maxy=1;

        // series label and y data
        for (ChartSeries s : chartSeriesData) {
            // build the series label
            if (seriesLabel == null)
                seriesLabel = s.seriesLabel;
            else
                seriesLabel += '|' + s.seriesLabel;

            // build the y data
            String yseriesdata;
            for (ChartLine line : s.chartdata) {
                String formattedY;
                System.debug(line);
                if (line.y != null)
                    formattedY = line.y.toPlainString();
                else
                    formattedY = '_';
                if (yseriesdata != null)
                    // _ indicates null
                    yseriesdata += ',' + formattedY;
                else
                    // _ indicates null
                    yseriesdata = formattedY;

                if (maxy < line.y) maxy = line.y;
            }
            if (ydata == null)
                ydata = yseriesdata;
            else
                ydata += '|' + yseriesdata;

        }
        url += '&chdl='+seriesLabel; // series label
        url += '&chd=t:' + ydata; // data

        // chart x-label
        String xlabel='';
        for (String mth : MONTHSLABEL) {
            xlabel+= '|' + mth;
        }

        url += '&chxl=0:' + xlabel;

        maxy = maxy * 1.1;

        // format axes
        url += '&chxr=0,0,12|1,0,' + maxy.toPlainString() + '&chxs=0,676767,11.5,0,lt,676767&chxt=x,y&chco=005F98,FF0000,70BF49,00BBDE';
        // everything else
        url += '&chds=0,' + maxy.toPlainString() + '&chdlp=b&chls=2|2|2&chma=5,5,5,25';
        // chart title
        url += '&chtt=KL Usage Per ' + wmapSub.WaterMAP__r.KBAI_Description__c;

        System.debug(url);

        return url;

    }

    // generates an empty chart series with 12 months worth of data in each
    private List<ChartSeries> InitChartSeries() {
        List<ChartSeries> series = new List<ChartSeries>();
        for (String year : yearsToDisplayForGraph) {
            // build 12 months of lines
            List<ChartLine> lines = new List<ChartLine>();
            for (String month : MONTHSLABEL) {
                lines.add(new ChartLine(month, null));
            }

            series.add(new ChartSeries(year, lines));
        }
        return series;
    }

    // populates the chart data with the real stuff!
    private void PopulateChartSeriesData(List<ChartSeries> chartSeriesData) {
        // loop through the ordered lines and build a two-level map
        // Series (Period, line)
        Map<String, Map<String, WaterMAPUtil.KBAILine>> KBAISeriesMap = new Map<String, Map<String, WaterMAPUtil.KBAILine>>();
        // Setup map for years that get displayed on graph 
        for(String year: yearsToDisplayForGraph){
            KBAISeriesMap.put(year, new Map<String, WaterMAPUtil.KBAILine>());
        }

        for (WaterMAPUtil.KBAILine k : orderedKBAILines) {
            Map<String, WaterMAPUtil.KBAILine> KBAILineMap = KBAISeriesMap.get(k.year);
            // the series is not there, therefore it is not shown on graph - ignore
            if (KBAILineMap==null) {
                //KBAILineMap = new Map<String, WaterMAPUtil.KBAILine>();
                //KBAISeriesMap.put(k.year, KBAILineMap);
                continue;
            }

            // quarterly data (may need to interpolate later!)
            if (k.periodName.startsWith('JAN-MAR') || k.periodName.startsWith('Jan-Mar') || k.periodName.startsWith('Q4')) {
                KBAILineMap.put('Jan', k);
                KBAILineMap.put('Feb', k);
                KBAILineMap.put('Mar', k);
            } else if (k.periodName.startsWith('APR-JUN') || k.periodName.startsWith('Apr-Jun') || k.periodName.startsWith('Q3')) {
                KBAILineMap.put('Apr', k);
                KBAILineMap.put('May', k);
                KBAILineMap.put('Jun', k);
            } else if (k.periodName.startsWith('JUL-SEP') || k.periodName.startsWith('Jul-Sep') || k.periodName.startsWith('Q1')) {
                KBAILineMap.put('Jul', k);
                KBAILineMap.put('Aug', k);
                KBAILineMap.put('Sep', k);
            } else if (k.periodName.startsWith('OCT-DEC') || k.periodName.startsWith('Oct-Dec') || k.periodName.startsWith('Q2')) {
                KBAILineMap.put('Oct', k);
                KBAILineMap.put('Nov', k);
                KBAILineMap.put('Dec', k);
            } else { // monthly data
                KBAILineMap.put(k.periodName.substring(0, 3), k);
            }
        }

        // loop through the chart series data and populate it
        for (ChartSeries series : chartSeriesData) {
            // get the KBAI line data for that year
            Map<String, WaterMAPUtil.KBAILine> KBAILineMap = KBAISeriesMap.get(series.serieslabel);

            if (KBAILineMap != null && !KBAILineMap.isEmpty()) {
                for (ChartLine line : series.chartData){
                    WaterMAPUtil.KBAILine kbailine = KBAILineMap.get(line.x);
                    if (kbailine != null)
                        line.y = kbailine.klperkbai;
                }
            }
        }
    }
    
    // class to hold KBAI sum/average data
    public class KBAISummaryTableRow{
        public String year{get;set;}
        public Decimal totalYearConsumption {
            get{
                if(totalYearConsumption == null){
                    totalYearConsumption = 0.0;
                }return totalYearConsumption;
            }set;
        }
        public Decimal kbaiCountSummary {
            get{
                if(kbaiCountSummary == null){
                    kbaiCountSummary = 0.0;
                }return kbaiCountSummary;
            }set;
        }
        public Decimal klPerKBAISummary {
            get{
                if(klPerKBAISummary == null){
                    klPerKBAISummary = 0.0;
                }return klPerKBAISummary;
            }
            set;
        }
        public KBAISummaryTableRow(String year, List<WaterMAPUtil.KBAILine> kbaiLines, String kbaiType){
            this.year = year;
            Integer numberOfKBAIRecord = 0;
            if(kbaiLines!=null){
                for(WaterMAPUtil.KBAILine kbai: kbaiLines){
                    totalYearConsumption += kbai.usage;
                    kbaiCountSummary += kbai.kbaiCount;
                    numberOfKBAIRecord ++;
                }
                if (kbaiType=='Average'){
                    kbaiCountSummary = kbaiCountSummary / numberOfKBAIRecord;
                }
                if(kbaiCountSummary > 0.0){
                    klPerKBAISummary = totalYearConsumption / kbaiCountSummary;
                }
            }
        }
    }

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
        waterMapSub.Status__c = 'Not Started';
        waterMapSub.Watermap__c = waterMap.id;
        waterMapSub.Watermap__r = waterMap;
        waterMapSub.Year__c = '2011/12';
        insert waterMapSub;

        Consumption_and_Charge__c charge = new Consumption_and_Charge__c();
        charge.Water_Volume__c = 1000;
        charge.Billing_Account__c = billAcc.id;
        charge.Financial_Year__c = '2010/11';
        charge.Name = 'Jan-Mar 2010/11';
        insert charge;

        charge = new Consumption_and_Charge__c();
        charge.Water_Volume__c = 2000;
        charge.Billing_Account__c = billAcc.id;
        charge.Financial_Year__c = '2010/11';
        charge.Name = 'Apr-Jun 2010/11';
        insert charge;

        charge = new Consumption_and_Charge__c();
        charge.Water_Volume__c = 3000;
        charge.Billing_Account__c = billAcc.id;
        charge.Financial_Year__c = '2010/11';
        charge.Name = 'Jul-Sep 2010/11';
        insert charge;

        charge = new Consumption_and_Charge__c();
        charge.Water_Volume__c = 4000;
        charge.Billing_Account__c = billAcc.id;
        charge.Financial_Year__c = '2010/11';
        charge.Name = 'Oct-Dec 2010/11';
        insert charge;

        charge = new Consumption_and_Charge__c();
        charge.Water_Volume__c = 1000;
        charge.Billing_Account__c = billAcc.id;
        charge.Financial_Year__c = '2009/10';
        charge.Name = 'Oct-Dec 2009/10';
        insert charge;

        List <Key_Business_Activity_Indicator__c> kbais = new List<Key_Business_Activity_Indicator__c>();

        Key_Business_Activity_Indicator__c kbai = new Key_Business_Activity_Indicator__c();
        kbai.WaterMAP__c = waterMap.id;
        kbai.Count__c = 100;
        kbai.Period__c = 'Jan-Mar 2010/11';
        kbai.Year__c = '2010/11';
        insert kbai;
        kbais.add(kbai);

        kbai = new Key_Business_Activity_Indicator__c();
        kbai.WaterMAP__c = waterMap.id;
        kbai.Count__c = 200;
        kbai.Period__c = 'Apr-Jun 2010/11';
        kbai.Year__c = '2010/11';
        insert kbai;
        kbais.add(kbai);

        kbai = new Key_Business_Activity_Indicator__c();
        kbai.WaterMAP__c = waterMap.id;
        kbai.Count__c = 300;
        kbai.Period__c = 'Jul-Sep 2010/11';
        kbai.Year__c = '2010/11';
        insert kbai;
        kbais.add(kbai);

        kbai = new Key_Business_Activity_Indicator__c();
        kbai.WaterMAP__c = waterMap.id;
        kbai.Count__c = 400;
        kbai.Period__c = 'Oct-Dec 2010/11';
        kbai.Year__c = '2010/11';
        insert kbai;
        kbais.add(kbai);

        kbai = new Key_Business_Activity_Indicator__c();
        kbai.WaterMAP__c = waterMap.id;
        kbai.Count__c = 400;
        kbai.Period__c = 'Oct-Dec 2009/10';
        kbai.Year__c = '2009/10';
        insert kbai;
        kbais.add(kbai);


        WaterMAP_KBAI_Chart_Controller controller = new WaterMAP_KBAI_Chart_Controller();

        controller.recentYrKBAIs = kbais;
        controller.wmapSub = waterMapSub;
        System.assertEquals('2010/11', controller.recentYear);
        System.assertEquals(3, controller.noOfYearsToDisplayForKBAI);

        List<WaterMAPUtil.KBAILine> lines = controller.orderedKBAILines;
        System.assertEquals(lines.size(), 5);
        /*
        System.assertEquals(1000, controller.recentYearKBAITotal);
        System.assertEquals(10000, controller.recentYearWaterConsumption);
        System.assertEquals(250, controller.recentYearKBAIAverage);
        System.assertEquals(40, controller.recentYearKLPerKBAI);
        */
        String url =controller.googleChartURL;
        controller.NoOp();
        List<KBAISummaryTableRow> tempTable = controller.kbaiSummaryTable;

        controller.wmapsub.WaterMAP__r.KBAI_Type__c = 'Sum';
        //System.assertEquals(10, controller.recentYearKLPerKBAI);
    }
}