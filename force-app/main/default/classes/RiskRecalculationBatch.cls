/**
 * @description Batch Apex to recalculate health scores and risk levels across all open opportunities.
 */
public with sharing class RiskRecalculationBatch implements Database.Batchable<SObject>, Database.Stateful {
    private Integer recordsProcessed = 0;
    private Integer alertsGenerated = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Amount, StageName, CloseDate, Probability, OwnerId,
                   IsClosed, IsWon, LastActivityDate, Health_Score__c, Risk_Level__c,
                   Discount_Percentage__c, Discount_Amount__c, Approval_Status__c,
                   Revenue_Confidence_Score__c, Forecast_Category__c
            FROM Opportunity
            WHERE IsClosed = false
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        DealHealthService.processOpportunities(scope);
        TriggerHandler.bypass('OpportunityTriggerHandler');
        try {
            update scope;
        } finally {
            TriggerHandler.clearBypass('OpportunityTriggerHandler');
        }
        recordsProcessed += scope.size();

        List<Risk_Alert__c> alerts = RiskAlertService.generateAlerts(scope);
        if (!alerts.isEmpty()) {
            insert alerts;
            alertsGenerated += alerts.size();
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('RiskRecalculationBatch complete. Processed: ' + recordsProcessed + ', Alerts: ' + alertsGenerated);
    }
}
