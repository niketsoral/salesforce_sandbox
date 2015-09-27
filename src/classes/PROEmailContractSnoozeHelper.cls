public class PROEmailContractSnoozeHelper{
    
    public PROEmailContractSnoozeHelper(){
    
    }
    /*
        Snooze contratc to given days.
    */
    public void SnoozeContractByOwnerId(Id ownerId,integer snoozeDays){
    
        List<DContract__c> contractList=[select id from DContract__c 
        where Is_First_Nag_Sent__c=true
            and(
                (In_Charge_Of_Report_Out__c='Project Manager' and  Project_Manager__C=:ownerId) or 
                (In_Charge_Of_Report_Out__c='Field Manager' and  Field_Manager__C=:ownerId) or 
                (In_Charge_Of_Report_Out__c='Backstop' and  Backstop__C=:ownerId) 
            )
        ];
        if(contractList.size()>0){
           SnoozeContract(contractList,snoozeDays);
        }
    }
    public void SnoozeContract(Id contractId,integer snoozeDays){
        List<DContract__c> contractList=[select id from DContract__c where id=:contractId and Is_First_Nag_Sent__c=true];
        if(contractList.size()>0){
          SnoozeContract(contractList,snoozeDays);
        }
    }
    public void SnoozeContract(List<DContract__c> contracts,integer snoozeDays){
        
        for(DContract__c contract : contracts){
            contract.Is_Snooze__c=true;
            contract.Snooze_Date__c=Date.Today();
            contract.Snooze_Days__c=snoozeDays;
            contract.Is_First_Nag_Sent__c=false;
            contract.First_Nag_Sent_Date__c=null;
            contract.Second_Nag_Sent_Date__c=null;
            contract.Third_Nag_Sent_Date__c=null;
            contract.Fourth_Nag_Sent_Date__c=null;
        }
        
        update contracts;
    }
    
    /*
        Set First Nag Set when First nag is sent to Contract Owner.
    */
    public void SetFirstNegSent(List<DContract__c> contracts){
        
        for(DContract__c contract : contracts){
            contract.Is_Snooze__c=false;
            contract.Snooze_Date__c=null;
            contract.Snooze_Days__c=null;
            contract.Is_First_Nag_Sent__c=true;
            contract.First_Nag_Sent_Date__c=Date.Today();
        }
        update contracts;
    }
    
    public void SetSecondNegSent(List<DContract__c> contracts){
        
        for(DContract__c contract : contracts){
            contract.Second_Nag_Sent_Date__c=Date.Today();
        }
        update contracts;
    }
    public void SetThirdNegSent(List<DContract__c> contracts){
        
        for(DContract__c contract : contracts){
            contract.Third_Nag_Sent_Date__c=Date.Today();
        }
        update contracts;
    }
     public void SetFourthNegSent(List<DContract__c> contracts){
        
        for(DContract__c contract : contracts){
            contract.Fourth_Nag_Sent_Date__c=Date.Today();
        }
        update contracts;
    }
    
    /*
        Reset all email reminder fields of a contract.
        This method is used in PRO Page to reset all fields of contract when new PRO is created. 
    */
    public void ResetEmailRemindar(Id contractId){
        
        DContract__c contract=new DContract__c();
        contract.id=contractId;
        contract.Is_Snooze__c=false;
        contract.Snooze_Date__c=null;
        contract.Snooze_Days__c=null;
        contract.Is_First_Nag_Sent__c=false;
        contract.First_Nag_Sent_Date__c=null;
        contract.Second_Nag_Sent_Date__c=null;
        contract.Third_Nag_Sent_Date__c=null;
        contract.Fourth_Nag_Sent_Date__c=null;
        update contract;
    
    }
 
}