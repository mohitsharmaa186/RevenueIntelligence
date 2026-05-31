@IsTest
private class ApprovalRuleSelectorTest {
    @IsTest
    static void testSelectAllRules() {
        List<Approval_Rule__mdt> rules = ApprovalRuleSelector.selectAllRules();
        System.assert(rules.size() >= 4, 'Deployed custom metadata rules should exist');
    }

    @IsTest
    static void testSelectRuleForDiscount() {
        Approval_Rule__mdt managerRule = ApprovalRuleSelector.selectRuleForDiscount(0.05);
        Approval_Rule__mdt directorRule = ApprovalRuleSelector.selectRuleForDiscount(0.15);
        Approval_Rule__mdt vpRule = ApprovalRuleSelector.selectRuleForDiscount(0.25);
        Approval_Rule__mdt croRule = ApprovalRuleSelector.selectRuleForDiscount(0.35);

        System.assertNotEquals(null, managerRule, 'Manager rule should match 5% discount');
        System.assertNotEquals(null, directorRule, 'Director rule should match 15% discount');
        System.assertNotEquals(null, vpRule, 'VP rule should match 25% discount');
        System.assertNotEquals(null, croRule, 'CRO rule should match 35% discount');
    }
}
