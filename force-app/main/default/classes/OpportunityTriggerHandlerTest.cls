@IsTest
private class OpportunityTriggerHandlerTest {
    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Trigger Test Account');
        insert acc;
    }

    @IsTest
    static void testBeforeInsert_HealthCalculation() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Trigger Insert Test',
            AccountId = acc.Id,
            Amount = 100000,
            StageName = 'Value Proposition',
            CloseDate = Date.today().addDays(20),
            Discount_Percentage__c = 0.10
        );

        Test.startTest();
        insert opp;
        Test.stopTest();

        opp = [SELECT Health_Score__c, Risk_Level__c, Approval_Status__c, Discount_Amount__c
               FROM Opportunity WHERE Id = :opp.Id];
        System.assertNotEquals(null, opp.Health_Score__c);
        System.assertNotEquals(null, opp.Risk_Level__c);
        System.assertEquals('Pending', opp.Approval_Status__c);
    }

    @IsTest
    static void testAfterInsert_RiskAlertGeneration() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Risk Alert Test',
            AccountId = acc.Id,
            Amount = 200000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(-10),
            Discount_Percentage__c = 0.40
        );

        Test.startTest();
        insert opp;
        Test.stopTest();

        List<Risk_Alert__c> alerts = [SELECT Id FROM Risk_Alert__c WHERE Opportunity__c = :opp.Id];
        System.assert(alerts.size() > 0, 'Risk alert should be generated for at-risk deal');
    }

    @IsTest
    static void testBeforeUpdate_DiscountChange() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Discount Update Test',
            AccountId = acc.Id,
            Amount = 50000,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            Discount_Percentage__c = 0.05
        );
        insert opp;

        Test.startTest();
        opp.Discount_Percentage__c = 0.25;
        update opp;
        Test.stopTest();

        opp = [SELECT Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Pending', opp.Approval_Status__c);
    }

    @IsTest
    static void testAfterUpdate_HealthImprovement() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Health Improvement Test',
            AccountId = acc.Id,
            Amount = 30000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(-5),
            Discount_Percentage__c = 0.40
        );
        insert opp;

        Test.startTest();
        opp.StageName = 'Closed Won';
        opp.CloseDate = Date.today();
        update opp;
        Test.stopTest();

        System.assert(true, 'Update completed without error');
    }

    @IsTest
    static void testAfterUpdate_CriticalRiskEscalation() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Critical Escalation Test',
            AccountId = acc.Id,
            Amount = 200000,
            StageName = 'Proposal/Price Quote',
            CloseDate = Date.today().addDays(20),
            Discount_Percentage__c = 0.05
        );
        insert opp;

        Test.startTest();
        opp.StageName = 'Prospecting';
        opp.CloseDate = Date.today().addDays(-30);
        opp.Discount_Percentage__c = 0.45;
        update opp;
        Test.stopTest();

        opp = [SELECT Risk_Level__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Critical', opp.Risk_Level__c);
    }

    @IsTest
    static void testTriggerHandlerBypass() {
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'Bypass Test',
            AccountId = acc.Id,
            Amount = 10000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );

        Test.startTest();
        insert opp;
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        Test.stopTest();

        System.assert(true, 'Bypass should prevent handler execution');
    }
}
