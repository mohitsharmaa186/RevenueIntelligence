/**
 * @description Service layer for deal health score calculation and risk assessment.
 */
public with sharing class DealHealthService {
    /**
     * @description Calculates health score for a single opportunity.
     *              Factors: stage probability, activity recency, discount level, close date proximity.
     */
    public static Integer calculateHealthScore(Opportunity opp) {
        Integer score = 0;

        // Stage probability (0-30 points)
        Decimal stageProb = RIP_Constants.STAGE_PROBABILITY.containsKey(opp.StageName)
            ? RIP_Constants.STAGE_PROBABILITY.get(opp.StageName)
            : 10;
        score += (Integer)(stageProb * 0.3);

        // Activity recency (0-30 points)
        Integer daysSinceActivity = RIP_Util.daysSince(opp.LastActivityDate);
        if (daysSinceActivity <= RIP_Constants.ACTIVITY_DAYS_HEALTHY) {
            score += 30;
        } else if (daysSinceActivity <= RIP_Constants.ACTIVITY_DAYS_WARNING) {
            score += 20;
        } else if (daysSinceActivity <= RIP_Constants.ACTIVITY_DAYS_CRITICAL) {
            score += 10;
        }

        // Discount impact (0-20 points) — lower discount = healthier
        Decimal discountPct = opp.Discount_Percentage__c != null ? opp.Discount_Percentage__c * 100 : 0;
        if (discountPct <= 5) {
            score += 20;
        } else if (discountPct <= 15) {
            score += 15;
        } else if (discountPct <= 30) {
            score += 8;
        } else {
            score += 2;
        }

        // Close date proximity (0-20 points)
        if (opp.CloseDate != null) {
            Integer daysToClose = Date.today().daysBetween(opp.CloseDate);
            if (daysToClose >= 0 && daysToClose <= 30) {
                score += 20;
            } else if (daysToClose > 30 && daysToClose <= 90) {
                score += 15;
            } else if (daysToClose > 90) {
                score += 5;
            } else if (daysToClose < 0) {
                score += 0; // Past due
            }
        }

        return (Integer)RIP_Util.clamp(score, 0, RIP_Constants.HEALTH_SCORE_MAX);
    }

    /**
     * @description Calculates revenue confidence score based on health and stage.
     */
    public static Decimal calculateRevenueConfidence(Opportunity opp, Integer healthScore) {
        Decimal stageProb = RIP_Constants.STAGE_PROBABILITY.containsKey(opp.StageName)
            ? RIP_Constants.STAGE_PROBABILITY.get(opp.StageName)
            : 10;
        Decimal healthFactor = healthScore / 100.0;
        return RIP_Util.clamp(stageProb * healthFactor, 0, 100);
    }

    /**
     * @description Determines forecast category based on health score and stage.
     */
    public static String determineForecastCategory(Opportunity opp, Integer healthScore) {
        if (opp.IsClosed && opp.IsWon) {
            return RIP_Constants.FORECAST_CLOSED;
        }
        if (healthScore >= 80 && opp.Probability >= 75) {
            return RIP_Constants.FORECAST_COMMIT;
        }
        if (healthScore >= 60) {
            return RIP_Constants.FORECAST_BEST_CASE;
        }
        if (healthScore >= 40) {
            return RIP_Constants.FORECAST_PIPELINE;
        }
        return RIP_Constants.FORECAST_OMIT;
    }

    /**
     * @description Bulk process opportunities — calculates all intelligence fields.
     */
    public static void processOpportunities(List<Opportunity> opps) {
        for (Opportunity opp : opps) {
            if (opp.IsClosed) {
                continue;
            }
            Integer healthScore = calculateHealthScore(opp);
            opp.Health_Score__c = healthScore;
            opp.Risk_Level__c = RIP_Util.determineRiskLevel(healthScore);
            opp.Revenue_Confidence_Score__c = calculateRevenueConfidence(opp, healthScore);
            opp.Forecast_Category__c = determineForecastCategory(opp, healthScore);

            if (opp.Amount != null && opp.Discount_Percentage__c != null) {
                opp.Discount_Amount__c = (opp.Amount * opp.Discount_Percentage__c).setScale(2);
            }
        }
    }

    /**
     * @description Returns dashboard metrics for LWC consumption.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDashboardMetrics() {
        Map<String, Object> raw = OpportunitySelector.getDashboardMetrics();
        return new Map<String, Object>{
            'pipelineRevenue' => raw.get('totalPipeline') != null ? raw.get('totalPipeline') : 0,
            'totalDeals' => raw.get('totalDeals') != null ? raw.get('totalDeals') : 0,
            'atRiskRevenue' => raw.get('atRiskRevenue') != null ? raw.get('atRiskRevenue') : 0,
            'healthyDeals' => raw.get('healthyDeals') != null ? raw.get('healthyDeals') : 0,
            'riskDeals' => raw.get('riskDeals') != null ? raw.get('riskDeals') : 0,
            'wonRevenue' => raw.get('wonRevenue') != null ? raw.get('wonRevenue') : 0
        };
    }

    /**
     * @description Returns deal health data for a specific opportunity.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDealHealth(Id opportunityId) {
        List<Opportunity> opps = OpportunitySelector.selectByIds(new Set<Id>{ opportunityId });
        if (opps.isEmpty()) {
            return new Map<String, Object>();
        }
        Opportunity opp = opps[0];
        return new Map<String, Object>{
            'healthScore' => opp.Health_Score__c,
            'riskLevel' => opp.Risk_Level__c,
            'revenueConfidence' => opp.Revenue_Confidence_Score__c,
            'forecastCategory' => opp.Forecast_Category__c,
            'discountPercentage' => opp.Discount_Percentage__c,
            'approvalStatus' => opp.Approval_Status__c,
            'revenueImpact' => opp.Revenue_Impact__c,
            'daysSinceActivity' => opp.Days_Since_Last_Activity__c
        };
    }
}
