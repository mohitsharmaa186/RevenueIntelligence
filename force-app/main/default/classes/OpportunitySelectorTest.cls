@IsTest
private class OpportunitySelectorTest {
    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Selector Test Account');
        insert acc;
        insert new List<Opportunity>{
            new Opportunity(
                Name = 'Open Healthy Opp',
                AccountId = acc.Id,
                Amount = 100000,
                StageName = 'Proposal/Price Quote',
                CloseDate = Date.today().addDays(20),
                Discount_Percentage__c = 0.03
            ),
            new Opportunity(
                Name = 'Open At Risk Opp',
                AccountId = acc.Id,
                Amount = 50000,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(-5),
                Discount_Percentage__c = 0.45
            ),
            new Opportunity(
                Name = 'Closed Won Opp',
                AccountId = acc.Id,
                Amount = 75000,
                StageName = 'Closed Won',
                CloseDate = Date.today()
            )
        };
    }

    @IsTest
    static void testSelectByIds() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Open Healthy Opp' LIMIT 1];

        System.assertEquals(0, OpportunitySelector.selectByIds(null).size());
        System.assertEquals(0, OpportunitySelector.selectByIds(new Set<Id>()).size());

        List<Opportunity> results = OpportunitySelector.selectByIds(new Set<Id>{ opp.Id });
        System.assertEquals(1, results.size());
        System.assertEquals('Open Healthy Opp', results[0].Name);
    }

    @IsTest
    static void testSelectOpenAndAtRisk() {
        List<Opportunity> openOpps = OpportunitySelector.selectOpenOpportunities();
        System.assertEquals(2, openOpps.size());

        List<Opportunity> atRisk = OpportunitySelector.selectAtRiskOpportunities();
        System.assertEquals(1, atRisk.size());
        System.assert(atRisk[0].Risk_Level__c == 'High' || atRisk[0].Risk_Level__c == 'Critical');
    }

    @IsTest
    static void testSelectByAccountId() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Opportunity> opps = OpportunitySelector.selectByAccountId(acc.Id);
        System.assertEquals(3, opps.size());
    }

    @IsTest
    static void testDashboardAndForecastMetrics() {
        Map<String, Object> metrics = OpportunitySelector.getDashboardMetrics();
        System.assertNotEquals(null, metrics.get('totalPipeline'));
        System.assertNotEquals(null, metrics.get('wonRevenue'));

        AggregateResult[] forecast = OpportunitySelector.getForecastMetrics();
        System.assert(forecast.size() > 0, 'Forecast metrics should return grouped results');
    }
}
