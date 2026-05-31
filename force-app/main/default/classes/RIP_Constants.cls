/**
 * @description Central constants for Revenue Intelligence Platform.
 *              No hardcoded IDs — all thresholds driven by constants or Custom Metadata.
 */
public with sharing class RIP_Constants {
    // Opportunity Health Score thresholds
    public static final Integer HEALTH_SCORE_MAX = 100;
    public static final Integer HEALTH_SCORE_HEALTHY = 70;
    public static final Integer HEALTH_SCORE_AT_RISK = 40;

    // Risk Levels
    public static final String RISK_LEVEL_LOW = 'Low';
    public static final String RISK_LEVEL_MEDIUM = 'Medium';
    public static final String RISK_LEVEL_HIGH = 'High';
    public static final String RISK_LEVEL_CRITICAL = 'Critical';

    // Approval Status values
    public static final String APPROVAL_STATUS_PENDING = 'Pending';
    public static final String APPROVAL_STATUS_APPROVED = 'Approved';
    public static final String APPROVAL_STATUS_REJECTED = 'Rejected';
    public static final String APPROVAL_STATUS_NOT_REQUIRED = 'Not Required';

    // Forecast Categories
    public static final String FORECAST_OMIT = 'Omitted';
    public static final String FORECAST_PIPELINE = 'Pipeline';
    public static final String FORECAST_BEST_CASE = 'Best Case';
    public static final String FORECAST_COMMIT = 'Commit';
    public static final String FORECAST_CLOSED = 'Closed';

    // Discount limits
    public static final Decimal MAX_DISCOUNT_PERCENT = 50;

    // Activity thresholds (days)
    public static final Integer ACTIVITY_DAYS_HEALTHY = 7;
    public static final Integer ACTIVITY_DAYS_WARNING = 14;
    public static final Integer ACTIVITY_DAYS_CRITICAL = 30;

    // Risk Alert Status
    public static final String ALERT_STATUS_OPEN = 'Open';
    public static final String ALERT_STATUS_ACKNOWLEDGED = 'Acknowledged';
    public static final String ALERT_STATUS_RESOLVED = 'Resolved';

    // Risk Alert Severity
    public static final String SEVERITY_LOW = 'Low';
    public static final String SEVERITY_MEDIUM = 'Medium';
    public static final String SEVERITY_HIGH = 'High';
    public static final String SEVERITY_CRITICAL = 'Critical';

    // Platform Event types
    public static final String EVENT_DEAL_APPROVED = 'Deal Approved';
    public static final String EVENT_DEAL_REJECTED = 'Deal Rejected';
    public static final String EVENT_RISK_ESCALATED = 'Risk Escalated';

    // REST API
    public static final String REST_BASE_PATH = '/services/apexrest/revenueintelligence/opportunities';

    // Batch sizes
    public static final Integer DEFAULT_BATCH_SIZE = 200;

    // Stage probability mapping
    public static final Map<String, Decimal> STAGE_PROBABILITY = new Map<String, Decimal>{
        'Prospecting' => 10,
        'Qualification' => 20,
        'Needs Analysis' => 40,
        'Value Proposition' => 50,
        'Id. Decision Makers' => 60,
        'Perception Analysis' => 70,
        'Proposal/Price Quote' => 75,
        'Negotiation/Review' => 90,
        'Closed Won' => 100,
        'Closed Lost' => 0
    };

    private RIP_Constants() {}
}
