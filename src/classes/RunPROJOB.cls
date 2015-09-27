public class RunPROJOB{
       public RunPROJOB(){
        
       }
       public pagereference runJob(){
           Id batchInstanceId = Database.executeBatch(new PROEmailRemindarBatch(), 200); 
           
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'PRO Email job is started.'));   
           return null;
       }
       public pagereference ClearData(){
           List<DContract__c> contractList=[select id,Name,Last_Report_Out_Date__c,Last_Report_Out_Status__c,Is_Snooze__c,Is_First_Nag_Sent__c,
                                       Snooze_Days__c,Snooze_Date__c,First_Nag_Sent_Date__c
                                     ,OwnerId,Owner.Name,Owner.Email 
                                     ,Backstop__c,Backstop__r.FirstName,Backstop__r.LastName,Backstop__r.Email 
                                     ,Project_Manager__c,Project_Manager__r.FirstName, Project_Manager__r.LastName,Project_Manager__r.Email
                                     ,Prime_Contracting_Business_Unit__c,Last_Report_Out_Created_Date__c 
                                     from DContract__c
                                     where Last_Report_Out_Date__c!=null and Requires_Report_Out__c='Yes' and
                                      Workflow_Escalation_Enabled__C=true];
                                      
            for(DContract__c contract : contractList){
                contract.Is_Snooze__c=false;
                contract.Snooze_Date__c=null;
                contract.Snooze_Days__c=null;
                contract.Is_First_Nag_Sent__c=false;
                contract.First_Nag_Sent_Date__c=null;
                contract.Second_Nag_Sent_Date__c=null;
                contract.Third_Nag_Sent_Date__c=null;
                contract.Fourth_Nag_Sent_Date__c=null;
             }
              
             update contractList;
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'PRO Data is cleared Successfullay'));   
           return null;
       }
}