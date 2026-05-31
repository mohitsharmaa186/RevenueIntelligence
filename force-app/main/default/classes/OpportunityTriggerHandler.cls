/**
 * @description Trigger handler for Opportunity — orchestrates health, risk, and approval logic.
 */
public with sharing class OpportunityTriggerHandler extends TriggerHandler {
    public override void beforeInsert() {
        DealHealthService.processOpportunities((List<Opportunity>) Trigger.new);
        for (Opportunity opp : (List<Opportunity>) Trigger.new) {
            ApprovalService.evaluateApprovalRequirement(opp);
        }
    }

    public override void beforeUpdate() {
        DealHealthService.processOpportunities((List<Opportunity>) Trigger.new);
        for (Opportunity opp : (List<Opportunity>) Trigger.new) {
            Opportunity oldOpp = ((Map<Id, Opportunity>) Trigger.oldMap).get(opp.Id);
            if (opp.Discount_Percentage__c != oldOpp.Discount_Percentage__c) {
                ApprovalService.evaluateApprovalRequirement(opp);
            }
        }
    }

    public override void afterInsert() {
        List<Risk_Alert__c> alerts = RiskAlertService.generateAlerts((List<Opportunity>) Trigger.new);
        if (!alerts.isEmpty()) {
            insert alerts;
        }
    }

    public override void afterUpdate() {
        List<Opportunity> oppsNeedingAlerts = new List<Opportunity>();
        for (Opportunity opp : (List<Opportunity>) Trigger.new) {
            Opportunity oldOpp = ((Map<Id, Opportunity>) Trigger.oldMap).get(opp.Id);
            if (opp.Health_Score__c != oldOpp.Health_Score__c && opp.Health_Score__c < RIP_Constants.HEALTH_SCORE_AT_RISK) {
                oppsNeedingAlerts.add(opp);
            }
            if (opp.Risk_Level__c == RIP_Constants.RISK_LEVEL_CRITICAL && oldOpp.Risk_Level__c != RIP_Constants.RISK_LEVEL_CRITICAL) {
                RiskAlertService.publishRiskEscalation(opp);
            }
        }

        RiskAlertService.resolveImprovedAlerts((List<Opportunity>) Trigger.new);

        List<Risk_Alert__c> newAlerts = RiskAlertService.generateAlerts(oppsNeedingAlerts);
        if (!newAlerts.isEmpty()) {
            insert newAlerts;
        }
    }
}
