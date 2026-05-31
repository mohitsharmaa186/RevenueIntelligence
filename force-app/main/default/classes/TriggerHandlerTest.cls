@IsTest
private class TriggerHandlerTest {
    private class TestHandler extends TriggerHandler {
        public Integer beforeInsertCount = 0;

        protected override void beforeInsert() {
            beforeInsertCount++;
        }
    }

    @IsTest
    static void testBypassAndClear() {
        TriggerHandler.bypass('OpportunityTriggerHandler');
        System.assertEquals(true, TriggerHandler.isBypassed('OpportunityTriggerHandler'));

        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        System.assertEquals(false, TriggerHandler.isBypassed('OpportunityTriggerHandler'));

        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.clearAllBypasses();
        System.assertEquals(false, TriggerHandler.isBypassed('OpportunityTriggerHandler'));
    }

    @IsTest
    static void testRunOutsideTriggerContext() {
        TestHandler handler = new TestHandler();
        handler.run();
        System.assertEquals(0, handler.beforeInsertCount, 'Virtual methods should not run outside trigger context');
    }
}
