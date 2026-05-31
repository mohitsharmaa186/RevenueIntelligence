/**
 * @description REST API for external systems to manage opportunities.
 *              Endpoint: /services/apexrest/revenueintelligence/opportunities
 */
@RestResource(urlMapping='/revenueintelligence/opportunities/*')
global with sharing class RevenueIntelligenceRestAPI {
    @HttpGet
    global static void getOpportunities() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            String oppId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);

            if (String.isNotBlank(oppId) && oppId.length() >= 15) {
                List<Opportunity> opps = OpportunitySelector.selectByIds(new Set<Id>{ oppId });
                if (opps.isEmpty()) {
                    res.statusCode = 404;
                    res.responseBody = Blob.valueOf(JSON.serialize(
                        RIP_Util.buildErrorResponse('Opportunity not found', 404)
                    ));
                    return;
                }
                res.statusCode = 200;
                res.responseBody = Blob.valueOf(JSON.serialize(
                    RIP_Util.buildSuccessResponse(formatOpportunity(opps[0]))
                ));
            } else {
                List<Opportunity> opps = OpportunitySelector.selectOpenOpportunities();
                List<Map<String, Object>> formatted = new List<Map<String, Object>>();
                for (Opportunity opp : opps) {
                    formatted.add(formatOpportunity(opp));
                }
                res.statusCode = 200;
                res.responseBody = Blob.valueOf(JSON.serialize(
                    RIP_Util.buildSuccessResponse(formatted)
                ));
            }
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(
                RIP_Util.buildErrorResponse(e.getMessage(), 500)
            ));
        }
    }

    @HttpPost
    global static void createOpportunity() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());

            Opportunity opp = new Opportunity(
                Name = (String) body.get('name'),
                AccountId = (Id) body.get('accountId'),
                Amount = body.containsKey('amount') ? (Decimal) body.get('amount') : null,
                StageName = body.containsKey('stageName') ? (String) body.get('stageName') : 'Prospecting',
                CloseDate = body.containsKey('closeDate') ? Date.valueOf((String) body.get('closeDate')) : Date.today().addDays(30)
            );

            if (body.containsKey('discountPercentage')) {
                opp.Discount_Percentage__c = (Decimal) body.get('discountPercentage');
            }

            insert opp;

            res.statusCode = 201;
            res.responseBody = Blob.valueOf(JSON.serialize(
                RIP_Util.buildSuccessResponse(formatOpportunity(opp))
            ));
        } catch (Exception e) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(JSON.serialize(
                RIP_Util.buildErrorResponse(e.getMessage(), 400)
            ));
        }
    }

    @HttpPut
    global static void updateOpportunity() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            String oppId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());

            List<Opportunity> opps = OpportunitySelector.selectByIds(new Set<Id>{ oppId });
            if (opps.isEmpty()) {
                res.statusCode = 404;
                res.responseBody = Blob.valueOf(JSON.serialize(
                    RIP_Util.buildErrorResponse('Opportunity not found', 404)
                ));
                return;
            }

            Opportunity opp = opps[0];
            if (body.containsKey('name')) { opp.Name = (String) body.get('name'); }
            if (body.containsKey('amount')) { opp.Amount = (Decimal) body.get('amount'); }
            if (body.containsKey('stageName')) { opp.StageName = (String) body.get('stageName'); }
            if (body.containsKey('closeDate')) { opp.CloseDate = Date.valueOf((String) body.get('closeDate')); }
            if (body.containsKey('discountPercentage')) { opp.Discount_Percentage__c = (Decimal) body.get('discountPercentage'); }

            update opp;

            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(
                RIP_Util.buildSuccessResponse(formatOpportunity(opp))
            ));
        } catch (Exception e) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(JSON.serialize(
                RIP_Util.buildErrorResponse(e.getMessage(), 400)
            ));
        }
    }

    @HttpDelete
    global static void deleteOpportunity() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            String oppId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
            List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Id = :oppId LIMIT 1];

            if (opps.isEmpty()) {
                res.statusCode = 404;
                res.responseBody = Blob.valueOf(JSON.serialize(
                    RIP_Util.buildErrorResponse('Opportunity not found', 404)
                ));
                return;
            }

            delete opps[0];

            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(
                RIP_Util.buildSuccessResponse('Opportunity deleted successfully')
            ));
        } catch (Exception e) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(JSON.serialize(
                RIP_Util.buildErrorResponse(e.getMessage(), 400)
            ));
        }
    }

    private static Map<String, Object> formatOpportunity(Opportunity opp) {
        return new Map<String, Object>{
            'id' => opp.Id,
            'name' => opp.Name,
            'accountId' => opp.AccountId,
            'amount' => opp.Amount,
            'stageName' => opp.StageName,
            'closeDate' => opp.CloseDate,
            'healthScore' => opp.Health_Score__c,
            'riskLevel' => opp.Risk_Level__c,
            'discountPercentage' => opp.Discount_Percentage__c,
            'approvalStatus' => opp.Approval_Status__c,
            'forecastCategory' => opp.Forecast_Category__c,
            'revenueConfidence' => opp.Revenue_Confidence_Score__c
        };
    }
}
