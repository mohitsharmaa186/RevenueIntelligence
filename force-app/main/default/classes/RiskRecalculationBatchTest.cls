@IsTest
private class RiskRecalculationBatchTest {
    @TestSetup
    static void setup() {
        TriggerHandler.bypass('OpportunityTriggerHandler');
        try {
            Account acc = new Account(Name = 'Batch Test Account');
            insert acc;

            List<Opportunity> opps = new List<Opportunity>();
            for (Integer i = 0; i < 5; i++) {
                opps.add(new Opportunity(
                    Name = 'Batch Opp ' + i,
                    AccountId = acc.Id,
                    Amount = 10000 * (i + 1),
                    StageName = 'Qualification',
                    CloseDate = Date.today().addDays(30)
                ));
            }
            insert opps;
        } finally {
            TriggerHandler.clearBypass('OpportunityTriggerHandler');
        }
    }

    @IsTest
    static void testBatchExecution() {
        Test.startTest();
        Database.executeBatch(new RiskRecalculationBatch(), 200);
        Test.stopTest();

        List<Opportunity> opps = [SELECT Health_Score__c, Risk_Level__c FROM Opportunity];
        System.assert(!opps.isEmpty(), 'Test data should exist');
        for (Opportunity opp : opps) {
            System.assertNotEquals(null, opp.Health_Score__c, 'Health score should be recalculated');
        }
    }
}
