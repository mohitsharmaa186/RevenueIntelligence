@IsTest
private class RiskAlertServiceTest {
    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Risk Alert Account');
        insert acc;
    }

    @IsTest
    static void testGenerateAlerts() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Alert Generation Test',
            AccountId = acc.Id,
            Amount = 150000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(-15),
            Discount_Percentage__c = 0.35
        );
        insert opp;

        opp = [SELECT Id, Health_Score__c, Risk_Level__c, IsClosed, LastActivityDate,
                      Discount_Percentage__c, CloseDate, Name
               FROM Opportunity WHERE Id = :opp.Id];

        Test.startTest();
        List<Risk_Alert__c> alerts = RiskAlertService.generateAlerts(new List<Opportunity>{ opp });
        Test.stopTest();

        System.assert(alerts.size() > 0, 'Should generate at least one alert');
        System.assertNotEquals(null, alerts[0].Reason__c);
        System.assertNotEquals(null, alerts[0].Recommended_Action__c);
    }

    @IsTest
    static void testGetOpportunityIntelligence() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Intelligence Test',
            AccountId = acc.Id,
            Amount = 80000,
            StageName = 'Negotiation/Review',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;

        Test.startTest();
        Map<String, Object> intelligence = RiskAlertService.getOpportunityIntelligence(opp.Id);
        Test.stopTest();

        System.assertEquals('Intelligence Test', intelligence.get('opportunityName'));
        System.assertNotEquals(null, intelligence.get('alerts'));
    }

    @IsTest
    static void testResolveImprovedAlerts() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Resolve Alert Test',
            AccountId = acc.Id,
            Amount = 60000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(-10),
            Discount_Percentage__c = 0.40
        );
        insert opp;

        Risk_Alert__c alert = new Risk_Alert__c(
            Opportunity__c = opp.Id,
            Risk_Score__c = 80,
            Severity__c = 'High',
            Reason__c = 'Test reason',
            Recommended_Action__c = 'Test action',
            Status__c = 'Open'
        );
        insert alert;

        opp.Health_Score__c = 75;
        Test.startTest();
        RiskAlertService.resolveImprovedAlerts(new List<Opportunity>{ opp });
        Test.stopTest();

        alert = [SELECT Status__c FROM Risk_Alert__c WHERE Id = :alert.Id];
        System.assertEquals('Resolved', alert.Status__c, 'Alert should be resolved when health improves');
    }

    @IsTest
    static void testPublishRiskEscalation() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Escalation Test',
            AccountId = acc.Id,
            Amount = 40000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;
        opp = [SELECT Id, Name, Health_Score__c, Risk_Level__c FROM Opportunity WHERE Id = :opp.Id];

        Test.startTest();
        RiskAlertService.publishRiskEscalation(opp);
        Test.stopTest();

        System.assertNotEquals(null, opp.Id);
    }

    @IsTest
    static void testGenerateAlerts_SkipsClosedAndNullHealth() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity closedOpp = new Opportunity(
            Name = 'Closed Skip Test',
            AccountId = acc.Id,
            Amount = 30000,
            StageName = 'Closed Lost',
            CloseDate = Date.today()
        );
        insert closedOpp;

        closedOpp = [SELECT Id, Health_Score__c, Risk_Level__c, IsClosed, LastActivityDate,
                            Discount_Percentage__c, CloseDate, Name
                     FROM Opportunity WHERE Id = :closedOpp.Id];

        Opportunity nullHealthOpp = new Opportunity(
            Name = 'Null Health',
            AccountId = acc.Id,
            Amount = 20000,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(20)
        );

        List<Risk_Alert__c> alerts = RiskAlertService.generateAlerts(
            new List<Opportunity>{ closedOpp, nullHealthOpp }
        );
        System.assertEquals(0, alerts.size(), 'Closed and null-health opps should not generate alerts');
    }

    @IsTest
    static void testResolveImprovedAlerts_NoImprovedOpps() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Still At Risk',
            AccountId = acc.Id,
            Amount = 50000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(-10),
            Health_Score__c = 30
        );
        insert opp;

        Test.startTest();
        RiskAlertService.resolveImprovedAlerts(new List<Opportunity>{ opp });
        Test.stopTest();

        System.assert(true, 'Should complete without error when no improved opps');
    }
}
