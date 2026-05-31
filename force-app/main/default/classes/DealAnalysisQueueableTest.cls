@IsTest
private class DealAnalysisQueueableTest {
    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Queueable Test Account');
        insert acc;
    }

    @IsTest
    static void testEnqueueAnalysis() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Queueable Test',
            AccountId = acc.Id,
            Amount = 60000,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockOpenAI());
        String result = DealAnalysisQueueable.enqueueAnalysis(opp.Id);
        Test.stopTest();

        System.assertEquals('Analysis queued successfully', result);
    }

    @IsTest
    static void testQueueableExecution() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Queueable Exec Test',
            AccountId = acc.Id,
            Amount = 45000,
            StageName = 'Needs Analysis',
            CloseDate = Date.today().addDays(25)
        );
        insert opp;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockOpenAI());
        System.enqueueJob(new DealAnalysisQueueable(opp.Id));
        Test.stopTest();

        List<Deal_Analysis__c> analyses = [SELECT Id FROM Deal_Analysis__c WHERE Opportunity__c = :opp.Id];
        System.assert(analyses.size() > 0, 'Analysis record should be created');
    }

    private class MockOpenAI implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"choices":[{"message":{"content":"{\\"summary\\":\\"Test\\",\\"riskExplanation\\":\\"Low\\",\\"winProbability\\":80,\\"recommendations\\":[\\"Go\\"],\\"confidenceScore\\":85}"}}]}');
            return res;
        }
    }
}
