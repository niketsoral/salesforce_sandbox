@isTest
private class hqInt_TestClass 
{
    


    @testSetup static void setupCustomSetting() 
    {
        CommcareToSalesforceSettings__c[] customSettings = new list <CommcareToSalesforceSettings__c>();

        CommcareToSalesforceSettings__c testCustomSetting = new CommcareToSalesforceSettings__c();
        testCustomSetting.name = 'ApiLimitParameter';
        testCustomSetting.value__c = '10';
        customSettings.add(testCustomSetting);

        testCustomSetting = new CommcareToSalesforceSettings__c();
        testCustomSetting.name = 'BatchFailureReportRecepeint';
        testCustomSetting.value__c = 'angadpathak@outlook.com;';
        customSettings.add(testCustomSetting);

        testCustomSetting = new CommcareToSalesforceSettings__c();
        testCustomSetting.name = 'CommCarePassword';
        testCustomSetting.value__c = 'Google@123';
        customSettings.add(testCustomSetting);

        testCustomSetting = new CommcareToSalesforceSettings__c();
        testCustomSetting.name = 'CommCareUserName';
        testCustomSetting.value__c = 'niketsoral@gmail.com';
        customSettings.add(testCustomSetting);

        testCustomSetting = new CommcareToSalesforceSettings__c();
        testCustomSetting.name = 'LastRunDate';
        testCustomSetting.value__c = '2015-01-01';
        customSettings.add(testCustomSetting);

        testCustomSetting = new CommcareToSalesforceSettings__c();
        testCustomSetting.name = 'JOBSTARTDATE';
        testCustomSetting.value__c = '2015-01-01';
        customSettings.add(testCustomSetting);

        insert customSettings;
    }

    @isTest static void hqInt_TestMethod() 
    {
        
            
            

        Test.startTest();

            //Test.setMock(HttpCalloutMock.class, myMultiMockObject); // setup of multiMockObject omitted for clarity
            Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
            Database.BatchableContext     bc;
            hqInt_MainClassBatch bClass = new hqInt_MainClassBatch();

            // we execute the start() and prepare results for execute()
            // in my use case, start() does the callout; 
            // thus the testmethod mocks the results of the callout (assumed here to be accounts)
            // setup of custom Iterable and Iterator not shown
            Integer[]  itrbl = (Integer[])bclass.start(bc);  //start() returns an iterable, in my case, a custom iterable. 
            //Note the casting
            //iterator  itrator = (Iterable<Integer>) itrbl.iterator();  // continue simulation of start() by constructing the iterator//
            Integer[] aScopeList = new Integer[]{};

            //create scope for execute() by iterating against the result of the mocked callout
                
            aScopeList.add(0);
            //while (itrator.hasNext()) 
            //{ 
                //aScopeList.add(itrator.next());

                // Now invoke execute() w/ Account list built via mocked callout invoked by start()
                system.debug('---bc--'+bc);
                bClass.execute(bc,aScopeList);

                // Finally, invoke finish()
                bClass.finish(bc);
                Test.stopTest();
                
            
    }
    
    @isTest 
    static void hqInt_TestMethodPhase2_SoftPlanVer() 
    {

            Test.startTest();

            //Test.setMock(HttpCalloutMock.class, myMultiMockObject); // setup of multiMockObject omitted for clarity
            Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
            Database.BatchableContext     bc;
            hqInt_BatchFetchObjectSoftwarePlanVer bClass = new hqInt_BatchFetchObjectSoftwarePlanVer(1);

            Integer[]  itrbl = (Integer[])bClass.start(bc);  //start() returns an iterable, in my case, a custom iterable. 
            Integer[] aScopeList = new Integer[]{};
            aScopeList.add(0);
            bClass.execute(bc,aScopeList);

            // Finally, invoke finish()
            bClass.finish(bc);


            Test.stopTest();
    }

    @isTest 
    static void hqInt_TestMethodPhase2_SoftPlan() 
    {

            Test.startTest();

            //Test.setMock(HttpCalloutMock.class, myMultiMockObject); // setup of multiMockObject omitted for clarity
            Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
            Database.BatchableContext     bc;
            hqInt_BatchFetchObjectSoftwarePlan bClass = new hqInt_BatchFetchObjectSoftwarePlan(1);

            Integer[]  itrbl = (Integer[])bClass.start(bc);  //start() returns an iterable, in my case, a custom iterable. 

            Integer[] aScopeList = new Integer[]{};
            aScopeList.add(0);
            bClass.execute(bc,aScopeList);

            // Finally, invoke finish()
            bClass.finish(bc);
            Test.stopTest();
    }

