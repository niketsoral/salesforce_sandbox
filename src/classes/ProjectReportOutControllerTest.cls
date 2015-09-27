@isTest(SeeAllData=true)
public class ProjectReportOutControllerTest {
    static testMethod void ProjectReportOutControllerTest1() {
        ProjectReportOutController proObj=new ProjectReportOutController();
        proObj.initAction();
        proObj.getProjectList2();
        proObj.getAllProjectList1();
        //proObj.getAllProjectList();
        List<ProjectReportOutController.PROProject> contractList= proObj.getAllProjectList1();
        proObj.contractIdName.put(contractList[0].contract.id,contractList[0].contract);
        proObj.contractId=contractList[0].contract.id;
        
        proObj.loadProjectReport();
        //Return false
        proObj.validData();
        
        proObj.status='Red';
        proObj.pro.PM_email__c='akanksha@gmail.com';
        proObj.pro.Report_Out_Date__c=Date.newInstance(2014, 12, 25);
        proObj.save();
        
        proObj.submitAnother();
        proObj.authenticateButton();
        
        List<selectoption> objList=proObj.StatusList;
        
        ProjectReportOutController.getRandomNonce();
    }
    static testMethod void ProjectReportOutControllerTest2() {
        ProjectReportOutController proObj=new ProjectReportOutController();
        List<ProjectReportOutController.PROProject> contractList= proObj.getAllProjectList1();
        proObj.selectedProjectId=contractList[0].contract.id;
        
        //proObj.selectedProjectId=contractList[0].id;
        proObj.FillProjectDetails();
        
        //Return False
        proObj.ValidateProject();
        
        proObj.saveProject();
        proObj.CurrentLoginEmail='aakansha@gmail.com';
        proObj.AddMe();
        List<Project_Report_Out__C> pastList= proObj.PastReportOuts;
        
        proObj.AddContact();
        proObj.RemoveContact();
        proObj.CurrentLoginEmail='ltse@dimagi.com';
        proObj.AddMe();
        
    }
}