/**
 * @description Selector for Approval_Rule__mdt custom metadata.
 */
public with sharing class ApprovalRuleSelector {
    private static List<Approval_Rule__mdt> cachedRules;

    public static List<Approval_Rule__mdt> selectAllRules() {
        if (cachedRules == null) {
            cachedRules = [
                SELECT Id, DeveloperName, Minimum_Discount__c, Maximum_Discount__c, Approver_Role__c
                FROM Approval_Rule__mdt
                ORDER BY Minimum_Discount__c ASC
            ];
        }
        return cachedRules;
    }

    public static Approval_Rule__mdt selectRuleForDiscount(Decimal discountPercent) {
        // Discount_Percentage__c stores fractions (e.g. 0.30 for 30%).
        // Approval_Rule__mdt stores percentage points (e.g. 10, 20, 50).
        // Convert once here.
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
