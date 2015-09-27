public class ContactTriggerHelper{

    public static void UpdateEmployee(List<Contact> contactList) {
        
        if(CheckRecursive.firstRun){
        
        //System.debug('Update EMP Fire');
        CheckRecursive.firstrun=false;
        
            List<SFDC_Employee__c> empList=[select id,Contact__c,Email_Address__c from SFDC_Employee__c where Contact__c=:contactList];
            
            Map<id,SFDC_Employee__c> contactEmployeeMap=new Map<id,SFDC_Employee__c>();
            
            for(SFDC_Employee__c emp:empList){
               
               if(!contactEmployeeMap.containsKey(emp.Contact__c)){
                   contactEmployeeMap.put(emp.Contact__c,emp);
               }
               
            }
            
            Set<id> accountIds=new Set<id>();
            Set<id> reportToIds=new Set<id>();
           
            for(Contact con:contactList){
                accountIds.add(con.accountid);
                reportToIds.add(con.ReportsToId);
            }
        
        
        Map<id,Account> accountMap=new Map<id,Account>([select id, name from account where id=:accountIds]);
        //Map<id,Contact> reportToMap=new Map<id,Contact>([select id, name from Contact where id=:reportToIds]);
        
        List<SFDC_Employee__c> reportTOEmpList=[select id,Contact__c from SFDC_Employee__c where Contact__c=:reportToIds];
        map<Id,id> reportTOEmpMap=new map<Id,id>();
        for(SFDC_Employee__c emp:reportTOEmpList){
            if(!reportTOEmpMap.containsKey(emp.Contact__c)){
              reportTOEmpMap.put(emp.Contact__c,emp.id);
            }
        }      
                
                
                
        List<SFDC_Employee__c> updateEmpList=new List<SFDC_Employee__c>();
        
        for(Contact con :contactList){
            if(contactEmployeeMap.containsKey(con.id)){
                     SFDC_Employee__c updateEmp=contactEmployeeMap.get(con.id);
                  
                      System.debug('Update EMP Fire: '+updateEmp.id);
                      Account acc=accountMap.get(con.AccountId);
                      string empName='';
                      if(con.FirstName==null){
                          empName=con.LastName;
                      }
                      else{
                          empName=con.FirstName+' '+con.LastName;
                      }
                      
                      updateEmp.Name =empName; //con.FirstName != Null ? con.FirstName : '' + ' '+con.LastName!= Null ? con.LastName: '';
                      if(acc!=null){
                          updateEmp.Entity__c = acc.Name;   
                      }
                      
                      updateEmp.Country__c=con.Country__c;
                      updateEmp.Sub_Unit__c = con.Department;
                      updateEmp.Skype_ID__c = con.Skype__c;
                      updateEmp.Email_Address__c = con.Email;     
                      updateEmp.Title__c = con.Title; 
                      
                      if(con.ReportsToId!=null){
                          updateEmp.Direct_Manager_Lookup__c= reportTOEmpMap.get(con.ReportsToId);  
                      }
                      else{
                          updateEmp.Direct_Manager_Lookup__c=null;
                          
                      }
                      updateEmpList.add(updateEmp);  
            }
            
        }
        if(updateEmpList.size()>0){
            update updateEmpList;
        }
          
        }
    }
}