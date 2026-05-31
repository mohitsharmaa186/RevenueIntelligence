// =============================================================================
// Revenue Intelligence Platform — Full Inline Anonymous Apex
// =============================================================================
//
// Use this script if you prefer a self-contained approach without deploying
// RIP_SampleDataLoader. Paste into Developer Console → Execute Anonymous.
//
// NOTE: Requires TriggerHandler class to be deployed (Phase 1).
//       Bypasses OpportunityTrigger to prevent duplicate auto-generated alerts.
// =============================================================================

TriggerHandler.bypass('OpportunityTriggerHandler');

try {
    // --- 1. Accounts (50) ---
    List<String> industries = new List<String>{
        'Technology','Healthcare','Financial Services','Manufacturing','Retail',
        'Energy','Telecommunications','Media','Education','Government'
    };
    List<String> prefixes = new List<String>{
        'Apex','Summit','Horizon','Pinnacle','Vertex','Nova','Quantum','Sterling'
    };
    List<String> suffixes = new List<String>{
        'Systems','Solutions','Group','Corp','Industries','Partners','Technologies'
    };

    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 50; i++) {
        accounts.add(new Account(
            Name = 'RIP - ' + prefixes[Math.mod(i, prefixes.size())] + ' '
                 + suffixes[Math.mod(i / 8, suffixes.size())] + ' ' + (i + 1),
            Industry = industries[Math.mod(i, industries.size())],
            Type = Math.mod(i, 3) == 0 ? 'Customer' : 'Prospect',
            AnnualRevenue = 500000 + (Math.random() * 49500000),
            BillingCity = 'San Francisco',
            BillingState = 'CA',
            BillingCountry = 'United States'
        ));
    }
    insert accounts;
    System.debug('Inserted ' + accounts.size() + ' accounts');

    // --- 2. Opportunities (200) ---
    List<String> stages = new List<String>{
        'Prospecting','Qualification','Needs Analysis','Value Proposition',
        'Proposal/Price Quote','Negotiation/Review'
    };
    List<String> dealTypes = new List<String>{
        'Enterprise License','Platform Upgrade','Annual Renewal',
        'Professional Services','Multi-Year Agreement','Expansion Deal'
    };
    List<String> riskLevels = new List<String>{ 'Low','Medium','High','Critical' };
    List<String> forecasts = new List<String>{ 'Pipeline','Best Case','Commit','Omitted' };
    List<String> approvals = new List<String>{ 'Not Required','Pending','Approved','Rejected' };

    List<Opportunity> opps = new List<Opportunity>();
    for (Integer i = 0; i < 200; i++) {
        Integer health = Math.mod(i, 10) <= 3 ? 75 + Integer.valueOf(Math.random() * 20)
                     : Math.mod(i, 10) <= 6 ? 40 + Integer.valueOf(Math.random() * 25)
                     : 10 + Integer.valueOf(Math.random() * 28);
        Decimal disc = Math.mod(i, 5) == 0 ? 0 : (0.05 + Math.random() * 0.35).setScale(2);
        Decimal amt = (25000 + Math.random() * 2475000).setScale(0);

        opps.add(new Opportunity(
            Name = 'RIP - ' + dealTypes[Math.mod(i, dealTypes.size())] + ' — ' + accounts[Math.mod(i, 50)].Name,
            AccountId = accounts[Math.mod(i, 50)].Id,
            Amount = amt,
            StageName = stages[Math.mod(i, stages.size())],
            CloseDate = Date.today().addDays(Integer.valueOf(7 + Math.random() * 173)),
            Health_Score__c = health,
            Risk_Level__c = health >= 70 ? 'Low' : health >= 40 ? 'Medium' : health >= 20 ? 'High' : 'Critical',
            Discount_Percentage__c = disc,
            Discount_Amount__c = (amt * disc).setScale(2),
            Approval_Status__c = disc > 0 ? approvals[Math.mod(i, 4)] : 'Not Required',
            Revenue_Confidence_Score__c = (health * 0.6).setScale(1),
            Forecast_Category__c = forecasts[Math.mod(i, 4)]
        ));
    }
    insert opps;
    System.debug('Inserted ' + opps.size() + ' opportunities');

    // --- 3. Risk Alerts (50) ---
    List<String> reasons = new List<String>{
        'No activity in 45 days — deal has gone dark',
        'Close date passed without stage advancement',
        'High discount eroding margin and deal value',
        'Stakeholder engagement dropped after proposal',
        'Competitor displacement risk identified'
    };
    List<String> actions = new List<String>{
        'Schedule follow-up with decision maker',
        'Review discount strategy with leadership',
        'Update close date or advance stage',
        'Conduct deal review with account team'
    };

    List<Risk_Alert__c> alerts = new List<Risk_Alert__c>();
    for (Integer i = 0; i < 50; i++) {
        Opportunity o = opps[Math.mod(i * 4, 200)];
        alerts.add(new Risk_Alert__c(
            Opportunity__c = o.Id,
            Risk_Score__c = 100 - Integer.valueOf(o.Health_Score__c),
            Severity__c = o.Risk_Level__c == 'Critical' ? 'Critical' : o.Risk_Level__c == 'High' ? 'High' : 'Medium',
            Reason__c = reasons[Math.mod(i, reasons.size())],
            Recommended_Action__c = actions[Math.mod(i, actions.size())],
            Status__c = Math.mod(i, 3) == 0 ? 'Open' : Math.mod(i, 3) == 1 ? 'Acknowledged' : 'Resolved'
        ));
    }
    insert alerts;
    System.debug('Inserted ' + alerts.size() + ' risk alerts');

    // --- 4. Deal Analyses (50) ---
    List<Deal_Analysis__c> analyses = new List<Deal_Analysis__c>();
    for (Integer i = 0; i < 50; i++) {
        Opportunity o = opps[Math.mod(i * 3, 200)];
        analyses.add(new Deal_Analysis__c(
            Opportunity__c = o.Id,
            AI_Summary__c = 'AI analysis for ' + o.Name + ': '
                + (o.Health_Score__c >= 70 ? 'Healthy deal with strong close potential.'
                   : 'At-risk deal requiring immediate sales intervention.'),
            Recommendations__c = '["Schedule executive briefing","Confirm budget authority","Prepare ROI analysis"]',
            Confidence_Score__c = o.Health_Score__c,
            Analysis_Date__c = DateTime.now().addDays(-Integer.valueOf(Math.random() * 30))
        ));
    }
    insert analyses;
    System.debug('Inserted ' + analyses.size() + ' deal analyses');

    // --- 5. Approval Audits (50) ---
    List<Approval_Audit__c> audits = new List<Approval_Audit__c>();
    List<String> auditComments = new List<String>{
        'Approved — within policy guidelines.',
        'Rejected — discount exceeds margin threshold.',
        'Escalated to VP Sales for final decision.',
        'Approved — strategic account exception granted.'
    };
    for (Integer i = 0; i < 50; i++) {
        Opportunity o = opps[Math.mod(i * 2, 200)];
        Decimal prev = o.Discount_Percentage__c != null ? o.Discount_Percentage__c : 0;
        audits.add(new Approval_Audit__c(
            Opportunity__c = o.Id,
            Approver__c = UserInfo.getUserId(),
            Action__c = Math.mod(i, 3) == 0 ? 'Approved' : Math.mod(i, 3) == 1 ? 'Rejected' : 'Escalated',
            Comments__c = auditComments[Math.mod(i, auditComments.size())],
            Previous_Discount__c = prev,
            New_Discount__c = Math.min(prev + 0.02, 0.50),
            Approval_Date__c = DateTime.now().addDays(-Integer.valueOf(1 + Math.random() * 59))
        ));
    }
    insert audits;
    System.debug('Inserted ' + audits.size() + ' approval audits');

    System.debug('=== SAMPLE DATA LOAD COMPLETE ===');

} finally {
    TriggerHandler.clearBypass('OpportunityTriggerHandler');
}
