/*
    Test class for Employee insert update trigger
*/
@isTest
public class EmployeeInsertUpdateTriggerTest {
    
    static testMethod void mapEmployeeContactTest(){
        
        //Create Account
        Account acc = new Account();
        acc.Name = 'Test dimagi';
        insert acc;
        
        //Create Contact
        Contact contact = new Contact();        
        contact.AccountId = acc.Id;
        contact.Title = 'Test Title';
        contact.MobilePhone = '9856254175';
        contact.Department = 'Account';
        contact.FirstName = 'Test';
        contact.LastName = 'Contact';       
        insert contact;
        
        //Create Employee
        SFDC_Employee__c emp = new SFDC_Employee__c();
        emp.Name = 'Test employee';
        emp.Contact__c = contact.Id;
        
        Test.startTest();
        
        insert emp;
        
        List<SFDC_Employee__c> employees = [Select Id, Title__c, Emergency_Contact_Phone__c, Sub_Unit__c, Field_Location__c 
                                            ,Country__c
                                            From SFDC_Employee__c where Id =:emp.Id];
                                            
        List<Contact> contacts = [Select Id, Title, MobilePhone From Contact where Id = :contact.Id];  
        
        System.assertNotEquals(employees, null);
        System.assertNotEquals(contacts, null);
        
        if(employees != null && !employees.isEmpty()){
            if(contacts != null && !contacts.isEmpty()){
                System.assertEquals(employees[0].Title__c, contacts[0].Title);              
            }
        }                                       
        
        Test.stopTest();
        
        emp.Skype_ID__c='1234';
        update emp;
        
        CheckRecursive.firstRun=true;
        contact.Skype__c='ABC_Test';
        contact.Department='Test HR';
        contact.Title='ABC';
        update contact;
        
        //System.assertEquals(emp.Title__c, contact.Title); 
        
    } 
    
}