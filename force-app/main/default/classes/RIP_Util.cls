/**
 * @description Utility methods for Revenue Intelligence Platform.
 */
public with sharing class RIP_Util {
    /**
     * @description Safely converts a Decimal to Integer, defaulting to 0.
     */
    public static Integer safeToInteger(Decimal value) {
        return value != null ? value.intValue() : 0;
    }

    /**
     * @description Clamps a value between min and max.
     */
    public static Decimal clamp(Decimal value, Decimal minVal, Decimal maxVal) {
        if (value == null) {
            return minVal;
        }
        if (value < minVal) {
            return minVal;
        }
        if (value > maxVal) {
            return maxVal;
        }
        return value;
    }

    /**
     * @description Calculates days between two dates.
     */
    public static Integer daysBetween(Date startDate, Date endDate) {
        if (startDate == null || endDate == null) {
            return 0;
        }
        return startDate.daysBetween(endDate);
    }

    /**
     * @description Returns the number of days since a given date.
     */
    public static Integer daysSince(Date targetDate) {
        if (targetDate == null) {
            return 999;
        }
        return targetDate.daysBetween(Date.today());
    }

    /**
     * @description Builds a standardized error response for REST APIs.
     */
    public static Map<String, Object> buildErrorResponse(String message, Integer statusCode) {
        return new Map<String, Object>{
            'success' => false,
            'message' => message,
            'statusCode' => statusCode
        };
    }

    /**
     * @description Builds a standardized success response for REST APIs.
     */
    public static Map<String, Object> buildSuccessResponse(Object data) {
        return new Map<String, Object>{
            'success' => true,
            'data' => data
        };
    }

    /**
     * @description Determines risk level from health score.
     */
    public static String determineRiskLevel(Integer healthScore) {
        if (healthScore >= RIP_Constants.HEALTH_SCORE_HEALTHY) {
            return RIP_Constants.RISK_LEVEL_LOW;
        } else if (healthScore >= RIP_Constants.HEALTH_SCORE_AT_RISK) {
            return RIP_Constants.RISK_LEVEL_MEDIUM;
        } else if (healthScore >= 20) {
            return RIP_Constants.RISK_LEVEL_HIGH;
        }
        return RIP_Constants.RISK_LEVEL_CRITICAL;
    }

    /**
     * @description Determines severity from risk level.
     */
    public static String determineSeverity(String riskLevel) {
        switch on riskLevel {
            when 'Low' { return RIP_Constants.SEVERITY_LOW; }
            when 'Medium' { return RIP_Constants.SEVERITY_MEDIUM; }
            when 'High' { return RIP_Constants.SEVERITY_HIGH; }
            when else { return RIP_Constants.SEVERITY_CRITICAL; }
        }
    }

    private RIP_Util() {}
}
