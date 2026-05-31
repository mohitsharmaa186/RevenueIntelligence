@IsTest
private class RIP_UtilTest {
    @IsTest
    static void testClamp() {
        System.assertEquals(0, RIP_Util.clamp(-5, 0, 100));
        System.assertEquals(100, RIP_Util.clamp(150, 0, 100));
        System.assertEquals(50, RIP_Util.clamp(50, 0, 100));
        System.assertEquals(0, RIP_Util.clamp(null, 0, 100));
    }

    @IsTest
    static void testDaysSince() {
        System.assertEquals(0, RIP_Util.daysSince(Date.today()));
        System.assertEquals(999, RIP_Util.daysSince(null));
        System.assertEquals(10, RIP_Util.daysSince(Date.today().addDays(-10)));
    }

    @IsTest
    static void testDetermineRiskLevel() {
        System.assertEquals('Low', RIP_Util.determineRiskLevel(80));
        System.assertEquals('Medium', RIP_Util.determineRiskLevel(50));
        System.assertEquals('High', RIP_Util.determineRiskLevel(30));
        System.assertEquals('Critical', RIP_Util.determineRiskLevel(10));
    }

    @IsTest
    static void testBuildResponses() {
        Map<String, Object> error = RIP_Util.buildErrorResponse('Test error', 400);
        System.assertEquals(false, error.get('success'));

        Map<String, Object> success = RIP_Util.buildSuccessResponse('data');
    @IsTest
    static void testSafeToIntegerAndDaysBetween() {
        System.assertEquals(42, RIP_Util.safeToInteger(42.7));
        System.assertEquals(0, RIP_Util.safeToInteger(null));
        System.assertEquals(10, RIP_Util.daysBetween(Date.today(), Date.today().addDays(10)));
        System.assertEquals(0, RIP_Util.daysBetween(null, Date.today()));
    }

    @IsTest
    static void testDetermineSeverity() {
        System.assertEquals('Low', RIP_Util.determineSeverity('Low'));
        System.assertEquals('Medium', RIP_Util.determineSeverity('Medium'));
        System.assertEquals('High', RIP_Util.determineSeverity('High'));
        System.assertEquals('Critical', RIP_Util.determineSeverity('Critical'));
        System.assertEquals('Critical', RIP_Util.determineSeverity('Unknown'));
    }
}
