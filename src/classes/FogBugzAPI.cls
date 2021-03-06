/**
 * Client for the FogBugzAPI
 *
 * @author  Antonio Grassi
 * @modifiedBy Virginia Fern�ndez
 *
 * @date    11/13/2012
 */
public with sharing class FogBugzAPI {
	
	private static final String    FB_API_URL          = 'http://manage.dimagi.com/api.asp?'; 
	private static final String    FB_LIST_COLS        = 'sArea,ixPersonOpenedBy,dtLastUpdated';
    private static final String    FB_CASE_COLS        = 'sTitle,sArea,sPersonAssignedTo,sVersion,dtLastUpdated,latestEvent,tags,ixPersonOpenedBy'; 

    private static final Integer   FB_HTTP_TIMEOUT     = 60000;
    
    /**
     * Retrieves list of cases on the current filter. For each case, we just get its
     * Id and last modified date. 
     */
    public Map<String, FogBugzCase> listCases() {

        HTTPRequest req = new HTTPRequest();
        req.setEndpoint(FB_API_URL);
        req.setBody('token=' + FogBugz_Settings__c.getOrgDefaults().Token__c + '&cmd=search&cols=' + FB_LIST_COLS);
        req.setTimeout(FB_HTTP_TIMEOUT);
        req.setMethod('POST');

        HTTP connection = new HTTP();

        HTTPResponse res = null;
        
        if (!Test.isRunningTest()) { 
            res = connection.send(req);
        }
        else {
        	FogBugzHttpCalloutMock mock = new FogBugzHttpCalloutMock();
        	res = mock.respond(req);
        }
        
        if (res.getBody() != null) {
            return parseCaseList(res.getBody());
        }
        else {
            System.debug(LoggingLevel.ERROR, 'FogBugzAPI::listCases() - Error while retrieving cases');
            hqInt_BatchErrorLogger.logError(FogBugzSynchronizerBatch.batchId,'Fogbugz Error','FogBugzAPI::listCases() - Error while retrieving cases','');
            return new Map<String, FogBugzCase>();
        }
    }
    
    public FogBugzCase getCase(String caseId) {

        HTTPRequest req = new HTTPRequest();
        req.setEndpoint(FB_API_URL);
        req.setBody('token=' + FogBugz_Settings__c.getOrgDefaults().Token__c + '&cmd=search&cols=' + FB_CASE_COLS + '&q=' + caseId);
        req.setTimeout(FB_HTTP_TIMEOUT);
        req.setMethod('POST');
        HTTP connection = new HTTP();
        HTTPResponse res = null;
        
        if (Test.isRunningTest()) {
        	FogBugzHttpCalloutMock mock = new FogBugzHttpCalloutMock();
        	res = mock.respond(req);
        }
        else {
	        res = connection.send(req);
        }
        
        if (res.getBody() != null) {
            Map<String,FogBugzCase> cases = parseCases(res.getBody());
            return cases.size() > 0 ? cases.values()[0] : null;
        }
        else {
            System.debug(LoggingLevel.ERROR, 'FogBugzAPI::getCase() - Error while retrieving case with Id ' + caseId);
            return null;
        }
    }
    
	public String setCurrentFilter(Integer filterId) {
		HTTPRequest req = new HTTPRequest();
        req.setEndpoint(FB_API_URL);
        req.setBody('token=' + FogBugz_Settings__c.getOrgDefaults().Token__c + '&cmd=setCurrentFilter&sFilter=' + filterId.format());
        req.setTimeout(FB_HTTP_TIMEOUT);
        req.setMethod('POST');
        
        HTTP connection = new HTTP();
        
        if (Test.isRunningTest()) {
        	FogBugzHttpCalloutMock mock = new FogBugzHttpCalloutMock();
        	return mock.respond(req).getBody();
        }
        
        return connection.send(req).getBody();
	}
	
	public String createCase(FogBugzCase fbCase, boolean close) {
		
		Map<String, String> params = new Map<String, String> {
			'cmd' => 'new',
			'sTitle' => fbCase.title,
			'sVersion' => fbCase.externalBugID,
			'sProject' => fbCase.project,
			'sArea' => fbCase.area,
			'sPersonAssignedTo' => fbCase.assignedTo,
			'sStatus' => fbCase.status,
			'ixPriority' => fbCase.priority.format()
		};
		
		if (fbCase.probability != null) {
			params.put('sTags', '['+fbCase.dealSize+'/'+fbCase.probability+']');
		}
		
		HTTPRequest req = new HttpRequest();
		req.setEndpoint(FB_API_URL);
		req.setBody('token=' + FogBugz_Settings__c.getOrgDefaults().Token__c + '&' + encodeParameters(params));
        req.setTimeout(FB_HTTP_TIMEOUT);
		req.setMethod('POST');
		
		HTTP connection = new HTTP();
		HTTPResponse res = null;
		
		if (Test.isRunningTest()) {
			FogBugzHttpCalloutMock mock = new FogBugzHttpCalloutMock();
			res = mock.respond(req);
		}
		else {
            res = connection.send(req);
		}
		
		
		fbCase.caseId = parseUpsertId(res.getBody());
		
		if (close) {
            this.resolveCase(fbCase);
            this.closeCase(fbCase);
        }
        
		return fbCase.caseId;
	}
	
	public String resolveCase(FogBugzCase fbCase) {
        Map<String, String> params = new Map<String, String> {
            'cmd' => 'resolve',
            'ixBug' => fbCase.caseId,
            'sVersion' => fbCase.externalBugID
        };
        
        HTTPRequest req = new HttpRequest();
        req.setEndpoint(FB_API_URL);
        req.setBody('token=' + FogBugz_Settings__c.getOrgDefaults().Token__c + '&' + encodeParameters(params));
        req.setTimeout(FB_HTTP_TIMEOUT);
        req.setMethod('POST');
        
        HTTP connection = new HTTP();
        HTTPResponse res = null;
        
        if (Test.isRunningTest()) {
            FogBugzHttpCalloutMock mock = new FogBugzHttpCalloutMock();
            res = mock.respond(req);	
        }
        else {
	        res = connection.send(req);
        }
        
        return parseUpsertId(res.getBody());
    }
    
    public String reopenCase(FogBugzCase fbCase) {
    	
        Map<String, String> params = new Map<String, String> {
            'cmd' => 'reopen',
            'ixBug' => fbCase.caseId,
            'sVersion' => fbCase.externalBugID
        };
        
        HTTPRequest req = new HttpRequest();
        req.setEndpoint(FB_API_URL);
        req.setBody('token=' + FogBugz_Settings__c.getOrgDefaults().Token__c + '&' + encodeParameters(params));
        req.setTimeout(FB_HTTP_TIMEOUT);
        req.setMethod('POST');
        
        HTTP connection = new HTTP();
        HTTPResponse res = null;
        
        if (Test.isRunningTest()) {
            FogBugzHttpCalloutMock mock = new FogBugzHttpCalloutMock();
            res = mock.respond(req);    
        }
        else {
            res = connection.send(req);
        }
        
        return parseUpsertId(res.getBody());
    }
    
    public String closeCase(FogBugzCase fbCase) {
    	
        Map<String, String> params = new Map<String, String> {
            'cmd' => 'close',
            'ixBug' => fbCase.caseId,
            'sVersion' => fbCase.externalBugID
        };
        
        HTTPRequest req = new HttpRequest();
        req.setEndpoint(FB_API_URL);
        req.setBody('token=' + FogBugz_Settings__c.getOrgDefaults().Token__c + '&' + encodeParameters(params));
        req.setTimeout(FB_HTTP_TIMEOUT);
        req.setMethod('POST');
        
        HTTP connection = new HTTP();
        HTTPResponse res = null;
        
        if (Test.isRunningTest()) {
        	FogBugzHttpCalloutMock mock = new FogBugzHttpCalloutMock();
        	res = mock.respond(req);
        }
        else {
	        res = connection.send(req);
        }
        
        return parseUpsertId(res.getBody());
    }
	
	public String updateCase(FogBugzCase fbCase) {
        Map<String, String> params = new Map<String, String> {
            'cmd' => 'edit',
            'ixBug' => fbCase.caseId,
            'sVersion' => fbCase.externalBugID
        };
        
        HTTPRequest req = new HttpRequest();
        req.setEndpoint(FB_API_URL);
        req.setBody('token=' + FogBugz_Settings__c.getOrgDefaults().Token__c + '&' + encodeParameters(params));
        req.setTimeout(FB_HTTP_TIMEOUT);
        req.setMethod('POST');
        
        HTTP connection = new HTTP();
        HTTPResponse res = null;
        
        if (Test.isRunningTest()) {
        	FogBugzHttpCalloutMock mock = new FogBugzHttpCalloutMock();
        	res = mock.respond(req);
        }
        else {
            res = connection.send(req);
        }
        
        return parseUpsertId(res.getBody());
	}
	
	private List<String> getCaseTags(FogBugzCase fbCase) {
        Map<String, String> paramsTags = new Map<String, String> {
            'cmd' => 'search',
            'q' => fbCase.caseId,
            'cols' => 'tags'
        };
        
        HTTPRequest req = new HttpRequest();
        req.setEndpoint(FB_API_URL);
        req.setBody('token=' + FogBugz_Settings__c.getOrgDefaults().Token__c + '&' + encodeParameters(paramsTags));
        req.setTimeout(FB_HTTP_TIMEOUT);
        req.setMethod('POST');
        
        HTTP connection = new HTTP();
        HTTPResponse res = null;
        
        if (Test.isRunningTest()) {
            
           FogBugzHttpCalloutMock mock = new FogBugzHttpCalloutMock();
           res = mock.respond(req);
        }
        else {
        	
           res = connection.send(req);
        }
        
        return parseCaseTags(res.getBody());
	}
	
	public String updateCaseTitleStageTag(FogBugzCase fbCase, boolean editTags, Set<String> products, boolean close, boolean reopen) {
		
		Map<String, String> params = new Map<String, String> {
            'cmd' => 'edit',
            'ixBug' => fbCase.caseId,
            'sVersion' => fbCase.externalBugID,
            'sTitle' => fbCase.title,
            'sArea' => fbCase.area
        };
        
		String tags = null;
		
		if (editTags) {
			
	        List<String> listTags = getCaseTags(fbCase);
	        
	        tags = '';
	        
	        for (String tag: listTags) {
	        	
	        	if ((!products.contains(tag)) && ((!tag.startsWith('[') || !tag.endsWith(']') || !Pattern.matches('\\d*/\\d*', tag.substring(1, tag.length()-1))))) {
	        		tags += tag+',';
	        	}
	        	else {
	        		products.remove(tag);
	        	}
	        }
	        
	        for (String product : products) {
	        	tags += product + ',';
	        }
	        
	        if (fbCase.probability != null) {
	           tags += '['+fbCase.dealSize+'/'+fbCase.probability+']';
	        }
	        
	        if (tags.equals('')) {
	        	tags = ' ';
	        }
	        
	        params.put('sTags', tags);
		}
		
        HTTPRequest req = new HttpRequest();
        req.setEndpoint(FB_API_URL);
        req.setBody('token=' + FogBugz_Settings__c.getOrgDefaults().Token__c + '&' + encodeParameters(params));
        req.setTimeout(FB_HTTP_TIMEOUT);
        req.setMethod('POST');
        
        HTTP connection = new HTTP();
        HTTPResponse res = null;
            
        if (Test.isRunningTest()) {            
            FogBugzHttpCalloutMock mock = new FogBugzHttpCalloutMock();
            res = mock.respond(req);
        }
        else {
            res = connection.send(req);
        }
        
        if (close) {
        	this.resolveCase(fbCase);
            return this.closeCase(fbCase);
        }
        else if (reopen) {
        	this.reopenCase(fbCase);
        }
        
        return parseUpsertId(res.getBody());
    }
    

    public String addNote(String caseId, String note) {
        Map<String, String> params = new Map<String, String> {
            'cmd' => 'edit',
            'ixBug' => caseId,
            'sEvent' => note
        };

        HTTPRequest req = new HttpRequest();
        req.setEndpoint(FB_API_URL);
        req.setBody('token=' + FogBugz_Settings__c.getOrgDefaults().Token__c + '&' + encodeParameters(params));
        req.setTimeout(FB_HTTP_TIMEOUT);
        req.setMethod('POST');
        
        HTTP connection = new HTTP();
        HTTPResponse res = null;
        
        if (Test.isRunningTest()) {
        	FogBugzHttpCalloutMock mock = new FogBugzHttpCalloutMock();
            res = mock.respond(req);
        } 
        else {
            res = connection.send(req);
        }

        return parseUpsertId(res.getBody());
    }
    
    public String getPersonEmail(String ixPerson) {
        Map<String, String> params = new Map<String, String> {
            'cmd' => 'viewPerson',
            'ixPerson' => ixPerson
        };

        HTTPRequest req = new HttpRequest();
        req.setEndpoint(FB_API_URL);
        req.setBody('token=' + FogBugz_Settings__c.getOrgDefaults().Token__c + '&' + encodeParameters(params));
        req.setTimeout(FB_HTTP_TIMEOUT);
        req.setMethod('POST');
        
        HTTP connection = new HTTP();
        HTTPResponse res = null;
        
        if (Test.isRunningTest()) {
        	FogBugzHttpCalloutMock mock = new FogBugzHttpCalloutMock();
            res = mock.respond(req);
        }
        else {
            res = connection.send(req);
        }

        String email = null;
        
        if (res != null && res.getBody() != null) {
        	XMLDom dom = new XMLDom(res.getBody());
            XMLDom.Element responseNode = dom.root.getElementByTagName('response');

	        if (responseNode != null) {
	            XMLDom.Element personNode = responseNode.getElementByTagName('person');
	            
	            if (personNode != null) {
	                email = personNode.getElementByTagName('sEmail').nodeValue;
	            }
	        }
        }
        
        return email;
    }
        

    /**
     * Encodes request parameters to be passed on GET URL or POST body
     */	
    private String encodeParameters(Map<String, String> parameters) {
        
        String res = '';
        
        for (String name:parameters.keySet()) {
        	
            res += (res == '' ? '' : '&') + name + '=' + EncodingUtil.urlEncode(parameters.get(name), 'UTF-8');
        }
        
        return res;
    }

	/**
	 * XML Parsing
	 */
	private String parseUpsertId(String xmlString) {
		
		String res = null;
		
		XMLDom dom = new XMLDom(xmlString);
        XMLDom.Element responseNode = dom.root.getElementByTagName('response');
        
        if (responseNode != null) {
        	XMLDom.Element caseNode = responseNode.getElementByTagName('case');
        	
        	if (caseNode != null) {
        		res = caseNode.getAttribute('ixBug');
        	}
        }
        
        return res;
	}
	
	/**
	 * Here we use SF's native DOM XML parser. We can parse a large case list,
	 * but we cannot access CDATA fields
	 */
	public Map<String, fogBugzCase> parseCaseList(String xmlString) {
		system.debug('----xmlString----'+xmlString);
		
        Dom.Document doc = new Dom.Document();
        doc.load(xmlString);
        
        Dom.XmlNode responseNode = doc.getRootElement();
        Dom.XmlNode casesNode = responseNode.getChildElement('cases', null);
        
        Map<String, FogBugzCase> cases = new Map<String, FogBugzCase>();

        if (casesNode != null) {
            
            for (Dom.XmlNode caseNode:casesNode.getChildren()) {
                FogBugzCase fbCase = parseListCase(caseNode);
                cases.put(fbCase.caseId, fbCase);
            }
        }
        
        return cases;
	}
	
    public FogBugzCase parseListCase(Dom.XmlNode caseNode) {
		system.debug('----caseNode----'+caseNode);
        FogBugzCase fbCase = new FogBugzCase();
        
        fbCase.caseId = caseNode.getAttribute('ixBug', null);
        fbCase.ixPersonOpenedBy = caseNode.getChildElement('ixPersonOpenedBy', null).getText();
        String dtLastUpdatedValue = caseNode.getChildElement('dtLastUpdated', null).getText();
        
        system.debug('----sAreaChildnodes----' + caseNode.getChildElement('sArea', null).getChildElements());
        
        for(Dom.XmlNode sAreaChildNode : caseNode.getChildElement('sArea', null).getChildElements())
        {
        	system.debug('----sAreaNode----' + sAreaChildNode.getText());	
        }
        String sAreaValue = caseNode.getChildElement('sArea', null).getText();
        
        if (dtLastUpdatedValue != null && dtLastUpdatedValue.length() > 0) {
            fbCase.lastModifiedDate = FogBugzUtils.parseRFC822UTCTime(dtLastUpdatedValue);
        }
		fbCase.area = sAreaValue;
        return fbCase;    	
    }

    /**
     * Here we use the custom XML parser (based on SF's native XMLReader)
     * in order to access CDATA fields. Should be used with only one or a few
     * cases in order to avoid the max script statements limit
     */
    public Map<String, FogBugzCase> parseCases(String xmlString) {
        
        XMLDom dom = new XMLDom(xmlString);
        XMLDom.Element casesNode = dom.root.getElementByTagName('cases');
        
        Map<String, FogBugzCase> cases = new Map<String, FogBugzCase>();
        
        for (XMLDom.Element caseNode:casesNode.childNodes) {
            FogBugzCase fbCase = parseCase(caseNode);
            cases.put(fbCase.caseId, fbCase);
        }

        return cases;
    }

    public FogBugzCase parseCase(XMLDom.Element caseNode) {
        
        FogBugzCase fbCase = new FogBugzCase();
        
        fbCase.title = caseNode.getElementByTagName('sTitle').nodeValue;
        fbCase.area = caseNode.getElementByTagName('sArea').nodeValue;
        fbCase.assignedTo = caseNode.getElementByTagName('sPersonAssignedTo').nodeValue;
        fbCase.externalBugID = caseNode.getElementByTagName('sVersion').nodeValue;
        fbCase.caseId = caseNode.getAttribute('ixBug');
        fbCase.ixPersonOpenedBy = caseNode.getElementByTagName('ixPersonOpenedBy').nodeValue;
        String dtLastUpdatedValue = caseNode.getElementByTagName('dtLastUpdated').nodeValue;
        
        if (dtLastUpdatedValue != null && dtLastUpdatedValue.length() > 0) {
            fbCase.lastModifiedDate = FogBugzUtils.parseRFC822UTCTime(dtLastUpdatedValue);
        }
        
        // Search for deal size & probability
        /*for (XMLDom.Element node:caseNode.getElementsByTagName('tag')) {
            
            String value = node.nodeValue;
            Integer slashLoc = value.indexOf('/');
            
            if (slashLoc != -1) {
                
                try {
                    fbCase.dealSize = Integer.valueOf(value.substring(1, slashLoc));
                    fbCase.probability = Decimal.valueOf(value.substring(slashLoc + 1, value.length() - 1));
                }
                catch (Exception e) {
                    system.debug(LoggingLevel.ERROR, 'ERROR - FogBugzAPI::parseCase() - ' + e.getMessage());  
                }
            }
        }*/
        
        XMLDom.Element[] events = caseNode.getElementsByTagName('event');
        
        if (!events.isEmpty()) {
            fbCase.latestEvent = events[0].getElementByTagName('s').nodeValue;
        }
        
        return fbCase;
    }
    
    public List<String> parseCaseTags(String xmlString) {
    	
        XMLDom dom = new XMLDom(xmlString);
        XMLDom.Element casesNode = dom.root.getElementByTagName('tags');
        
        List<String> tags = new List<String>();
        
        for (XMLDom.Element node:casesNode.childNodes) {
            
            tags.add(node.nodeValue);
            
        }
        
        return tags;
    }
}