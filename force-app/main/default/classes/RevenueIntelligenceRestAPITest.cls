@IsTest
private class RevenueIntelligenceRestAPITest {
    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'REST Test Account');
        insert acc;
        insert new Opportunity(
            Name = 'REST Test Opportunity',
            AccountId = acc.Id,
            Amount = 100000,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30)
        );
    }

    @IsTest
    static void testGetOpportunities_List() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/revenueintelligence/opportunities/';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        RevenueIntelligenceRestAPI.getOpportunities();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
    }

    @IsTest
    static void testGetOpportunity_ById() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/revenueintelligence/opportunities/' + opp.Id;
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        RevenueIntelligenceRestAPI.getOpportunities();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
    }

    @IsTest
    static void testCreateOpportunity() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/revenueintelligence/opportunities/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'name' => 'API Created Opp',
            'accountId' => acc.Id,
            'amount' => 55000,
            'stageName' => 'Prospecting',
            'closeDate' => String.valueOf(Date.today().addDays(45))
        }));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        RevenueIntelligenceRestAPI.createOpportunity();
        Test.stopTest();

        System.assertEquals(201, res.statusCode);
    }

    @IsTest
    static void testUpdateOpportunity() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/revenueintelligence/opportunities/' + opp.Id;
        req.httpMethod = 'PUT';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'amount' => 150000,
            'stageName' => 'Negotiation/Review'
        }));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        RevenueIntelligenceRestAPI.updateOpportunity();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
    }

    @IsTest
    static void testDeleteOpportunity() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Delete Test',
            AccountId = acc.Id,
            Amount = 10000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/revenueintelligence/opportunities/' + opp.Id;
        req.httpMethod = 'DELETE';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        RevenueIntelligenceRestAPI.deleteOpportunity();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
    }

    @IsTest
    static void testGetOpportunity_NotFound() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/revenueintelligence/opportunities/006000000000000AAA';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        RevenueIntelligenceRestAPI.getOpportunities();
        Test.stopTest();

        System.assertEquals(404, res.statusCode);
    }

    @IsTest
    static void testUpdateOpportunity_NotFound() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/revenueintelligence/opportunities/006000000000000AAA';
        req.httpMethod = 'PUT';
        req.requestBody = Blob.valueOf('{"amount":1000}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        RevenueIntelligenceRestAPI.updateOpportunity();
        Test.stopTest();

        System.assertEquals(404, res.statusCode);
    }

    @IsTest
    static void testDeleteOpportunity_NotFound() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/revenueintelligence/opportunities/006000000000000AAA';
        req.httpMethod = 'DELETE';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        RevenueIntelligenceRestAPI.deleteOpportunity();
        Test.stopTest();

        System.assertEquals(404, res.statusCode);
    }

    @IsTest
    static void testCreateOpportunity_InvalidBody() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/revenueintelligence/opportunities/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('not-json');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        RevenueIntelligenceRestAPI.createOpportunity();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
    }
}
