@IsTest
private class RiskAlertSelectorTest {
    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Alert Selector Account');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'Alert Selector Opp',
            AccountId = acc.Id,
            Amount = 80000,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(15)
        );
        insert opp;
        insert new List<Risk_Alert__c>{
            new Risk_Alert__c(
                Opportunity__c = opp.Id,
                Risk_Score__c = 70,
                Severity__c = 'High',
                Reason__c = 'Test reason',
                Recommended_Action__c = 'Test action',
                Status__c = 'Open'
            ),
            new Risk_Alert__c(
                Opportunity__c = opp.Id,
                Risk_Score__c = 40,
                Severity__c = 'Medium',
                Reason__c = 'Resolved reason',
                Recommended_Action__c = 'Resolved action',
                Status__c = 'Resolved'
            )
        };
    }

    @IsTest
    static void testSelectByOpportunityIds() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        System.assertEquals(0, RiskAlertSelector.selectByOpportunityIds(null).size());
        System.assertEquals(0, RiskAlertSelector.selectByOpportunityIds(new Set<Id>()).size());

        List<Risk_Alert__c> alerts = RiskAlertSelector.selectByOpportunityIds(new Set<Id>{ opp.Id });
        System.assertEquals(1, alerts.size());
        System.assertEquals('Open', alerts[0].Status__c);
    }

    @IsTest
    static void testSelectOpenAlertsAndBySeverity() {
        List<Risk_Alert__c> openAlerts = RiskAlertSelector.selectOpenAlerts();
        System.assertEquals(1, openAlerts.size());

        List<Risk_Alert__c> highAlerts = RiskAlertSelector.selectBySeverity('High');
        System.assertEquals(1, highAlerts.size());
    }
}