    @isTest 
    static void hqInt_TestMethodPhase2_Subscriber() 
    {

            Test.startTest();

            //Test.setMock(HttpCalloutMock.class, myMultiMockObject); // setup of multiMockObject omitted for clarity
            Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
            Database.BatchableContext     bc;
            hqInt_BatchFetchObjectSubscriber bClass = new hqInt_BatchFetchObjectSubscriber(1);

            Integer[]  itrbl = (Integer[])bClass.start(bc);  //start() returns an iterable, in my case, a custom iterable. 
            
            Integer[] aScopeList = new Integer[]{};
            aScopeList.add(0);
            bClass.execute(bc,aScopeList);

            // Finally, invoke finish()
            bClass.finish(bc);
            Test.stopTest();
    }

    @isTest 
    static void hqInt_TestMethodPhase2_Subscription() 
    {

            Test.startTest();

            //Test.setMock(HttpCalloutMock.class, myMultiMockObject); // setup of multiMockObject omitted for clarity
            Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
            Database.BatchableContext     bc;
            hqInt_BatchFetchObjectSubscription bClass = new hqInt_BatchFetchObjectSubscription(1);

            Integer[]  itrbl = (Integer[])bClass.start(bc);  //start() returns an iterable, in my case, a custom iterable. 
            
            Integer[] aScopeList = new Integer[]{};
            aScopeList.add(0);
            bClass.execute(bc,aScopeList);

            // Finally, invoke finish()
            bClass.finish(bc);
            Test.stopTest();
    }
    
    @isTest 
    static void hqInt_TestMethodPhase2_BillingAccount() 
    {

            Test.startTest();

            //Test.setMock(HttpCalloutMock.class, myMultiMockObject); // setup of multiMockObject omitted for clarity
            Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
            Database.BatchableContext     bc;
            hqInt_BatchFetchObjectBillingAccount bClass = new hqInt_BatchFetchObjectBillingAccount(1);

            Integer[]  itrbl = (Integer[])bClass.start(bc);  //start() returns an iterable, in my case, a custom iterable. 
            
            Integer[] aScopeList = new Integer[]{};
            aScopeList.add(0);
            bClass.execute(bc,aScopeList);

            // Finally, invoke finish()
            bClass.finish(bc);
            Test.stopTest();
    }

    @isTest 
    static void hqInt_TestMethodPhase2_Invoice() 
    {

            Test.startTest();

            //Test.setMock(HttpCalloutMock.class, myMultiMockObject); // setup of multiMockObject omitted for clarity
            Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
            Database.BatchableContext     bc;
            hqInt_BatchFetchObjectAcctingInvoice bClass = new hqInt_BatchFetchObjectAcctingInvoice(1);

            Integer[]  itrbl = (Integer[])bClass.start(bc);  //start() returns an iterable, in my case, a custom iterable. 
            
            Integer[] aScopeList = new Integer[]{};
            aScopeList.add(0);
            bClass.execute(bc,aScopeList);

            // Finally, invoke finish()
            bClass.finish(bc);
            Test.stopTest();
    }

    @isTest 
    static void hqInt_TestMethodManualRunController() 
    {

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
            hqInt_ManualRunController obj = new hqInt_ManualRunController();
            obj.runBatchJob();
            Test.StopTest();
    }

    @isTest 
    static void hqInt_TestMethodErrorLogger() 
    {

        hqInt_BatchErrorLogger.logError('abc','test error details','Actual Error Message','LIne no error in class');
    }
/**
    @isTest 
    static void hqInt_TestMethodManualRunController2() 
    {
	
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
        hqInt_ManualRunController obj = new hqInt_ManualRunController();
        obj.runBatchJobPhase2();
        Test.StopTest();
    
    }
    **/
	@isTest 
    static void hqInt_TestSubsAdjTrigger() 
    {
		Accounting_SubscriptionAdjustment__c obj = new Accounting_SubscriptionAdjustment__c();
		insert obj;
    
    }
    
}