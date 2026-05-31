/**
 * @description Selector for Risk_Alert__c queries.
 */
public with sharing class RiskAlertSelector {
    private static final List<String> BASE_FIELDS = new List<String>{
        'Id', 'Name', 'Opportunity__c', 'Risk_Score__c', 'Severity__c',
        'Reason__c', 'Recommended_Action__c', 'Status__c', 'CreatedDate'
    };

    public static List<Risk_Alert__c> selectByOpportunityIds(Set<Id> oppIds) {
        if (oppIds == null || oppIds.isEmpty()) {
            return new List<Risk_Alert__c>();
        }
        String soql = 'SELECT ' + String.join(BASE_FIELDS, ', ') +
            ' FROM Risk_Alert__c WHERE Opportunity__c IN :oppIds AND Status__c = \'Open\'';
        return Database.query(soql);
    }

    public static List<Risk_Alert__c> selectOpenAlerts() {
        String soql = 'SELECT ' + String.join(BASE_FIELDS, ', ') +
            ' FROM Risk_Alert__c WHERE Status__c = \'Open\' ORDER BY Risk_Score__c DESC';
        return Database.query(soql);
    }

    public static List<Risk_Alert__c> selectBySeverity(String severity) {
        String soql = 'SELECT ' + String.join(BASE_FIELDS, ', ') +
            ' FROM Risk_Alert__c WHERE Severity__c = :severity AND Status__c = \'Open\'';
        return Database.query(soql);
    }
}
