/**
 * @description Loads realistic demo data for the Revenue Intelligence Platform.
 *              Run via Anonymous Apex: RIP_SampleDataLoader.load();
 */
public with sharing class RIP_SampleDataLoader {
    private static final Integer ACCOUNT_COUNT = 50;
    private static final Integer OPPORTUNITY_COUNT = 200;
    private static final Integer RISK_ALERT_COUNT = 50;
    private static final Integer DEAL_ANALYSIS_COUNT = 50;
    private static final Integer APPROVAL_AUDIT_COUNT = 50;

    private static final List<String> INDUSTRIES = new List<String>{
        'Technology', 'Healthcare', 'Financial Services', 'Manufacturing',
        'Retail', 'Energy', 'Telecommunications', 'Media', 'Education', 'Government'
    };

    private static final List<String> COMPANY_PREFIXES = new List<String>{
        'Apex', 'Summit', 'Horizon', 'Pinnacle', 'Vertex', 'Nova', 'Quantum',
        'Sterling', 'Meridian', 'Cascade', 'Atlas', 'Prism', 'Nexus', 'Vanguard',
        'Catalyst', 'Fusion', 'Helix', 'Orbit', 'Pulse', 'Zenith'
    };

    private static final List<String> COMPANY_SUFFIXES = new List<String>{
        'Systems', 'Solutions', 'Group', 'Corp', 'Industries', 'Partners',
        'Technologies', 'Enterprises', 'Global', 'Dynamics'
    };

    private static final List<String> OPEN_STAGES = new List<String>{
        'Prospecting', 'Qualification', 'Needs Analysis', 'Value Proposition',
        'Id. Decision Makers', 'Perception Analysis', 'Proposal/Price Quote', 'Negotiation/Review'
    };

    private static final List<String> RISK_LEVELS = new List<String>{ 'Low', 'Medium', 'High', 'Critical' };
    private static final List<String> FORECAST_CATS = new List<String>{ 'Pipeline', 'Best Case', 'Commit', 'Omitted' };
    private static final List<String> APPROVAL_STATUSES = new List<String>{ 'Not Required', 'Pending', 'Approved', 'Rejected' };
    private static final List<String> ALERT_SEVERITIES = new List<String>{ 'Low', 'Medium', 'High', 'Critical' };
    private static final List<String> ALERT_STATUSES = new List<String>{ 'Open', 'Acknowledged', 'Resolved' };
    private static final List<String> AUDIT_ACTIONS = new List<String>{ 'Approved', 'Rejected', 'Escalated' };

    private static final List<String> RISK_REASONS = new List<String>{
        'No activity in 45 days — deal has gone dark',
        'Close date passed without stage advancement',
        'High discount of 35% eroding margin and deal value',
        'Stakeholder engagement dropped after proposal stage',
        'Competitor displacement risk identified in last QBR',
        'Budget reallocation delayed procurement timeline',
        'Champion left the organization — relationship at risk',
        'Critical health score below acceptable threshold',
        'Stale activity — 21 days since last touch',
        'Deal stuck in Negotiation/Review for 60+ days'
    };

    private static final List<String> RECOMMENDED_ACTIONS = new List<String>{
        'Schedule immediate follow-up call with decision maker',
        'Review discount strategy with sales leadership',
        'Update close date or advance to next stage',
        'Conduct deal review with account team',
        'Engage executive sponsor for top-down alignment',
        'Prepare competitive displacement battle card',
        'Re-qualify budget and timeline with economic buyer'
    };

    private static final List<String> AI_SUMMARIES = new List<String>{
        'Strong enterprise opportunity with solid stakeholder engagement. Deal progressing through evaluation with moderate competitive pressure.',
        'Mid-market deal showing signs of stall — recommend re-engagement within 48 hours to maintain momentum.',
        'High-value strategic account with multi-year potential. Discount request requires VP approval but win probability remains favorable.',
        'At-risk deal due to prolonged inactivity. Economic buyer unresponsive — consider executive outreach.',
        'Healthy pipeline opportunity with clear path to close. Technical validation complete, awaiting final procurement review.',
        'Complex deal with multiple stakeholders. Risk elevated due to budget cycle timing — monitor closely.',
        'Competitive bake-off in progress. Strong product fit but pricing pressure from incumbent vendor.',
        'Renewal expansion opportunity with existing customer. Low risk, high confidence — prioritize for commit forecast.'
    };

    public static void load() {
        load(false);
    }

    public static void load(Boolean deleteExisting) {
        if (deleteExisting) {
            deleteExistingData();
        }

        TriggerHandler.bypass('OpportunityTriggerHandler');

        try {
            List<Account> accounts = createAccounts();
            insert accounts;

            List<Opportunity> opportunities = createOpportunities(accounts);
            insert opportunities;

            List<Risk_Alert__c> alerts = createRiskAlerts(opportunities);
            insert alerts;

            List<Deal_Analysis__c> analyses = createDealAnalyses(opportunities);
            insert analyses;

            List<Approval_Audit__c> audits = createApprovalAudits(opportunities);
            insert audits;

            System.debug('=== Revenue Intelligence Sample Data Loaded ===');
            System.debug('Accounts: ' + accounts.size());
            System.debug('Opportunities: ' + opportunities.size());
            System.debug('Risk Alerts: ' + alerts.size());
            System.debug('Deal Analyses: ' + analyses.size());
            System.debug('Approval Audits: ' + audits.size());
        } finally {
            TriggerHandler.clearBypass('OpportunityTriggerHandler');
        }
    }

    private static void deleteExistingData() {
        delete [SELECT Id FROM Approval_Audit__c WHERE Opportunity__r.Name LIKE 'RIP - %'];
        delete [SELECT Id FROM Deal_Analysis__c WHERE Opportunity__r.Name LIKE 'RIP - %'];
        delete [SELECT Id FROM Risk_Alert__c WHERE Opportunity__r.Name LIKE 'RIP - %'];
        delete [SELECT Id FROM Opportunity WHERE Name LIKE 'RIP - %'];
        delete [SELECT Id FROM Account WHERE Name LIKE 'RIP - %'];
    }

    private static List<Account> createAccounts() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < ACCOUNT_COUNT; i++) {
            String prefix = COMPANY_PREFIXES[mod(i, COMPANY_PREFIXES.size())];
            String suffix = COMPANY_SUFFIXES[mod(i / COMPANY_PREFIXES.size(), COMPANY_SUFFIXES.size())];
            accounts.add(new Account(
                Name = 'RIP - ' + prefix + ' ' + suffix + ' ' + (i + 1),
                Industry = INDUSTRIES[mod(i, INDUSTRIES.size())],
                Type = mod(i, 3) == 0 ? 'Customer' : (mod(i, 3) == 1 ? 'Prospect' : 'Partner'),
                AnnualRevenue = randomDecimal(500000, 50000000).setScale(0),
                NumberOfEmployees = Integer.valueOf(randomDecimal(50, 10000).setScale(0)),
                BillingCity = pickCity(i),
                BillingCountryCode = 'US',
                BillingStateCode = pickState(i)
            ));
        }
        return accounts;
    }

    private static List<Opportunity> createOpportunities(List<Account> accounts) {
        List<Opportunity> opportunities = new List<Opportunity>();
        List<String> dealTypes = new List<String>{
            'Enterprise License', 'Platform Upgrade', 'Annual Renewal',
            'Professional Services', 'Multi-Year Agreement', 'Pilot Program',
            'Expansion Deal', 'New Logo Acquisition', 'Cross-Sell Bundle'
        };

        for (Integer i = 0; i < OPPORTUNITY_COUNT; i++) {
            Account acc = accounts[mod(i, accounts.size())];
            Integer healthScore = generateHealthScore(i);
            String riskLevel = healthFromScore(healthScore);
            Decimal discount = generateDiscount(i);
            String stage = pickStage(i, healthScore);
            Boolean isClosed = mod(i, 20) == 0;
            Boolean isWon = isClosed && mod(i, 3) != 0;

            if (isClosed) {
                stage = isWon ? 'Closed Won' : 'Closed Lost';
            }

            opportunities.add(new Opportunity(
                Name = 'RIP - ' + dealTypes[mod(i, dealTypes.size())] + ' — ' + acc.Name,
                AccountId = acc.Id,
                Amount = randomDecimal(25000, 2500000).setScale(0),
                StageName = stage,
                CloseDate = isClosed
                    ? Date.today().addDays(-Integer.valueOf(randomDecimal(1, 90).setScale(0)))
                    : Date.today().addDays(Integer.valueOf(randomDecimal(7, 180).setScale(0))),
                Probability = isClosed ? (isWon ? 100 : 0) : stageProbability(stage),
                Health_Score__c = healthScore,
                Risk_Level__c = riskLevel,
                Discount_Percentage__c = discount,
                Discount_Amount__c = null,
                Approval_Status__c = approvalFromDiscount(discount, i),
                Revenue_Confidence_Score__c = (healthScore * stageProbability(stage) / 100.0).setScale(1),
                Forecast_Category__c = forecastFromHealth(healthScore, isClosed, isWon)
            ));
        }

        for (Opportunity opp : opportunities) {
            if (opp.Amount != null && opp.Discount_Percentage__c != null) {
                opp.Discount_Amount__c = (opp.Amount * opp.Discount_Percentage__c).setScale(2);
            }
        }

        return opportunities;
    }

    private static List<Risk_Alert__c> createRiskAlerts(List<Opportunity> opportunities) {
        List<Opportunity> atRiskOpps = new List<Opportunity>();
        for (Opportunity opp : opportunities) {
            if (opp.Risk_Level__c == 'High' || opp.Risk_Level__c == 'Critical') {
                atRiskOpps.add(opp);
            }
        }

        if (atRiskOpps.isEmpty()) {
            for (Integer i = 0; i < Math.min(RISK_ALERT_COUNT, opportunities.size()); i++) {
                atRiskOpps.add(opportunities[i]);
            }
        }

        List<Risk_Alert__c> alerts = new List<Risk_Alert__c>();
        for (Integer i = 0; i < RISK_ALERT_COUNT; i++) {
            Opportunity opp = atRiskOpps[mod(i, atRiskOpps.size())];
            Integer riskScore = 100 - (opp.Health_Score__c != null ? Integer.valueOf(opp.Health_Score__c) : 50);
            String severity = severityFromRisk(opp.Risk_Level__c);

            alerts.add(new Risk_Alert__c(
                Opportunity__c = opp.Id,
                Risk_Score__c = riskScore,
                Severity__c = severity,
                Reason__c = RISK_REASONS[mod(i, RISK_REASONS.size())],
                Recommended_Action__c = RECOMMENDED_ACTIONS[mod(i, RECOMMENDED_ACTIONS.size())],
                Status__c = ALERT_STATUSES[mod(i, ALERT_STATUSES.size())]
            ));
        }
        return alerts;
    }

    private static List<Deal_Analysis__c> createDealAnalyses(List<Opportunity> opportunities) {
        List<Deal_Analysis__c> analyses = new List<Deal_Analysis__c>();
        List<String> recommendations = new List<String>{
            '["Schedule executive briefing within 5 business days","Confirm budget authority with CFO"]',
            '["Reduce discount to 15% or below before close","Engage solutions architect for POC"]',
            '["Send mutual close plan to champion","Identify and neutralize competitive threat"]',
            '["Re-qualify timeline with procurement lead","Offer phased implementation to reduce risk"]',
            '["Accelerate legal review — assign dedicated resource","Prepare ROI analysis for board presentation"]'
        };

        for (Integer i = 0; i < DEAL_ANALYSIS_COUNT; i++) {
            Opportunity opp = opportunities[mod(i * 3, opportunities.size())];
            Integer confidence = opp.Health_Score__c != null ? Integer.valueOf(opp.Health_Score__c) : 65;

            analyses.add(new Deal_Analysis__c(
                Opportunity__c = opp.Id,
                AI_Summary__c = AI_SUMMARIES[mod(i, AI_SUMMARIES.size())],
                Recommendations__c = recommendations[mod(i, recommendations.size())],
                Confidence_Score__c = confidence,
                Analysis_Date__c = DateTime.now().addDays(-Integer.valueOf(randomDecimal(0, 30).setScale(0)))
            ));
        }
        return analyses;
    }

    private static List<Approval_Audit__c> createApprovalAudits(List<Opportunity> opportunities) {
        List<Opportunity> discountedOpps = new List<Opportunity>();
        for (Opportunity opp : opportunities) {
            if (opp.Discount_Percentage__c != null && opp.Discount_Percentage__c > 0) {
                discountedOpps.add(opp);
            }
        }

        if (discountedOpps.isEmpty()) {
            discountedOpps = opportunities;
        }

        Id approverId = UserInfo.getUserId();
        List<Approval_Audit__c> audits = new List<Approval_Audit__c>();
        List<String> comments = new List<String>{
            'Approved — within policy guidelines for this deal size.',
            'Approved with condition to revisit pricing at renewal.',
            'Rejected — discount exceeds margin threshold for segment.',
            'Escalated to VP Sales for final decision.',
            'Approved — strategic account exception granted.',
            'Rejected — insufficient business case for discount level.',
            'Approved — competitive match required to retain account.',
            'Escalated — awaiting CRO sign-off on margin impact.'
        };

        for (Integer i = 0; i < APPROVAL_AUDIT_COUNT; i++) {
            Opportunity opp = discountedOpps[mod(i, discountedOpps.size())];
            Decimal prevDiscount = opp.Discount_Percentage__c != null ? opp.Discount_Percentage__c : 0;
            Decimal newDiscount = Math.min(prevDiscount + (mod(i, 3) * 0.02), 0.50);

            audits.add(new Approval_Audit__c(
                Opportunity__c = opp.Id,
                Approver__c = approverId,
                Action__c = AUDIT_ACTIONS[mod(i, AUDIT_ACTIONS.size())],
                Comments__c = comments[mod(i, comments.size())],
                Previous_Discount__c = prevDiscount,
                New_Discount__c = newDiscount,
                Approval_Date__c = DateTime.now().addDays(-Integer.valueOf(randomDecimal(1, 60).setScale(0)))
            ));
        }
        return audits;
    }

    // --- Helper methods ---

    private static Integer generateHealthScore(Integer index) {
        Integer bucket = mod(index, 10);
        if (bucket <= 3) return Integer.valueOf(randomDecimal(72, 98).setScale(0));
        if (bucket <= 6) return Integer.valueOf(randomDecimal(40, 69).setScale(0));
        return Integer.valueOf(randomDecimal(8, 39).setScale(0));
    }

    private static String healthFromScore(Integer score) {
        if (score >= 70) return 'Low';
        if (score >= 40) return 'Medium';
        if (score >= 20) return 'High';
        return 'Critical';
    }

    private static Decimal generateDiscount(Integer index) {
        Integer bucket = mod(index, 5);
        if (bucket == 0) return 0;
        if (bucket == 1) return randomDecimal(0.01, 0.08).setScale(2);
        if (bucket == 2) return randomDecimal(0.08, 0.18).setScale(2);
        if (bucket == 3) return randomDecimal(0.18, 0.32).setScale(2);
        return randomDecimal(0.32, 0.48).setScale(2);
    }

    private static String approvalFromDiscount(Decimal discount, Integer index) {
        if (discount == null || discount <= 0) return 'Not Required';
        return APPROVAL_STATUSES[mod(index, APPROVAL_STATUSES.size())];
    }

    private static String pickStage(Integer index, Integer healthScore) {
        if (healthScore >= 70) return OPEN_STAGES[Math.min(OPEN_STAGES.size() - 1, mod(index, OPEN_STAGES.size()) + 4)];
        if (healthScore >= 40) return OPEN_STAGES[mod(index, OPEN_STAGES.size())];
        return OPEN_STAGES[Math.min(2, mod(index, 3))];
    }

    private static Decimal stageProbability(String stage) {
        Map<String, Decimal> probMap = RIP_Constants.STAGE_PROBABILITY;
        return probMap.containsKey(stage) ? probMap.get(stage) : 20;
    }

    private static String forecastFromHealth(Integer healthScore, Boolean isClosed, Boolean isWon) {
        if (isClosed && isWon) return 'Closed';
        if (healthScore >= 80) return 'Commit';
        if (healthScore >= 60) return 'Best Case';
        if (healthScore >= 40) return 'Pipeline';
        return 'Omitted';
    }

    private static String severityFromRisk(String riskLevel) {
        if (riskLevel == 'Critical') return 'Critical';
        if (riskLevel == 'High') return 'High';
        if (riskLevel == 'Medium') return 'Medium';
        return 'Low';
    }

    private static String pickCity(Integer index) {
        List<String> cities = new List<String>{
            'San Francisco', 'New York', 'Chicago', 'Austin', 'Seattle',
            'Boston', 'Denver', 'Atlanta', 'Dallas', 'Portland'
        };
        return cities[mod(index, cities.size())];
    }

    private static String pickState(Integer index) {
        List<String> states = new List<String>{
            'CA', 'NY', 'IL', 'TX', 'WA', 'MA', 'CO', 'GA', 'TX', 'OR'
        };
        return states[mod(index, states.size())];
    }

    private static Integer mod(Integer a, Integer b) {
        return Math.mod(Math.abs(a), b);
    }

    private static Decimal randomDecimal(Decimal minVal, Decimal maxVal) {
        Double rnd = Math.random();
        return minVal + (maxVal - minVal) * Decimal.valueOf(rnd);
    }
}
