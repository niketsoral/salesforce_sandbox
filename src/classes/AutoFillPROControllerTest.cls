@isTest(SeeAllData=true)
public class AutoFillPROControllerTest {
	static testMethod void Test1() {
        AutoFillPROController proObj=new AutoFillPROController();
        proObj.initAction();
        proObj.authenticate();
        proObj.getUnauthorizedReqToken();
        AutoFillPROController.getRandomNonce();
    }
}