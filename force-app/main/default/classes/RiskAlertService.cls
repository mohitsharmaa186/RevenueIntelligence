/**
 * @description Service layer for risk alert generation and management.
 */
public with sharing class RiskAlertService {
    /**
     * @description Generates risk alerts for opportunities based on health scores.
     */
    public static List<Risk_Alert__c> generateAlerts(List<Opportunity> opps) {
        // Collect candidate IDs first
        Set<Id> candidateIds = new Set<Id>();
        for (Opportunity opp : opps) {
            if (opp.IsClosed || opp.Health_Score__c == null) {
                continue;
            }
            if (opp.Health_Score__c < RIP_Constants.HEALTH_SCORE_AT_RISK) {
                candidateIds.add(opp.Id);
            }
        }

        // Exclude opps that already have open alerts
        Set<Id> alreadyAlerted = new Set<Id>();
        if (!candidateIds.isEmpty()) {
            for (Risk_Alert__c a : [SELECT Opportunity__c FROM Risk_Alert__c
                                    WHERE Opportunity__c IN :candidateIds
                                    AND Status__c = :RIP_Constants.ALERT_STATUS_OPEN]) {
                alreadyAlerted.add(a.Opportunity__c);
            }
        }

        List<Risk_Alert__c> alertsToInsert = new List<Risk_Alert__c>();
        for (Opportunity opp : opps) {
            if (candidateIds.contains(opp.Id) && !alreadyAlerted.contains(opp.Id)) {
                alertsToInsert.add(buildAlert(opp));
            }
        }

        return alertsToInsert;
    }

    private static Risk_Alert__c buildAlert(Opportunity opp) {
        String riskLevel = opp.Risk_Level__c;
        Integer riskScore = 100 - (Integer)(opp.Health_Score__c != null ? opp.Health_Score__c : 0);

        String reason = buildReason(opp);
        String recommendedAction = buildRecommendedAction(opp);

        return new Risk_Alert__c(
            Opportunity__c = opp.Id,
            Risk_Score__c = riskScore,
            Severity__c = RIP_Util.determineSeverity(riskLevel),
            Reason__c = reason,
            Recommended_Action__c = recommendedAction,
            Status__c = RIP_Constants.ALERT_STATUS_OPEN
        );
    }

    private static String buildReason(Opportunity opp) {
        List<String> reasons = new List<String>();
        Integer daysSince = RIP_Util.daysSince(opp.LastActivityDate);

        if (daysSince > RIP_Constants.ACTIVITY_DAYS_CRITICAL) {
            reasons.add('No activity in ' + daysSince + ' days');
        } else if (daysSince > RIP_Constants.ACTIVITY_DAYS_WARNING) {
            reasons.add('Stale activity — ' + daysSince + ' days since last touch');
        }

        if (opp.Discount_Percentage__c != null && opp.Discount_Percentage__c > 0.30) {
            reasons.add('High discount of ' + (opp.Discount_Percentage__c * 100).setScale(1) + '% eroding margin');
        }

        if (opp.CloseDate != null && opp.CloseDate < Date.today()) {
            reasons.add('Close date has passed without resolution');
        }

        if (opp.Health_Score__c != null && opp.Health_Score__c < 20) {
            reasons.add('Critical health score of ' + opp.Health_Score__c);
        }

        return reasons.isEmpty() ? 'Deal health below acceptable threshold' : String.join(reasons, '; ');
    }

    private static String buildRecommendedAction(Opportunity opp) {
        Integer daysSince = RIP_Util.daysSince(opp.LastActivityDate);

        if (daysSince > RIP_Constants.ACTIVITY_DAYS_WARNING) {
            return 'Schedule immediate follow-up call with decision maker';
        }
        if (opp.Discount_Percentage__c != null && opp.Discount_Percentage__c > 0.30) {
            return 'Review discount strategy with sales leadership';
        }
        if (opp.CloseDate != null && opp.CloseDate < Date.today()) {
            return 'Update close date or advance to next stage';
        }
        return 'Conduct deal review with account team';
    }

    /**
     * @description Resolves existing open alerts when health improves.
     */
    public static void resolveImprovedAlerts(List<Opportunity> opps) {
        Set<Id> improvedOppIds = new Set<Id>();
        for (Opportunity opp : opps) {
            if (opp.Health_Score__c != null && opp.Health_Score__c >= RIP_Constants.HEALTH_SCORE_AT_RISK) {
                improvedOppIds.add(opp.Id);
            }
        }

        if (improvedOppIds.isEmpty()) {
            return;
        }

        List<Risk_Alert__c> openAlerts = RiskAlertSelector.selectByOpportunityIds(improvedOppIds);
        for (Risk_Alert__c alert : openAlerts) {
            alert.Status__c = RIP_Constants.ALERT_STATUS_RESOLVED;
        }

        if (!openAlerts.isEmpty()) {
            update openAlerts;
        }
    }

    /**
     * @description Publishes risk escalation platform event for a single opportunity.
     */
    public static void publishRiskEscalation(Opportunity opp) {
        DealApprovedEvent__e evt = new DealApprovedEvent__e(
            Opportunity_Id__c = opp.Id,
            Event_Type__c = RIP_Constants.EVENT_RISK_ESCALATED,
            Message__c = 'Risk escalated for ' + opp.Name + ' — Health Score: ' + opp.Health_Score__c
        );
        EventBus.publish(evt);
    }

    /**
     * @description Publishes risk escalation platform events in bulk — single EventBus.publish call.
     */
    public static void publishRiskEscalations(List<Opportunity> opps) {
        List<DealApprovedEvent__e> events = new List<DealApprovedEvent__e>();
        for (Opportunity opp : opps) {
            events.add(new DealApprovedEvent__e(
                Opportunity_Id__c = opp.Id,
                Event_Type__c = RIP_Constants.EVENT_RISK_ESCALATED,
                Message__c = 'Risk escalated for ' + opp.Name + ' — Health Score: ' + opp.Health_Score__c
            ));
        }
        EventBus.publish(events);
    }

    /**
     * @description Returns intelligence panel data for LWC.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getOpportunityIntelligence(Id opportunityId) {
        List<Opportunity> opps = OpportunitySelector.selectByIds(new Set<Id>{ opportunityId });
        List<Risk_Alert__c> alerts = RiskAlertSelector.selectByOpportunityIds(new Set<Id>{ opportunityId });

        Map<String, Object> intelligence = new Map<String, Object>();
        if (!opps.isEmpty()) {
            Opportunity opp = opps[0];
            intelligence.put('opportunityName', opp.Name);
            intelligence.put('healthScore', opp.Health_Score__c);
            intelligence.put('riskLevel', opp.Risk_Level__c);
            intelligence.put('forecastCategory', opp.Forecast_Category__c);
            intelligence.put('revenueConfidence', opp.Revenue_Confidence_Score__c);
            intelligence.put('discountPercentage', opp.Discount_Percentage__c);
            intelligence.put('approvalStatus', opp.Approval_Status__c);
        }

        List<Map<String, Object>> alertData = new List<Map<String, Object>>();
        for (Risk_Alert__c alert : alerts) {
            alertData.add(new Map<String, Object>{
                'id' => alert.Id,
                'severity' => alert.Severity__c,
                'reason' => alert.Reason__c,
                'recommendedAction' => alert.Recommended_Action__c,
                'riskScore' => alert.Risk_Score__c
            });
        }
        intelligence.put('alerts', alertData);

        return intelligence;
    }
}
