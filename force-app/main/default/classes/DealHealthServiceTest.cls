@IsTest
private class DealHealthServiceTest {
    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
    }

    @IsTest
    static void testCalculateHealthScore_HealthyDeal() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Healthy Deal',
            AccountId = acc.Id,
            Amount = 100000,
            StageName = 'Proposal/Price Quote',
            CloseDate = Date.today().addDays(15),
            Discount_Percentage__c = 0.05
        );

        Test.startTest();
        insert opp;
        Test.stopTest();

        opp = [SELECT Health_Score__c, Risk_Level__c, Forecast_Category__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertNotEquals(null, opp.Health_Score__c, 'Health score should be calculated');
        System.assert(opp.Health_Score__c > 0, 'Health score should be positive');
    }

    @IsTest
    static void testCalculateHealthScore_AtRiskDeal() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'At Risk Deal',
            AccountId = acc.Id,
            Amount = 50000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(-5),
            Discount_Percentage__c = 0.45
        );

        Test.startTest();
        insert opp;
        Test.stopTest();

        opp = [SELECT Health_Score__c, Risk_Level__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertNotEquals(null, opp.Risk_Level__c, 'Risk level should be set');
    }

    @IsTest
    static void testGetDashboardMetrics() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        insert new Opportunity(
            Name = 'Dashboard Test',
            AccountId = acc.Id,
            Amount = 75000,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30)
        );

        Test.startTest();
        Map<String, Object> metrics = DealHealthService.getDashboardMetrics();
        Test.stopTest();

        System.assertNotEquals(null, metrics.get('pipelineRevenue'));
        System.assertNotEquals(null, metrics.get('totalDeals'));
    }

    @IsTest
    static void testGetDealHealth() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Health Test',
            AccountId = acc.Id,
            Amount = 25000,
            StageName = 'Needs Analysis',
            CloseDate = Date.today().addDays(45)
        );
        insert opp;

        Test.startTest();
        Map<String, Object> health = DealHealthService.getDealHealth(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, health.get('healthScore'));
        System.assertNotEquals(null, health.get('riskLevel'));
    }

    @IsTest
    static void testProcessOpportunities_Bulk() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            opps.add(new Opportunity(
                Name = 'Bulk Test ' + i,
                AccountId = acc.Id,
                Amount = 10000 * (i + 1),
                StageName = 'Qualification',
                CloseDate = Date.today().addDays(30 + i)
            ));
        }

        Test.startTest();
        insert opps;
        Test.stopTest();

        List<Opportunity> results = [SELECT Health_Score__c FROM Opportunity WHERE Id IN :opps];
    @IsTest
    static void testCalculateHealthScore_Direct() {
        Opportunity opp = new Opportunity(
            StageName = 'Unknown Stage',
            CloseDate = Date.today().addDays(120),
            LastActivityDate = Date.today(),
            Discount_Percentage__c = 0.02
        );

        Integer score = DealHealthService.calculateHealthScore(opp);
        System.assert(score >= 0 && score <= 100);

        Decimal confidence = DealHealthService.calculateRevenueConfidence(opp, score);
        System.assertNotEquals(null, confidence);

        String forecast = DealHealthService.determineForecastCategory(opp, score);
        System.assertNotEquals(null, forecast);
    }

    @IsTest
    static void testDetermineForecastCategory_ClosedWon() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Closed Won Forecast',
            AccountId = acc.Id,
            Amount = 50000,
            StageName = 'Closed Won',
            CloseDate = Date.today()
        );
        insert opp;
        opp = [SELECT IsClosed, IsWon FROM Opportunity WHERE Id = :opp.Id];

        System.assertEquals('Closed', DealHealthService.determineForecastCategory(opp, 90));
    }

    @IsTest
    static void testProcessOpportunities_SkipsClosed() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity openOpp = new Opportunity(
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            Amount = 10000,
            Discount_Percentage__c = 0.05
        );
        Opportunity closedOpp = new Opportunity(
            Name = 'Closed Skip Process',
            AccountId = acc.Id,
            Amount = 20000,
            StageName = 'Closed Won',
            CloseDate = Date.today()
        );
        insert closedOpp;
        closedOpp = [SELECT IsClosed, IsWon, StageName, CloseDate, Amount, Discount_Percentage__c
                     FROM Opportunity WHERE Id = :closedOpp.Id];

        DealHealthService.processOpportunities(new List<Opportunity>{ openOpp, closedOpp });
        System.assertNotEquals(null, openOpp.Health_Score__c);
        System.assertEquals(null, closedOpp.Health_Score__c);
    }

    @IsTest
    static void testGetDealHealth_InvalidId() {
        Map<String, Object> health = DealHealthService.getDealHealth('006000000000000AAA');
        System.assertEquals(true, health.isEmpty());
    }
}
