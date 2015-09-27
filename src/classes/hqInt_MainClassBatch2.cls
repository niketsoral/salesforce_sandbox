public class hqInt_MainClassBatch2 implements Database.Batchable<Integer>,Database.AllowsCallouts,Database.Stateful
{

    Integer apiLimitParameter = Integer.valueOf(CommcareToSalesforceSettings__c.getInstance('ApiLimitParameter').Value__c);
    Integer successfullyLoadedRecords = 0;

    public Iterable<Integer> start(Database.BatchableContext BC) 
    {
        integer totalCount;
        integer totalBatches;

        try
        {
            hqInt_MainClass obj = new hqInt_MainClass();
            HTTPResponse res = obj.requestMethod(1,0);
            JSONParser parser = JSON.createParser(res.getBody());
            while (parser.nextToken() != null) 
    		{
            	if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'total_count') 
                {
                    parser.nextToken();
                    totalCount = parser.getIntegerValue();
                    break;
                }
            }

        }
        catch(exception e)
        {
            if(e.getMessage().contains('Read timed out'))
            {
                system.abortJob(BC.getJobId());
                Database.executeBatch(new hqInt_MainClassBatch2(),1);
            }
        }

        list <Integer> listOffset = new list <Integer>();
        
        for(integer i=0;i <= totalCount/apiLimitParameter ; i++)
          listOffset.add(i*apiLimitParameter);     

          

        system.debug('---listoffset---'+listoffset);       
        
        return listOffset;
    }

    public void execute(Database.BatchableContext info, List<Integer> offsetList) 
    {
        
        try
        {
        	hqInt_MainClass2 obj = new hqInt_MainClass2();
            obj.mainMethod(offsetList[0]);
            successfullyLoadedRecords += apiLimitParameter;
		}
        catch(exception e)
        {
            system.debug('Error has occured'+e.getMessage());
            
            Batch_Error_Logs__c batchError = new Batch_Error_Logs__c();
            batchError.Batch_Id__c = info.getJobId();
            batchError.Details__c= '\n failed at offset with limit param '+ apiLimitParameter +' : '+ string.valueOf(offsetList[0]);
            batchError.Error_Message__c = e.getMessage();
            batchError.Stack_Trace_String__c = e.getStackTraceString();
            insert batchError;
        } 
        
    }

    public void finish(Database.BatchableContext info) 
    {
        
        String subject = 'CommCare Salesforce Job Run Report - Invoice Object';
        String emailBody = 'Total Successfully loaded Invoice records = ' + successfullyLoadedRecords + '\n\n';
        
        hqInt_BatchErrorLogger.sendErrorEmails(info.getJobId(),subject,emailBody);
    }
}