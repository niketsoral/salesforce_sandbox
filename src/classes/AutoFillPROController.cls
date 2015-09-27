public class AutoFillPROController{
    
    private String OAUTH_CALLBACK_URL='';
    private String clientId='';
    private String clientSecret='';
    private string domainName='';
    
    public String AUTH_URL = 'https://accounts.google.com/o/oauth2/auth';
    public String ACCESS_TOKEN_URL = 'https://accounts.google.com/o/oauth2/token';
    public Boolean isAuthenticated {get; set;}
    public string oauth_token {get;set;}
    
   
    public string PROMessage{
        get;set;
    }
    
    public string contractId{
        get;set;
    }
    public string noOfDaysStr{
        get;set;
    }
    public string ownerId{
        get;set;
    }
    public AutoFillPROController(){
        if(ApexPages.currentPage().getParameters().get('id')!=null){
            contractId=ApexPages.currentPage().getParameters().get('id');
        }
       
        List<PRO_OAuth_Settings__c> googleSettings=PRO_OAuth_Settings__c.getALL().values();
        if(googleSettings!=null && googleSettings.size()>0){
            clientId=googleSettings[0].ClientID__c;
            clientSecret=googleSettings[0].ClientSecret__c;
            domainName=googleSettings[0].Domain_Name__c;
            OAUTH_CALLBACK_URL=googleSettings[0].Auto_Fill_PRO_Callback_URL__C;
            
        }
        isAuthenticated = false;
    }
     public void initAction() {
           
           oauth_token = ApexPages.currentPage().getParameters().get('oauth_token');
           String oauth_verifier = ApexPages.currentPage().getParameters().get('oauth_verifier');
           string oauth_code = ApexPages.currentPage().getParameters().get('code');
           
           System.debug('Google Code: '+oauth_code);
           if(oauth_code!=null){
               oauth_token=getFromJSON(getAuthorizedReqToken(oauth_code),'access_token');
           }
           
           if(oauth_token!=null){
               isAuthenticated =true;
               AutoFillPRO();
           }
    }
    
    public PageReference authenticate() {
            PageReference authPage=null;
       
            oauth_token = ApexPages.currentPage().getParameters().get('oauth_token');
            String oauth_verifier = ApexPages.currentPage().getParameters().get('oauth_verifier');
            string oauth_code = ApexPages.currentPage().getParameters().get('code');
    
            if (oauth_code != null){
               oauth_token=getFromJSON(getAuthorizedReqToken(oauth_code),'access_token');
               if(oauth_token!=null){
                   isAuthenticated =true;
                   AutoFillPRO();  
               }
            }
            else{
                
                 String authURL = getUnauthorizedReqToken();
                 authPage=new PageReference(authURL);
                 authPage.setRedirect(false);
                 AutoFillPRO();  
            }
            return authPage;
        
    }
    public String getUnauthorizedReqToken(){
         
          String vf_url=this.OAUTH_CALLBACK_URL;
          String state = getRandomNonce(); //Random String
          String body='client_id='+this.clientId+'&redirect_uri='+this.OAUTH_CALLBACK_URL+'&state='+state;
          
          String retUrl=this.AUTH_URL+'?'+body+'&response_type=code&scope=profile+email';
          
          if(domainName!='gmail.com'){
              retUrl=retUrl+'&hd='+domainName;
          }
          
          //String retUrl=this.AUTH_URL+'?hd='+domainName+'&'+body+'&response_type=code&scope=profile+email';
          return retUrl;
    }
    public static String getRandomNonce(){
           String allChars='ABCDEFGHIJKLMNOPQRSTUVWXYZ';
           String nonce='';
           for(integer cnt=0; cnt<=9;cnt++)   {
               Integer i = 1+Math.Round(700.0*Math.random()/26);
               if (i<=26)
               {
                  i--;
                  String newStr=allChars.substring(i,i+1);
                  nonce=nonce+newStr;
              }else{
                cnt--;
              }
          }
          return nonce;
    }
    
    public String getAuthorizedReqToken(String code){
         
            String body='client_id='+this.clientId+'&redirect_uri='+this.OAUTH_CALLBACK_URL+'&client_secret='+this.clientSecret+'&code='+code+'&grant_type=authorization_code';
             
            String tokenResponse = basicAuthCallout(this.ACCESS_TOKEN_URL,'',body,'POST');
             
            System.debug('=========================== RESPONSE:'+tokenResponse);
             
            String authReqToken = tokenResponse;
            return authReqToken;
    }
   
    public String basicAuthCallout(String endPoint,String header, String body,String method){
            HttpRequest req = new HttpRequest();
          
            req.setEndpoint(endPoint);
            req.setMethod(method);
            if(method=='POST'){
                 req.setBody(body);
            }
            Http http = new Http();
            System.debug('=========== REQ BODY:'+endPoint);
            HTTPResponse res = http.send(req);
            return res.getBody();
     }
     public string getFromJSON(string response,string fieldName){
        JSONParser parser = JSON.createParser(response);
        
        string accessToken='';
        
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && 
                (parser.getText() == fieldName)) {
                parser.nextToken();
                accessToken= parser.getText();
            }
        }
        return accessToken;
     }
    
    
    public void AutoFillPRO(){
        //try{
           
            if(contractId!=null){
               List<Project_Report_Out__c> prlist = new list<Project_Report_Out__c>(
                    [select id ,PM_email__c,Cap_planning_GDoc__c,Key_Accomplishments_Last_Two_Weeks__c,
                    Key_Next_Steps_next_2_weeks__c,Client_Facing__c,Requires_Developer_Work__c,Ability_to_meet_Schedule__c,
                    Ability_to_stay_within_Scope__c,Current_System_Usage__c,Partner_Relationship__c,
                    Issues_Questions_Notables__c,Resource_Planning__c,Contract__r.Requires_Developer_Work__c,Status__C,
                    Project_Dashboard__c,Contract__R.Name,Report_Out_Date__c from Project_Report_Out__c
                    where Contract__c =: contractid order by Report_Out_Date__c  desc limit 1]);
               
                if(!prlist.isempty()){
                    //Auto Fill Next PRO
                    Project_Report_Out__c nextPro=new Project_Report_Out__c();
                    nextPro.Contract__c =contractid;
                    
                    nextPro.Report_Out_Date__c = Date.today();//GetNextPRODueDate(prlist[0].Report_Out_Date__c.addDays(1));
                    nextPro.Key_Accomplishments_Last_Two_Weeks__c= prlist[0].Key_Accomplishments_Last_Two_Weeks__c;
                    nextPro.Key_Next_Steps_next_2_weeks__c= prlist[0].Key_Next_Steps_next_2_weeks__c;
                    nextPro.Issues_Questions_Notables__c = prlist[0].Issues_Questions_Notables__c;
                    nextPro.Client_Facing__c = prlist[0].Client_Facing__c;
                    nextPro.Requires_Developer_Work__c = prlist[0].Requires_Developer_Work__c;
                    nextPro.Status__C=prlist[0].Status__C;
                    nextPro.Project_Dashboard__c = prlist[0].Project_Dashboard__c;
                    nextPro.Resource_Planning__c = prlist[0].Resource_Planning__c ;
                    nextPro.Cap_planning_GDoc__c = prlist[0].Cap_planning_GDoc__c;
                    nextPro.Ability_to_meet_Schedule__c=prlist[0].Ability_to_meet_Schedule__c;
                    nextPro.Ability_to_stay_within_Scope__c=prlist[0].Ability_to_stay_within_Scope__c;
                    nextPro.Current_System_Usage__c=prlist[0].Current_System_Usage__c;
                    nextPro.Partner_Relationship__c=prlist[0].Partner_Relationship__c;
                    nextPro.No_Change_From_Last_Time__C=true;
                    
                    nextPro.Name = prlist[0].Contract__r.Name + ' - [' + nextPro.Report_Out_Date__c.format() + ']';
                    nextPro.Last_Report_ID__C=prlist[0].id;
                    
                    insert nextPro;
                    
                    
                    PROEmailContractSnoozeHelper snoozeHelper=new PROEmailContractSnoozeHelper();
                    snoozeHelper.ResetEmailRemindar(contractId);
                    SendEmail(nextPro.id);
                    
                }
            
                 PROMessage='Your PRO snoozed successfully.';
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Your PRO snoozed successfully.'));   
           
            }
            
        //}
        //catch(Exception ex){
        
        //}
        
    }
    public Date GetNextPRODueDate(date currentDate){
        
        Date latestPRODueDate=null;
        
        integer currentMonth=currentDate.month();
        integer currentYear=currentDate.year();
        
        List<Date> currentMonthThursDayList=PROHelper.GetAllThursDayOfMonth(currentYear,currentMonth);
        
      
        if(currentDate>=currentMonthThursDayList[3]){
        
             Date nextMonthDate=currentDate.addMonths(1);
             integer nextMonth=nextMonthDate.month();
             integer nextYear=nextMonthDate.year();
             //Get Next Month Thursday.
             List<Date> NextMonthThursDayList=PROHelper.GetAllThursDayOfMonth(nextYear,nextMonth);
             
             return NextMonthThursDayList[1];
             
        }
        else{
            if(currentDate<currentMonthThursDayList[1]){
                    latestPRODueDate=currentMonthThursDayList[1];
            }else{
                latestPRODueDate=currentMonthThursDayList[3];
            }
        }
        return latestPRODueDate;
    }
    
    
    public void SendEmail(string PROID){
         Id templateId=[select id from EmailTemplate where DeveloperName='Project_Report_Out_VF' limit 1].id;
         List<Contact> contactList=new List<Contact>();
         OrgWideEmailAddress orgWideAddress= [select Id from OrgWideEmailAddress where 
                                              Address = 'dimagi-salesforce@dimagi.com' limit 1];

         List<Contract_Contact__c> contractContactList= [select id,Contact__C,Email__C,Type__c,Contact__r.Email,Contact__r.Name,Contract__C from 
                                                             Contract_Contact__c 
                                                        where Contract__C=:contractid];
         List<string> emailList=new List<string>();
         for(Contract_Contact__c conContact:contractContactList){
             if(conContact.Type__C!='Email'){
                 contactList.add(conContact.Contact__r);
             }
             else{
                 emailList.add(conContact.Email__C);
             }
         }
         
         for(Contact con:contactList){
             if(con!=null && con.Email!=null){
                 emailList.add(con.Email);
             }
         }
         if(contactList.size()>0){
             Messaging.SingleEmailMessage msg=new Messaging.SingleEmailMessage();
             msg.setTemplateId(templateId);
             msg.setTargetObjectId(contactList[0].Id);
             msg.setToAddresses(emailList);
             msg.setWhatId(PROID);
             msg.setSaveAsActivity(false);
             msg.setOrgWideEmailAddressId(orgWideAddress.id);
             Messaging.sendEmail(new Messaging.SingleEmailMessage[]{msg} );
         }
     }
    

}