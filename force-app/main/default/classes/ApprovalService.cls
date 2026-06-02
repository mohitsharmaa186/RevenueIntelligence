/**
 * @description Metadata-driven approval engine — no hardcoded approval rules.
 */
public with sharing class ApprovalService {
    /**
     * @description Determines the required approver role based on discount percentage.
     */
    public static Approval_Rule__mdt getApprovalRule(Decimal discountPercent) {
        return ApprovalRuleSelector.selectRuleForDiscount(discountPercent);
    }

    /**
     * @description Processes discount approval request for an opportunity.
     */
    public static void processDiscountApproval(Opportunity opp, String action, String comments) {
        Approval_Rule__mdt rule = getApprovalRule(opp.Discount_Percentage__c);

        Approval_Audit__c audit = new Approval_Audit__c(
            Opportunity__c = opp.Id,
            Approver__c = UserInfo.getUserId(),
            Action__c = action,
            Comments__c = comments,
            Previous_Discount__c = opp.Discount_Percentage__c,
            New_Discount__c = opp.Discount_Percentage__c,
            Approval_Date__c = DateTime.now()
        );
        insert audit;

        if (action == 'Approved') {
            opp.Approval_Status__c = RIP_Constants.APPROVAL_STATUS_APPROVED;
            publishApprovalEvent(opp, RIP_Constants.EVENT_DEAL_APPROVED);
        } else if (action == 'Rejected') {
            opp.Approval_Status__c = RIP_Constants.APPROVAL_STATUS_REJECTED;
            publishApprovalEvent(opp, RIP_Constants.EVENT_DEAL_REJECTED);
        }
        update opp;
    }

    /**
     * @description Sets approval status when discount changes.
     */
    public static void evaluateApprovalRequirement(Opportunity opp) {
        Decimal discount = opp.Discount_Percentage__c != null ? opp.Discount_Percentage__c : 0;

        if (discount <= 0) {
            opp.Approval_Status__c = RIP_Constants.APPROVAL_STATUS_NOT_REQUIRED;
            return;
        }

        Approval_Rule__mdt rule = getApprovalRule(discount);
        if (rule != null) {
            opp.Approval_Status__c = RIP_Constants.APPROVAL_STATUS_PENDING;
        }
    }

    /**
     * @description Returns approval info for LWC display.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getApprovalInfo(Decimal discountPercent) {
        Approval_Rule__mdt rule = getApprovalRule(discountPercent);
        Map<String, Object> info = new Map<String, Object>();
        if (rule != null) {
            info.put('approverRole', rule.Approver_Role__c);
            info.put('minDiscount', rule.Minimum_Discount__c);
            info.put('maxDiscount', rule.Maximum_Discount__c);
            info.put('requiresApproval', true);
        } else {
            info.put('requiresApproval', false);
        }
        return info;
    }

    private static void publishApprovalEvent(Opportunity opp, String eventType) {
        DealApprovedEvent__e evt = new DealApprovedEvent__e(
            Opportunity_Id__c = opp.Id,
            Event_Type__c = eventType,
            Message__c = eventType + ' for ' + opp.Name
        );
        EventBus.publish(evt);
    }
}
