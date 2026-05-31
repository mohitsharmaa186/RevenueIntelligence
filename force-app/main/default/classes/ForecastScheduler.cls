/**
 * @description Schedulable class that runs nightly to update forecast and pipeline metrics.
 */
public with sharing class ForecastScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        RiskRecalculationBatch batch = new RiskRecalculationBatch();
        Database.executeBatch(batch, RIP_Constants.DEFAULT_BATCH_SIZE);
    }

    /**
     * @description Schedules the nightly forecast job. Call once during post-deployment setup.
     */
    public static String scheduleNightly() {
        String cronExp = '0 0 2 * * ?'; // 2 AM daily
        ForecastScheduler scheduler = new ForecastScheduler();
        return System.schedule('Revenue Intelligence Nightly Forecast', cronExp, scheduler);
    }
}
