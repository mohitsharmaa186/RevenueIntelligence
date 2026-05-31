/**
 * @description Selector for Approval_Rule__mdt custom metadata.
 */
public with sharing class ApprovalRuleSelector {
    public static List<Approval_Rule__mdt> selectAllRules() {
        return [
            SELECT Id, DeveloperName, Minimum_Discount__c, Maximum_Discount__c, Approver_Role__c
            FROM Approval_Rule__mdt
            ORDER BY Minimum_Discount__c ASC
        ];
    }

    public static Approval_Rule__mdt selectRuleForDiscount(Decimal discountPercent) {
        Decimal discountPoints = discountPercent != null ? discountPercent * 100 : 0;
        for (Approval_Rule__mdt rule : selectAllRules()) {
            Decimal minDiscount = rule.Minimum_Discount__c != null ? rule.Minimum_Discount__c : 0;
            Decimal maxDiscount = rule.Maximum_Discount__c != null ? rule.Maximum_Discount__c : 999;
            if (discountPoints >= minDiscount && discountPoints < maxDiscount) {
                return rule;
            }
        }
        return null;
    }
}
