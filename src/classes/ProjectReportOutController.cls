/**
 * This class provides functionality to Dimagi Project Report Outs Site.
 *
 * @author Virginia Fernández
 * @modifiedBy Nick Nestle - nnestle@dimagi.com
 * @modifiedBy Pablo Vigil - pablo.vigil@roundfusion.com
 * @since 2014-05
 */
public with sharing class ProjectReportOutController{
    
    private String OAUTH_CALLBACK_URL='';
    private String clientId='';
    private String clientSecret='';
    private string domainName='';
    
    public String AUTH_URL = 'https://accounts.google.com/o/oauth2/auth';
    public String ACCESS_TOKEN_URL = 'https://accounts.google.com/o/oauth2/token';
    
    PROEmailContractSnoozeHelper snoozeHelper=new PROEmailContractSnoozeHelper();
    
    string currentLoginUser='';
    public string CurrentLoginEmail{
        get;set;
    }
    public Map<Id, DContract__C> contractIdName = new Map<Id, DContract__C> {};

    public String dateAlert {get; set;}
    public Project_Report_Out__c pro {get; set;}
    public String contractId {get; set;}
    public Boolean showDevWork {get; set;}

    public Boolean isAuthenticated {get; set;}
    public String password {get; set;}
       
    //public String oauth_code {get;set;}
    public string oauth_token {get;set;}
    public string LastProjectId{
        get;set;
    }
    public string ProjectId{
        get;set;
    }
    public string SelectedTab{
        get;set;
    }
    
    Map<string,integer> frequencyMap=new Map<string,integer>();
    
    public ProjectReportOutController() {
           
            List<PRO_OAuth_Settings__c> googleSettings=PRO_OAuth_Settings__c.getALL().values();
            if(googleSettings!=null && googleSettings.size()>0){
                clientId=googleSettings[0].ClientID__c;
                clientSecret=googleSettings[0].ClientSecret__c;
                domainName=googleSettings[0].Domain_Name__c;
                OAUTH_CALLBACK_URL=googleSettings[0].Auth_Callback_URL__c;
            }
            
            List<PRO_Frequency_Settings__C> proSettings=PRO_Frequency_Settings__C.getAll().values();
            for(PRO_Frequency_Settings__C proSet : proSettings){
                frequencyMap.put(proSet.Name,Integer.valueOf(proSet.Frequency_In_Week__C));
            }
            
            if(ApexPages.currentPage().getParameters().get('state')!=null){
                ProjectId=ApexPages.currentPage().getParameters().get('state');
            }

            if(ProjectId!=null){
                 SelectedTab='projectTab';
            }
            else{
                SelectedTab='reportTab';
            }
           
       
        
        isAuthenticated = false;
        showDevWork = false;
    }  
   

    // What to do initially.
    public void initAction() {
           
           oauth_token = ApexPages.currentPage().getParameters().get('oauth_token');
           String oauth_verifier = ApexPages.currentPage().getParameters().get('oauth_verifier');
           string oauth_code = ApexPages.currentPage().getParameters().get('code');
           
           System.debug('Google Code: '+oauth_code);
           
           
           
           if(oauth_code!=null){
               oauth_token=getFromJSON(getAuthorizedReqToken(oauth_code),'access_token');
           }
           
           if(oauth_token!=null){
               string message=callForUserInfo(oauth_token);
               if(message!=''){
                   isAuthenticated =true;
                   
                   currentLoginUser=message;
               }
           }
    }
            
    public void loadProjectReport(){
        pro=new Project_Report_Out__c();
        List<Project_Report_Out__c> prlist = new list<Project_Report_Out__c>(
        [select id ,PM_email__c,Cap_planning_GDoc__c,Key_Accomplishments_Last_Two_Weeks__c,
        Key_Next_Steps_next_2_weeks__c,Client_Facing__c,Requires_Developer_Work__c,Ability_to_meet_Schedule__c,
        Ability_to_stay_within_Scope__c,Current_System_Usage__c,Partner_Relationship__c,
        Issues_Questions_Notables__c,Resource_Planning__c,Contract__r.Requires_Developer_Work__c,
        Project_Dashboard__c from Project_Report_Out__c
        where Contract__c =: contractid order by lastmodifieddate desc limit 1]);
        
        pro.PM_email__c = CurrentLoginEmail;
        
        if(!prlist.isempty()){
            lastProjectId=prlist[0].id;
            
            pro.Report_Out_Date__c = system.today();
            pro.Key_Accomplishments_Last_Two_Weeks__c= prlist[0].Key_Accomplishments_Last_Two_Weeks__c;
            pro.Key_Next_Steps_next_2_weeks__c= prlist[0].Key_Next_Steps_next_2_weeks__c;
            pro.Issues_Questions_Notables__c = prlist[0].Issues_Questions_Notables__c;
            pro.Client_Facing__c = prlist[0].Client_Facing__c;
            pro.Requires_Developer_Work__c = prlist[0].Requires_Developer_Work__c;
            showDevWork = prlist[0].Contract__r.Requires_Developer_Work__c;
            pro.Project_Dashboard__c = prlist[0].Project_Dashboard__c;
            pro.Resource_Planning__c = '----';
            pro.Cap_planning_GDoc__c = prlist[0].Cap_planning_GDoc__c;
            ToMeetSchedule=prlist[0].Ability_to_meet_Schedule__c;
            StayWithinScope=prlist[0].Ability_to_stay_within_Scope__c;
            CurrentSystemUsage=prlist[0].Current_System_Usage__c;
            PartnerRelationship=prlist[0].Partner_Relationship__c;
        }
        else{
            DContract__c contractObj=[select id,Requires_Developer_Work__c from DContract__c 
            where Id=:contractid limit 1];
            
            lastProjectId=null;
            pro.Report_Out_Date__c = system.today();
            pro.Key_Accomplishments_Last_Two_Weeks__c= null;
            pro.Key_Next_Steps_next_2_weeks__c= null;
            pro.Issues_Questions_Notables__c = null;
            pro.Client_Facing__c = null;
            pro.Requires_Developer_Work__c = null;
            showDevWork = contractObj.Requires_Developer_Work__c;
            pro.Project_Dashboard__c = null;
            pro.Resource_Planning__c = '----';
            pro.Cap_planning_GDoc__c = null;
            ToMeetSchedule=null;
            StayWithinScope=null;
            CurrentSystemUsage=null;
            PartnerRelationship=null;
        
        }
        
    }

    public List<PROProject> getProjectList2(){
        List<PROProject> proList=new List<PROProject>();
        DContract__c[] contracts = [SELECT Id, Name, Requires_Developer_Work__c,Last_Report_Out_Date__c,Last_Report_Out_Status__c
                                           FROM DContract__c 
                                           WHERE Requires_Report_Out__c = 'Yes' and(
                                                (In_Charge_Of_Report_Out__c='Project Manager' and  Project_Manager__r.Email=:CurrentLoginEmail) or 
                                                (In_Charge_Of_Report_Out__c='Field Manager' and  Field_Manager__r.Email=:CurrentLoginEmail) or 
                                                (In_Charge_Of_Report_Out__c='Backstop' and  Backstop__r.Email=:CurrentLoginEmail) 
                                                or Owner.Email=:CurrentLoginEmail
                                            )
                                       ORDER BY Name];
                                       
        if(contracts.size()>0 && contractid==null){
            contractid= contracts[0].id;
            loadProjectReport();
        }
                                         
        for(DContract__c dc:contracts){
            contractIdName.put(dc.Id, dc);
            PROProject prObj=new PROProject();
            prObj.Contract=dc;
            if(contractId!=null && contractId!=''){
                prObj.cssClass=dc.id==contractId?'bgColorCls':'';
            }
            proList.add(prObj);
        }
        return proList;
    }
    public List<PROProject> getAllProjectList1(){
        List<PROProject> proList=new List<PROProject>();
        DContract__c[] contracts = [SELECT Id, Name, Requires_Developer_Work__c,Last_Report_Out_Date__c,Last_Report_Out_Status__c
                                           FROM DContract__c 
                                           WHERE Requires_Report_Out__c = 'Yes'
                                           ORDER BY Name];
        if(contracts.size()>0 && selectedProjectId==null){
            if(ProjectId!=null){
                selectedProjectId=ProjectId;
            }
            else{
                selectedProjectId= contracts[0].id;
            }
            FillProjectDetails();
        }
        for(DContract__c dc:contracts){
            PROProject prObj=new PROProject();
            prObj.Contract=dc;
            if(selectedProjectId!=null && selectedProjectId!=''){
                prObj.cssClass=dc.id==selectedProjectId?'bgColorCls':'';
            }
            proList.add(prObj);
        }
        return proList;                                  
    }
    
    /**
     * Checks if the date entered is the second or fourth thursday.
     * @return True if the date format it's right, false otherwise.
     */
    public boolean validData() {
        // Check if user has selected one project.
        if (contractId == null || contractId == '') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You must select a project.'));
            return false;
        }
        if (status== null || status== '') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Status cannot be blank'));
            return false;
        }
        
        if (pro.PM_email__c == null || pro.PM_email__c == '') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Email cannot be blank'));
            return false;
        }
        if (pro.Report_Out_Date__c == null ) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Report out Date cannot be blank'));
            return false;
        }
        return true;
        /*else{ 
            DContract__C contract=contractIdName.get(contractId);
            string lastStatus=contract.Last_Report_Out_Status__c;
            
            integer noOfWeeks=frequencyMap.get(lastStatus);
            
            //For New Project Last PRO Status is null then we set 2 weeks;
            if(noOfWeeks==null){
                noOfWeeks=2;
            }
            List<Date> thudayList=PROHelper.GetAllThursDayOfMonth(pro.Report_Out_Date__c.Year(),pro.Report_Out_Date__c.Month());
            
            if(noOfWeeks==4){
                 if(thudayList[3]==pro.Report_Out_Date__c){
                     return true;
                 }
                 else{
                     ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'You must select the fourth Thursday of the month.'));
                     return false;
                 }
            }
            else if(noOfWeeks==3){
                 if(thudayList[2]==pro.Report_Out_Date__c){
                     return true;
                 }
                 else{
                     ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'You must select the third Thursday of the month.'));
                     return false;
                 }
            }
            else if(noOfWeeks==2){
                 if(thudayList[1]==pro.Report_Out_Date__c || thudayList[3]==pro.Report_Out_Date__c){
                     return true;
                 }
                 else{
                     ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'You must select the second or forth Thursday of the month.'));
                     return false;
                 }
            }
            else if(noOfWeeks==1){
                 for(Date dt : thudayList){
                     if(dt==pro.Report_Out_Date__c){
                         return true;
                     }
                 }
                 
                 ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'You must select the Thursday of the month.'));
                 return false;
            }
           return false;
        }*/
    }

    // Alert that the day is wrong.
    private void alertInvalidDate() {
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'You must select the second or fourth Thursday of the month.'));
    }

    // What to do when submit is clicked.
    public PageReference save() {
        PageReference page = null;

        // Check all required fields are set, otherwise returns an error message.
        if (validData()) {
            pro.Contract__c = contractId;
            pro.Name = contractIdName.get(pro.Contract__c).Name + ' - [' + pro.Report_Out_Date__c.format() + ']';
            pro.status__C=status;
            pro.Ability_to_meet_Schedule__c= ToMeetSchedule;
            pro.Ability_to_stay_within_Scope__c=StayWithinScope;
            pro.Current_System_Usage__c=CurrentSystemUsage;
            pro.Partner_Relationship__c=PartnerRelationship;
            pro.User_Name__C=currentLoginUser;
            pro.Last_Report_ID__C=lastProjectId;
            
            DContract__c dcontract=new DContract__c();
            dcontract.id=contractId;
            dcontract.Last_Report_Out_Status__c=status;
            
            try
            {
                snoozeHelper.ResetEmailRemindar(contractId);
                
                insert pro;
                
                SendEmail(pro.id);
                update dcontract;
                page = new PageReference('/apex/ProjectReportOutSubmitted');
                
               
            } 
            catch(DmlException ex){
                 ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getDmlMessage(0)));
            }
            catch (Exception e) {
                System.debug(e);
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'There was an error trying to save. Please try again.'));
                //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,e.getMessage()));
            }
        }
        return page;
    }

    public PageReference submitAnother() {
        pro = new Project_Report_Out__c();
        DeleteContactList.clear();
        loadProjectReport();
        
        PageReference newPage = new PageReference('/apex/ProjectReportOut');
        newPage.getParameters().put('oauth_token',oauth_token);
        newPage.setRedirect(true);
        return newPage ;
    }
    public PageReference authenticateButton() {
        Misc_Settings__c settings = Misc_Settings__c.getOrgDefaults();
        if (password == settings.Project_Report_Out_Password__c) {
            isAuthenticated =true;
        }
        else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Wrong password.'));
        }
        return null;
    }

    public PageReference authenticate() {
           PageReference authPage=null;

            oauth_token = ApexPages.currentPage().getParameters().get('oauth_token');
            String oauth_verifier = ApexPages.currentPage().getParameters().get('oauth_verifier');
            string oauth_code = ApexPages.currentPage().getParameters().get('code');
    
            if (oauth_code != null){
               oauth_token=getFromJSON(getAuthorizedReqToken(oauth_code),'access_token');
               
               string message=callForUserInfo(oauth_token);
               System.debug('message: '+message);
               if(message!=''){
                   isAuthenticated =true;
                   currentLoginUser=message;
               }
            }
            else{
                 
                 String authURL = getUnauthorizedReqToken();
                 authPage=new PageReference(authURL);
                 authPage.setRedirect(false);
                 
            }
            return authPage;
        
    }
   
     // Get a list of picklist values from an existing object field.
    private List<SelectOption> getPicklistValues(SObject obj, String fieldName)
    {
      List<SelectOption> options = new list<SelectOption>();
      Schema.sObjectType objType = obj.getSObjectType(); 
      // Describe the SObject using its object type.
      Schema.DescribeSObjectResult objDescribe = objType.getDescribe();       
      // Get a map of fields for the SObject
      map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap(); 
      // Get the list of picklist values for this field.
      list<Schema.PicklistEntry> values =fieldMap.get(fieldName).getDescribe().getPickListValues();
      // Add these values to the selectoption list.
      
      for (Schema.PicklistEntry a : values)
      { 
         options.add(new SelectOption(a.getValue(),'')); 
      }
      options.add(new SelectOption('N/A',''));
      return options;
    }
    public List<selectoption> StatusList{
           get{
              return getPicklistValues(new Project_Report_Out__c(),'Status__c');
           }
           set;
    }
    public string status{
        get;set;
    }
    public string ToMeetSchedule{
         get;set;
    }
    public string StayWithinScope{
         get;set;
    }
    public string CurrentSystemUsage{
         get;set;
    }
    /*public string CustomReportsDevelopment{
        get;set;
    }*/
    public string PartnerRelationship{
        get;set;
    }
    
     public String getUnauthorizedReqToken(){
         
          String vf_url=this.OAUTH_CALLBACK_URL;
          String state = projectId; //Random String
          String body='client_id='+this.clientId+'&redirect_uri='+this.OAUTH_CALLBACK_URL+'&state='+state;
         
          String retUrl=this.AUTH_URL+'?'+body+'&response_type=code&scope=profile+email';
          
          if(domainName!='gmail.com'){
              retUrl=retUrl+'&hd='+domainName;
          }
          
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
    public string callForUserInfo(string token){
        string userInfoURL='https://www.googleapis.com/oauth2/v1/userinfo?access_token='+token;
        string responseJSON=basicAuthCallout(userInfoURL,'','','GET');
        string response=getFromJSON(responseJSON,'name');
        
        CurrentLoginEmail=getFromJSON(responseJSON,'email');
        
        return response;
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
     

     public List<Project_Report_Out__c> PastReportOuts{
         get{
              List<Project_Report_Out__c> lastReportOuts=[select id,status__c,Contract__r.Name,Contract__r.Last_Report_Out_Date__c from Project_Report_Out__c 
              where PM_email__c=:CurrentLoginEmail order by Contract__r.Name,Contract__r.Last_Report_Out_Date__c desc ];
              return lastReportOuts;
         }
         set;
     }
     
     
     public string selectedProjectId{get;set;}
     public string InChangeOfReportOut{get;set;}
     public string ProjectManager{get;set;}
     public string FieldManager{get;set;}
     public string Backstop{get;set;}
     public DContract__c Project{
         get;set;
     }
     public boolean EnableAddButton{
         get;set;
     }
     
     //When project is changed this method is called.
     public void FillProjectDetails(){
         DeleteContactList.clear();
         ContractContacts=new List<Contract_Contact__c>();
         
         List<DContract__c> contractList=[select id,Project_Manager__c,Backstop__c,Field_Manager__c,In_Charge_Of_Report_Out__c from DContract__c 
         where Id=:selectedProjectId];
         if(contractList!=null && contractList.size()>0){
             Project=contractList[0];
         }
         ContractContactsProject=[select id,Contact__C,Contract__C,Type__C,Email__C from Contract_Contact__c where Contract__C=:selectedProjectId and Type__C not in('Person','Email')];
         
         ContractContacts=[select id,Contact__C,Contract__C,Type__C,Email__C  from Contract_Contact__c where Contract__C=:selectedProjectId and Type__C in('Person','Email') order by Type__C desc];
         
         //Fill Last Report outs of project   
         LastRepotOuts=[select id,Name,status__c,Contract__r.Name,Contract__r.Last_Report_Out_Date__c,Report_Out_Date__c  from Project_Report_Out__c 
         where Contract__C=:selectedProjectId order by Report_Out_Date__c desc ];
         EnableAddButton=true;
     }
     public List<Project_Report_Out__c> LastRepotOuts{
         get;set;
     }
     
     public PageReference saveProjectOnly(){
         PageReference page = null;
         
         if(ValidateProject()){
             try{
                 update Project;
             }
             catch(DmlException ex){
                 ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getDmlMessage(0)));
             }
             catch (Exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,e.getMessage()));
             }
             ContractContactsProject=[select id,Contact__C,Contract__C,Type__C from Contract_Contact__c 
                     where Contract__C=:selectedProjectId and Type__C not in('Person','Email')];
         }
         return page;
     }
     
     public PageReference saveProject(){
         PageReference page = null;
         
         page=saveProjectOnly();
         SaveContact();
         
         return page;
         
     }
     
     List<Contract_Contact__c> DeleteContactList=new List<Contract_Contact__c>();
     
     public void SaveContact(){
         /*string PMId=null;
         if(Project.Project_Manager__c!=null){
             PMId=Project.Project_Manager__c;
         }
         
         string FMId=null;
         if(Project.Field_Manager__c!=null){
             FMId=Project.Field_Manager__c;
         }
         
         string BTId=null;
         if(Project.Backstop__c!=null){
             BTId=Project.Backstop__c;
         }
         
         boolean PMFound=false,FMFound=false,BTFound=false;
         
         for(Contract_Contact__c contContact : ContractContacts){
            if(contContact.Type__C=='Project Manager'){
                contContact.Contact__C=PMId;
                PMFound=true;
            }
            else if(contContact.Type__C=='Field Manager'){
                contContact.Contact__C=FMId;
                FMFound=true;
            }
            else if(contContact.Type__C=='Backstop'){
                contContact.Contact__C=BTId;
                BTFound=true;
            }
        }
        if(PMId!=null && !PMFound){
             Contract_Contact__c contractContact=new Contract_Contact__c();
             contractContact.Contract__c=selectedProjectId;
             contractContact.Contact__C=PMId;
             contractContact.Type__C='Project Manager';
             ContractContacts.add(contractContact);
        }
        if(FMId!=null && !FMFound){
             Contract_Contact__c contractContact=new Contract_Contact__c();
             contractContact.Contract__c=selectedProjectId;
             contractContact.Contact__C=FMId;
             contractContact.Type__C='Field Manager';
             ContractContacts.add(contractContact);
        }
        if(BTId!=null && !BTFound){
             Contract_Contact__c contractContact=new Contract_Contact__c();
             contractContact.Contract__c=selectedProjectId;
             contractContact.Contact__C=BTId;
             contractContact.Type__C='Backstop';
             ContractContacts.add(contractContact);
        }*/
        
        List<integer>removeIndex=new List<integer>();
        if(ContractContacts!=null){
            for(integer index=0;index<ContractContacts.size();index++){
                Contract_Contact__c contContact=ContractContacts[index];
                if(contContact.Contact__C!=null || contContact.Email__C!=null){
                     upsert contContact;
                }
                else{
                    if(contContact.Id!=null){
                        removeIndex.add(index);
                        delete contContact;
                    }
                }
            }
        }
        for(integer index=0;index<removeIndex.size();index++){
            ContractContacts.remove(removeIndex[index]);
        }
        
        if(DeleteContactList.size()>0){
            delete DeleteContactList;
            DeleteContactList.clear();
        }
        
     }
     public boolean ValidateProject(){
         
        if (selectedProjectId == null || selectedProjectId == '') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You must select a project.'));
            return false;
        }
        return true;
     
     }
     public ID RemoveContactId{
         get;set;
     }
     public void RemoveContact(){
          if(ContractContacts.size()>0){
             integer removeIndex=-1;
             for(integer index=0;index<ContractContacts.size();index++){
                 Contract_Contact__c ct=ContractContacts[index];
                 if(ct.Contact__c==RemoveContactId ){
                     if(ct.id!=null){
                          DeleteContactList.add(ct);
                     }
                     removeIndex=index;
                     break;
                 }
             }
             if(removeIndex==-1){
                 for(integer index=0;index<ContractContacts.size();index++){
                     Contract_Contact__c ct=ContractContacts[index];
                     if(ct.Type__C=='Person' && ct.Contact__c==null){
                         removeIndex=index;
                         break;
                     }
                 }
             }
             
             if(removeIndex!=-1){
                 ContractContacts.remove(removeIndex);
             }
         }
     }
     public string RemoveEmailId{
         get;set;
     }
     public void RemoveEmail(){
          if(ContractContacts.size()>0){
             integer removeIndex=-1;
             for(integer index=0;index<ContractContacts.size();index++){
                 Contract_Contact__c ct=ContractContacts[index];
                 if(ct.Email__C==RemoveEmailId){
                     if(ct.id!=null){
                          DeleteContactList.add(ct);
                     }
                     removeIndex=index;
                     break;
                 }
             }
             if(removeIndex==-1){
                 for(integer index=0;index<ContractContacts.size();index++){
                     Contract_Contact__c ct=ContractContacts[index];
                     if(ct.Type__C=='Email' && ct.Email__C==null){
                         removeIndex=index;
                         break;
                     }
                 }
             }
             
             if(removeIndex!=-1){
                 ContractContacts.remove(removeIndex);
             }
         }
     }
     
     public void AddContact(){
         Contract_Contact__c contractContact=new Contract_Contact__c();
         contractContact.Contract__c=selectedProjectId;
         contractContact.Type__C='Person';
         ContractContacts.add(contractContact);
     }
     public void AddEmail(){
         Contract_Contact__c contractContact=new Contract_Contact__c();
         contractContact.Contract__c=selectedProjectId;
         contractContact.Type__C='Email';
         ContractContacts.add(contractContact);
     }
     
     public List<Contract_Contact__c> ContractContacts{
         get;set;
     }
     public List<Contract_Contact__c> ContractContactsProject{
         get;set;
     }
     public void SendEmail(string PROID){
         Id templateId=[select id from EmailTemplate where DeveloperName='Project_Report_Out_VF' limit 1].id;
         List<Contact> contactList=new List<Contact>();
         OrgWideEmailAddress orgWideAddress= [select Id from OrgWideEmailAddress where 
                                              Address = 'dimagi-salesforce@dimagi.com' limit 1];
         /*List<DContract__c> contractList=[select id,Project_Manager__c,Backstop__c,Field_Manager__c,
                                          Project_Manager__r.Name,Backstop__r.Name,Field_Manager__r.Name,
                                          In_Charge_Of_Report_Out__c from DContract__c 
                                          where Id=:contractid];
         if(contractList!=null && contractList.size()>0){
            if(contractList[0].Project_Manager__c!=null){
                contactList.add(contractList[0].Project_Manager__r);
            }
            if(contractList[0].Backstop__c!=null){
                contactList.add(contractList[0].Backstop__r);
            }
            if(contractList[0].Field_Manager__c!=null){
                contactList.add(contractList[0].Field_Manager__r);
            }
         }*/
         List<Contract_Contact__c> contractContactList= [select id,Contact__C,Email__C,Type__c,Contact__r.Email,Contact__r.Id,Contact__r.Name,Contract__C from 
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
         System.debug('Contact List Size: '+contactList.size());
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
         
         /*List<Messaging.SingleEmailMessage> messageList=new List<Messaging.SingleEmailMessage>();
         
         for(Contact con:contactList){
             Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
             msg.setTemplateId(templateId);
             //msg.setCcAddresses(new String[] {'email1@recipient.com', 'email2@recipient.com'});
             msg.setTargetObjectId(con.Id);
             msg.setWhatId(PROID);
             msg.setSaveAsActivity(false);
             messageList.add(msg);
         }
         if(messageList.size()>0){
             Messaging.sendEmail(messageList);
         }*/
     }
     public void AddMe(){
     
         List<Contact> contList=[select id,name from contact where email=:CurrentLoginEmail];
         
         if(contList.size()>0){
           Contract_Contact__c contractContact=new Contract_Contact__c();
           contractContact.Contract__c=selectedProjectId;
           contractContact.Type__C='Person';
           contractContact.Contact__C=contList[0].id;
           ContractContacts.add(contractContact);
         
         }
     }
     public class PROProject{
         public PROProject(){
         
         }
         public DContract__c contract{
             get;set;
         }
         public string CSSClass{
             get;set;
         }
     
     
     }
     
 }