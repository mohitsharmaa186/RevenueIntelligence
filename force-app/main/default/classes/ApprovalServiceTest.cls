@IsTest
private class ApprovalServiceTest {
    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Approval Test Account');
        insert acc;
    }

    @IsTest
    static void testEvaluateApprovalRequirement_LowDiscount() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Low Discount Test',
            AccountId = acc.Id,
            Amount = 50000,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            Discount_Percentage__c = 0.03
        );

        Test.startTest();
        insert opp;
        Test.stopTest();

        opp = [SELECT Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Pending', opp.Approval_Status__c);
    }

    @IsTest
    static void testEvaluateApprovalRequirement_NoDiscount() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'No Discount Test',
            AccountId = acc.Id,
            Amount = 50000,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30)
        );

        Test.startTest();
        insert opp;
        Test.stopTest();

        opp = [SELECT Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Not Required', opp.Approval_Status__c);
    }

    @IsTest
    static void testProcessDiscountApproval() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Approval Process Test',
            AccountId = acc.Id,
            Amount = 100000,
            StageName = 'Negotiation/Review',
            CloseDate = Date.today().addDays(15),
            Discount_Percentage__c = 0.15
        );
        insert opp;

        Test.startTest();
        ApprovalService.processDiscountApproval(opp, 'Approved', 'Looks good');
        Test.stopTest();

        List<Approval_Audit__c> audits = [SELECT Id, Action__c FROM Approval_Audit__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, audits.size());
        System.assertEquals('Approved', audits[0].Action__c);
    }

    @IsTest
    static void testGetApprovalInfo_NoRuleRequired() {
        Map<String, Object> info = ApprovalService.getApprovalInfo(0);
        System.assertEquals(true, info.get('requiresApproval'));
    }

    @IsTest
    static void testGetApprovalRule() {
        Approval_Rule__mdt rule = ApprovalService.getApprovalRule(0.20);
        System.assertNotEquals(null, rule);
    }

    @IsTest
    static void testProcessDiscountApproval_Rejected() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Rejected Approval Test',
            AccountId = acc.Id,
            Amount = 80000,
            StageName = 'Negotiation/Review',
            CloseDate = Date.today().addDays(15),
            Discount_Percentage__c = 0.20
        );
        insert opp;

        Test.startTest();
        ApprovalService.processDiscountApproval(opp, 'Rejected', 'Discount too high');
        Test.stopTest();

        opp = [SELECT Approval_Status__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Rejected', opp.Approval_Status__c);

        List<Approval_Audit__c> audits = [SELECT Action__c FROM Approval_Audit__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals('Rejected', audits[0].Action__c);
    }
}
