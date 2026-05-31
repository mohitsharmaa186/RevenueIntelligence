/**
 * @description Queueable job for async AI deal analysis.
 */
public with sharing class DealAnalysisQueueable implements Queueable, Database.AllowsCallouts {
    private Id opportunityId;

    public DealAnalysisQueueable(Id opportunityId) {
        this.opportunityId = opportunityId;
    }

    public void execute(QueueableContext context) {
        AIDealAnalysisService.analyzeDeal(opportunityId);
    }

    @AuraEnabled
    public static String enqueueAnalysis(Id opportunityId) {
        System.enqueueJob(new DealAnalysisQueueable(opportunityId));
        return 'Analysis queued successfully';
    }
}
