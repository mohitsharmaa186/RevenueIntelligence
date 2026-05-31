/**
 * @description AI-powered deal analysis service using OpenAI via Named Credential.
 */
public with sharing class AIDealAnalysisService {
    /**
     * @description Builds the analysis prompt from opportunity data.
     */
    public static String buildAnalysisPrompt(Opportunity opp, List<Risk_Alert__c> alerts) {
        String alertSummary = '';
        for (Risk_Alert__c alert : alerts) {
            alertSummary += '- ' + alert.Severity__c + ': ' + alert.Reason__c + '\n';
        }

        return 'Analyze this sales opportunity and provide a JSON response with keys: ' +
            'summary, riskExplanation, winProbability, recommendations (array of strings), confidenceScore (0-100).\n\n' +
            'Opportunity: ' + opp.Name + '\n' +
            'Amount: $' + opp.Amount + '\n' +
            'Stage: ' + opp.StageName + '\n' +
            'Close Date: ' + opp.CloseDate + '\n' +
            'Health Score: ' + opp.Health_Score__c + '/100\n' +
            'Risk Level: ' + opp.Risk_Level__c + '\n' +
            'Discount: ' + opp.Discount_Percentage__c + '%\n' +
            'Days Since Activity: ' + RIP_Util.daysSince(opp.LastActivityDate) + '\n' +
            'Active Risk Alerts:\n' + (String.isNotBlank(alertSummary) ? alertSummary : 'None');
    }

    /**
     * @description Calls OpenAI API via Named Credential and parses response.
     */
    public static Map<String, Object> analyzeDeal(Id opportunityId) {
        List<Opportunity> opps = OpportunitySelector.selectByIds(new Set<Id>{ opportunityId });
        if (opps.isEmpty()) {
            throw new AuraHandledException('Opportunity not found');
        }
        Opportunity opp = opps[0];
        List<Risk_Alert__c> alerts = RiskAlertSelector.selectByOpportunityIds(new Set<Id>{ opportunityId });

        Map<String, Object> analysisResult = performAnalysis(opp, alerts);

        Deal_Analysis__c analysis = new Deal_Analysis__c(
            Opportunity__c = opportunityId,
            AI_Summary__c = (String) analysisResult.get('summary'),
            Recommendations__c = JSON.serialize(analysisResult.get('recommendations')),
            Confidence_Score__c = (Decimal) analysisResult.get('confidenceScore'),
            Analysis_Date__c = DateTime.now()
        );
        insert analysis;

        analysisResult.put('analysisId', analysis.Id);
        return analysisResult;
    }

    /**
     * @description Performs AI analysis — uses Named Credential when available, falls back to rule-based.
     */
    private static Map<String, Object> performAnalysis(Opportunity opp, List<Risk_Alert__c> alerts) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:OpenAI_API/v1/chat/completions');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(60000);

            Map<String, Object> body = new Map<String, Object>{
                'model' => 'gpt-4o-mini',
                'messages' => new List<Map<String, String>>{
                    new Map<String, String>{
                        'role' => 'system',
                        'content' => 'You are a revenue intelligence analyst. Respond only with valid JSON.'
                    },
                    new Map<String, String>{
                        'role' => 'user',
                        'content' => buildAnalysisPrompt(opp, alerts)
                    }
                },
                'temperature' => 0.3
            };
            req.setBody(JSON.serialize(body));

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> choices = (List<Object>) responseBody.get('choices');
                if (!choices.isEmpty()) {
                    Map<String, Object> choice = (Map<String, Object>) choices[0];
                    Map<String, Object> message = (Map<String, Object>) choice.get('message');
                    String content = (String) message.get('content');
                    return (Map<String, Object>) JSON.deserializeUntyped(content);
                }
            }
        } catch (Exception e) {
            System.debug('AI API unavailable, using rule-based analysis: ' + e.getMessage());
        }

        return buildRuleBasedAnalysis(opp, alerts);
    }

    /**
     * @description Rule-based fallback when AI API is unavailable.
     */
    private static Map<String, Object> buildRuleBasedAnalysis(Opportunity opp, List<Risk_Alert__c> alerts) {
        Integer healthScore = opp.Health_Score__c != null ? opp.Health_Score__c.intValue() : 50;
        Decimal winProb = RIP_Constants.STAGE_PROBABILITY.containsKey(opp.StageName)
            ? RIP_Constants.STAGE_PROBABILITY.get(opp.StageName) * (healthScore / 100.0)
            : 10;

        List<String> recommendations = new List<String>();
        if (RIP_Util.daysSince(opp.LastActivityDate) > 14) {
            recommendations.add('Schedule follow-up within 48 hours');
        }
        if (opp.Discount_Percentage__c != null && opp.Discount_Percentage__c > 0.20) {
            recommendations.add('Negotiate discount reduction before close');
        }
        if (opp.CloseDate != null && opp.CloseDate < Date.today()) {
            recommendations.add('Update close date to reflect realistic timeline');
        }
        if (recommendations.isEmpty()) {
            recommendations.add('Continue current engagement strategy');
        }

        String riskExplanation = 'Deal health score is ' + healthScore + '/100 with ' +
            opp.Risk_Level__c + ' risk level. ' +
            (alerts.isEmpty() ? 'No active risk alerts.' : alerts.size() + ' active risk alert(s).');

        return new Map<String, Object>{
            'summary' => opp.Name + ' — $' + opp.Amount + ' opportunity at ' + opp.StageName +
                ' stage with ' + healthScore + '% health score.',
            'riskExplanation' => riskExplanation,
            'winProbability' => winProb.setScale(1),
            'recommendations' => recommendations,
            'confidenceScore' => healthScore
        };
    }

    @AuraEnabled
    public static Map<String, Object> getLatestAnalysis(Id opportunityId) {
        List<Deal_Analysis__c> analyses = [
            SELECT Id, AI_Summary__c, Recommendations__c, Confidence_Score__c, Analysis_Date__c
            FROM Deal_Analysis__c
            WHERE Opportunity__c = :opportunityId
            ORDER BY Analysis_Date__c DESC
            LIMIT 1
        ];

        if (analyses.isEmpty()) {
            return new Map<String, Object>();
        }

        Deal_Analysis__c analysis = analyses[0];
        List<String> recommendations = new List<String>();
        if (String.isNotBlank(analysis.Recommendations__c)) {
            recommendations = (List<String>) JSON.deserialize(analysis.Recommendations__c, List<String>.class);
        }

        return new Map<String, Object>{
            'analysisId' => analysis.Id,
            'summary' => analysis.AI_Summary__c,
            'recommendations' => recommendations,
            'confidenceScore' => analysis.Confidence_Score__c,
            'analysisDate' => analysis.Analysis_Date__c
        };
    }
}
