global class hqInt_MainClass  
{
	/**
	 * 
	 * 
	 * MAIN METHOD
	 *
	 **/
	public integer offsetParam; 
	global void mainMethod(integer offsetParameter)
	{
		offsetParam = offsetParameter; 
		String response;
		
		HTTPResponse res = requestMethod(Integer.valueOf(CommcareToSalesforceSettings__c.getInstance('ApiLimitParameter').Value__c),offsetParameter);
  
		response = res.getBody(); 
		System.debug('---res---'+ response);

		response = ReplaceReservedWords(response);

		processJson(response);		

	}
	
    /**
     * 
     * Method Name : requestMethod  
     * Purpose : Http Callout to CommCareHQ 
     * 
     **/
	public HTTPResponse requestMethod(integer limitParameter,integer offsetParameter)
	{

        HttpRequest req = new HttpRequest();
		req.setEndpoint('https://www.commcarehq.org/hq/admin/api/global/project_space_metadata/?limit='+ String.valueOf(limitParameter) +'&offset='+ String.valueOf(offsetParameter));
		req.setMethod('GET');

		// Specify the required user name and password to access the endpoint 

		// As well as the header and header information 


		String username = CommcareToSalesforceSettings__c.getInstance('CommCareUserName').Value__c;
		String password = CommcareToSalesforceSettings__c.getInstance('CommCarePassword').Value__c;

		Blob headerValue = Blob.valueOf(username + ':' + password);
		String authorizationHeader = 'BASIC ' +
		EncodingUtil.base64Encode(headerValue);
		req.setHeader('Authorization', authorizationHeader);
		req.setTimeout(120000);

		// Create a new http object to send the request object 

		// A response object is generated as a result of the request   


		Http http = new Http();
		HTTPResponse res = http.send(req);
		system.debug('---status--'+res.getStatusCode());
		if(res.getStatusCode() != 200)
			throw new CustomException();
		return res;
		
	}
	
    /**
     * 
     * Method Name : processJson
     * Purpose : Process Json response and perform DML 
     * 
     **/
	private string processJson(String jsonString)
	{
		hqInt_Model_DomainClass domainobj;
        list <hqInt_Model_DomainClass> listDomainObj = new list <hqInt_Model_DomainClass>();
        list <Domain__c> listDomainRec = new list <Domain__c>();
        list <hqInt_Model_DeploymentClass> listDeploymentObj = new list <hqInt_Model_DeploymentClass>();
        list <Deployment__c> listDeploymentRec = new list <Deployment__c>();
        list <Internal_Properties__c> listInternalPropRec = new list <Internal_Properties__c>();
        
		//Process Response
		JSONParser parser = JSON.createParser(jsonString);

		while (parser.nextToken() != null) 
		{
	        // Start at the array of invoices.
	        if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'domain_properties') 
	        {
	        	while (parser.nextToken() != null) {
	               
	                if (parser.getCurrentToken() == JSONToken.START_OBJECT) 
	                {
	                    // Read entire invoice object, including its array of line items.
	                    domainObj = (hqInt_Model_DomainClass)parser.readValueAs(hqInt_Model_DomainClass.class);
	                	listDomainObj.add(domainObj);
	                    system.debug('---domainobj---' + domainObj);
	                    // Skip the child start array and start object markers.
	                    parser.skipChildren();
	                    break;
	                }
	            }
	        }
    	}
		
        //Set for holding the external id field for domain object. It is used to fetch existing internal prop & deployment rec & delete those.
    	set <String> setDomainId = new set <String>();

    	//Below for loop is used to create sobject out of model object
        for(hqInt_Model_DomainClass domainObj1 : listDomainObj)
        {
            Domain__c domainRec = domainObj1.createDbObject();
            domainRec.offset__c = offsetParam;
            listDomainRec.add(domainRec);
            setDomainId.add(domainRec.id__c);

            Internal_Properties__c InternalPropRec = domainObj1.internal.createDbObject();
            listInternalPropRec.add(InternalPropRec);

         	Deployment__c deploymentRec = domainObj1.deployment.createDbObject();
            listDeploymentRec.add(deploymentRec);
               
    	}
		system.debug('----offsetParam---'+offsetParam);
    	//insert the sobjects except domain sobject
    	insert listInternalPropRec;
    	insert listDeploymentRec;
  
    	list <Internal_Properties__c> listInternalPropToBeDeleted = new list <Internal_Properties__c>();
    	list <Deployment__c> listDeploymentToBeDeleted = new list <Deployment__c>();

    	//fetch exisiting sf id of deployment and internal prop for deletion.
    	for(Domain__c domain : [SELECT id,Internal_Properties__c,Deployment__c from Domain__c WHERE id__c in :setDomainId])
    	{
    		if(domain.Internal_Properties__c != null)
    		{
    			Internal_Properties__c 	InternalPropRec = new Internal_Properties__c(id=domain.Internal_Properties__c);
    			listInternalPropToBeDeleted.add(InternalPropRec);	
    		}
    		if(domain.Deployment__c != null)
    		{
    			Deployment__c 	deploymentRec = new Deployment__c(id=domain.Deployment__c);
    			listDeploymentToBeDeleted.add(deploymentRec);	
    		}
    	}
    	//delete existing int prop and deployment records
    	delete listInternalPropToBeDeleted;
    	delete listDeploymentToBeDeleted;

    	//populate the lookup fields on domain obect 
    	for(integer i=0;i<listDeploymentRec.size();i++)
        {
            listDomainRec[i].Internal_Properties__c = listInternalPropRec[i].id;
            listDomainRec[i].Deployment__c = listDeploymentRec[i].id;
        }

        //Finally do an upsert on the domain record list
        upsert listDomainRec id__c;

    	return null;	
	} 
	
    /**
     * 
     * Method Name : ReplaceReservedWords
     * Purpose : In json string, some fields will be reserved / not allowed keywords. This method will replace those with alternate names
     * 
     **/
	private string ReplaceReservedWords(string myString) 
	{
 
       myString = myString.replaceAll('"_id"\\s*:', '"x_id":');
       myString = myString.replaceAll('"public"\\s*:', '"x_Public":');
       myString = myString.replaceAll('"date"\\s*:', '"x_date":');
       //myString = myString.replaceAll('"currency"\\s*:', '"x_currency":');
       return myString;
    }

	
}