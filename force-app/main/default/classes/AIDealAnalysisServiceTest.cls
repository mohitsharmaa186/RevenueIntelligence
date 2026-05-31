@IsTest
private class AIDealAnalysisServiceTest {
    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'AI Test Account');
        insert acc;
    }

    @IsTest
    static void testAnalyzeDeal_RuleBasedFallback() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'AI Analysis Test',
            AccountId = acc.Id,
            Amount = 120000,
            StageName = 'Proposal/Price Quote',
            CloseDate = Date.today().addDays(20),
            Discount_Percentage__c = 0.15
        );
        insert opp;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OpenAIMockResponse());
        Map<String, Object> result = AIDealAnalysisService.analyzeDeal(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result.get('summary'));
        System.assertNotEquals(null, result.get('winProbability'));
        System.assertNotEquals(null, result.get('recommendations'));
    }

    @IsTest
    static void testGetLatestAnalysis() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Latest Analysis Test',
            AccountId = acc.Id,
            Amount = 90000,
            StageName = 'Negotiation/Review',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;

        insert new Deal_Analysis__c(
            Opportunity__c = opp.Id,
            AI_Summary__c = 'Test summary',
            Recommendations__c = '["Action 1","Action 2"]',
            Confidence_Score__c = 75,
            Analysis_Date__c = DateTime.now()
        );

        Test.startTest();
        Map<String, Object> analysis = AIDealAnalysisService.getLatestAnalysis(opp.Id);
        Test.stopTest();

        System.assertEquals('Test summary', analysis.get('summary'));
        System.assertEquals(75, analysis.get('confidenceScore'));
    }

    @IsTest
    static void testAnalyzeDeal_NotFound() {
        Test.startTest();
        try {
            AIDealAnalysisService.analyzeDeal('006000000000000AAA');
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(true, 'Expected exception thrown');
        }
        Test.stopTest();
    }

    @IsTest
    static void testAnalyzeDeal_HTTPFailureFallback() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'HTTP Failure Test',
            AccountId = acc.Id,
            Amount = 95000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(-3),
            Discount_Percentage__c = 0.35
        );
        insert opp;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OpenAIFailureMock());
        Map<String, Object> result = AIDealAnalysisService.analyzeDeal(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result.get('summary'));
        System.assertNotEquals(null, result.get('riskExplanation'));
    }

    @IsTest
    static void testGetLatestAnalysis_Empty() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'No Analysis Yet',
            AccountId = acc.Id,
            Amount = 40000,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(25)
        );
        insert opp;

        Map<String, Object> analysis = AIDealAnalysisService.getLatestAnalysis(opp.Id);
        System.assertEquals(true, analysis.isEmpty());
    }

    @IsTest
    static void testBuildAnalysisPrompt() {
        Opportunity opp = new Opportunity(
            Name = 'Prompt Test Opp',
            Amount = 55000,
            StageName = 'Qualification',
            CloseDate = Date.today(),
            Health_Score__c = 55,
            Risk_Level__c = 'Medium',
            Discount_Percentage__c = 0.10
        );
        Risk_Alert__c alert = new Risk_Alert__c(
            Severity__c = 'High',
            Reason__c = 'Stale activity'
        );

        String prompt = AIDealAnalysisService.buildAnalysisPrompt(opp, new List<Risk_Alert__c>{ alert });
        System.assert(prompt.contains('Prompt Test Opp'));
        System.assert(prompt.contains('Stale activity'));
    }

    private class OpenAIFailureMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Service unavailable"}');
            return res;
        }
    }

    private class OpenAIMockResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"choices":[{"message":{"content":"{\\"summary\\":\\"AI Summary\\",\\"riskExplanation\\":\\"Moderate risk\\",\\"winProbability\\":65,\\"recommendations\\":[\\"Follow up\\"],\\"confidenceScore\\":70}"}}]}');
            return res;
        }
    }
}
