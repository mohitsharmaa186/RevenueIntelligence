/**
 * @description SOSL-based global search across Opportunities, Accounts, Contacts, and Risk Alerts.
 */
public with sharing class GlobalSearchService {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> search(String searchTerm) {
        if (String.isBlank(searchTerm) || searchTerm.length() < 2) {
            return new Map<String, Object>{
                'opportunities' => new List<Map<String, Object>>(),
                'accounts' => new List<Map<String, Object>>(),
                'contacts' => new List<Map<String, Object>>(),
                'riskAlerts' => new List<Map<String, Object>>()
            };
        }

        String soslQuery = 'FIND {' + String.escapeSingleQuotes(searchTerm) + '}' +
            ' IN ALL FIELDS RETURNING' +
            ' Opportunity(Id, Name, Amount, StageName, Risk_Level__c, Health_Score__c LIMIT 10),' +
            ' Account(Id, Name, Industry, Total_Pipeline_Value__c LIMIT 10),' +
            ' Contact(Id, Name, Email, Phone, Account.Name LIMIT 10),' +
            ' Risk_Alert__c(Id, Name, Severity__c, Reason__c, Status__c, Opportunity__r.Name LIMIT 10)';

        List<List<SObject>> searchResults = Search.query(soslQuery);

        Map<String, Object> results = new Map<String, Object>();
        results.put('opportunities', formatOpportunities(searchResults.size() > 0 ? searchResults[0] : new List<SObject>()));
        results.put('accounts', formatAccounts(searchResults.size() > 1 ? searchResults[1] : new List<SObject>()));
        results.put('contacts', formatContacts(searchResults.size() > 2 ? searchResults[2] : new List<SObject>()));
        results.put('riskAlerts', formatRiskAlerts(searchResults.size() > 3 ? searchResults[3] : new List<SObject>()));

        return results;
    }

    private static List<Map<String, Object>> formatOpportunities(List<SObject> records) {
        List<Map<String, Object>> formatted = new List<Map<String, Object>>();
        for (SObject rec : records) {
            formatted.add(new Map<String, Object>{
                'id' => rec.get('Id'),
                'name' => rec.get('Name'),
                'amount' => rec.get('Amount'),
                'stage' => rec.get('StageName'),
                'riskLevel' => rec.get('Risk_Level__c'),
                'healthScore' => rec.get('Health_Score__c')
            });
        }
        return formatted;
    }

    private static List<Map<String, Object>> formatAccounts(List<SObject> records) {
        List<Map<String, Object>> formatted = new List<Map<String, Object>>();
        for (SObject rec : records) {
            formatted.add(new Map<String, Object>{
                'id' => rec.get('Id'),
                'name' => rec.get('Name'),
                'industry' => rec.get('Industry'),
                'pipelineValue' => rec.get('Total_Pipeline_Value__c')
            });
        }
        return formatted;
    }

    private static List<Map<String, Object>> formatContacts(List<SObject> records) {
        List<Map<String, Object>> formatted = new List<Map<String, Object>>();
        for (SObject rec : records) {
            formatted.add(new Map<String, Object>{
                'id' => rec.get('Id'),
                'name' => rec.get('Name'),
                'email' => rec.get('Email'),
                'phone' => rec.get('Phone')
            });
        }
        return formatted;
    }

    private static List<Map<String, Object>> formatRiskAlerts(List<SObject> records) {
        List<Map<String, Object>> formatted = new List<Map<String, Object>>();
        for (SObject rec : records) {
            formatted.add(new Map<String, Object>{
                'id' => rec.get('Id'),
                'name' => rec.get('Name'),
                'severity' => rec.get('Severity__c'),
                'reason' => rec.get('Reason__c'),
                'status' => rec.get('Status__c')
            });
        }
        return formatted;
    }
}
