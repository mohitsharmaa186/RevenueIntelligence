@IsTest
private class ForecastSchedulerTest {
    @IsTest
    static void testScheduleNightly() {
        String jobId = ForecastScheduler.scheduleNightly();
        System.assertNotEquals(null, jobId, 'Scheduled job should return an ID');
        System.abortJob(jobId);
    }

    @IsTest
    static void testSchedulableInstantiation() {
        ForecastScheduler scheduler = new ForecastScheduler();
        System.assertNotEquals(null, scheduler, 'Schedulable should instantiate');
    }
}
