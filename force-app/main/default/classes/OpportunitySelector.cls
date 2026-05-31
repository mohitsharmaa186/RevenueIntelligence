/**
 * @description Selector for Opportunity queries — centralizes SOQL.
 */
public with sharing class OpportunitySelector {
    private static final List<String> BASE_FIELDS = new List<String>{
        'Id', 'Name', 'AccountId', 'Amount', 'StageName', 'CloseDate',
        'Probability', 'OwnerId', 'IsClosed', 'IsWon', 'LastActivityDate',
        'Health_Score__c', 'Risk_Level__c', 'Discount_Percentage__c',
        'Discount_Amount__c', 'Approval_Status__c', 'Revenue_Confidence_Score__c',
        'Forecast_Category__c', 'Days_Since_Last_Activity__c', 'Revenue_Impact__c'
    };

    public static List<Opportunity> selectByIds(Set<Id> oppIds) {
        if (oppIds == null || oppIds.isEmpty()) {
            return new List<Opportunity>();
        }
        String soql = 'SELECT ' + String.join(BASE_FIELDS, ', ') +
            ' FROM Opportunity WHERE Id IN :oppIds';
        return Database.query(soql);
    }

    public static List<Opportunity> selectOpenOpportunities() {
        String soql = 'SELECT ' + String.join(BASE_FIELDS, ', ') +
            ' FROM Opportunity WHERE IsClosed = false ORDER BY Amount DESC';
        return Database.query(soql);
    }

    public static List<Opportunity> selectAtRiskOpportunities() {
        String soql = 'SELECT ' + String.join(BASE_FIELDS, ', ') +
            ' FROM Opportunity WHERE IsClosed = false' +
            ' AND Risk_Level__c IN (\'High\', \'Critical\')' +
            ' ORDER BY Amount DESC';
        return Database.query(soql);
    }

    public static List<Opportunity> selectByAccountId(Id accountId) {
        String soql = 'SELECT ' + String.join(BASE_FIELDS, ', ') +
            ' FROM Opportunity WHERE AccountId = :accountId ORDER BY CloseDate ASC';
        return Database.query(soql);
    }

    public static Map<String, Object> getDashboardMetrics() {
        AggregateResult[] pipelineResults = [
            SELECT SUM(Amount) totalPipeline, COUNT(Id) totalDeals
            FROM Opportunity
            WHERE IsClosed = false
        ];

        AggregateResult[] atRiskResults = [
            SELECT SUM(Amount) atRiskRevenue, COUNT(Id) riskDeals
            FROM Opportunity
            WHERE IsClosed = false AND Risk_Level__c IN ('High', 'Critical')
        ];

        AggregateResult[] healthyResults = [
            SELECT COUNT(Id) healthyDeals
            FROM Opportunity
            WHERE IsClosed = false AND Health_Score__c >= 70
        ];

        AggregateResult[] wonResults = [
            SELECT SUM(Amount) wonRevenue
            FROM Opportunity
            WHERE IsClosed = true AND IsWon = true
        ];

        Map<String, Object> metrics = new Map<String, Object>();
        if (!pipelineResults.isEmpty()) {
            metrics.put('totalPipeline', pipelineResults[0].get('totalPipeline'));
            metrics.put('totalDeals', pipelineResults[0].get('totalDeals'));
        }
        if (!atRiskResults.isEmpty()) {
            metrics.put('atRiskRevenue', atRiskResults[0].get('atRiskRevenue'));
            metrics.put('riskDeals', atRiskResults[0].get('riskDeals'));
        }
        if (!healthyResults.isEmpty()) {
            metrics.put('healthyDeals', healthyResults[0].get('healthyDeals'));
        }
        if (!wonResults.isEmpty()) {
            metrics.put('wonRevenue', wonResults[0].get('wonRevenue'));
        }
        return metrics;
    }

    public static AggregateResult[] getForecastMetrics() {
        return [
            SELECT Forecast_Category__c category, SUM(Amount) totalAmount, COUNT(Id) dealCount
            FROM Opportunity
            WHERE IsClosed = false AND Forecast_Category__c != null
            GROUP BY Forecast_Category__c
        ];
    }
}
