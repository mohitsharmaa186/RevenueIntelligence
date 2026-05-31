import { LightningElement, api, wire } from 'lwc';
import enqueueAnalysis from '@salesforce/apex/DealAnalysisQueueable.enqueueAnalysis';
import getLatestAnalysis from '@salesforce/apex/AIDealAnalysisService.getLatestAnalysis';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AiDealAnalysisPanel extends LightningElement {
    @api recordId;

    summary = '';
    riskExplanation = '';
    winProbability = 0;
    recommendations = [];
    confidenceScore = 0;
    analysisDate = null;
    isLoading = false;
    isAnalyzing = false;
    hasAnalysis = false;

    @wire(getLatestAnalysis, { opportunityId: '$recordId' })
    wiredAnalysis({ error, data }) {
        if (data && data.summary) {
            this.summary = data.summary;
            this.recommendations = data.recommendations || [];
            this.confidenceScore = data.confidenceScore || 0;
            this.analysisDate = data.analysisDate;
            this.hasAnalysis = true;
        }
    }

    handleAnalyzeDeal() {
        this.isAnalyzing = true;
        enqueueAnalysis({ opportunityId: this.recordId })
            .then(() => {
                this.showToast('Analysis Started', 'AI deal analysis is running. Results will appear shortly.', 'info');
                setTimeout(() => this.refreshAnalysis(), 3000);
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || 'Failed to start analysis', 'error');
            })
            .finally(() => {
                this.isAnalyzing = false;
            });
    }

    refreshAnalysis() {
        this.isLoading = true;
        getLatestAnalysis({ opportunityId: this.recordId })
            .then(data => {
                if (data && data.summary) {
                    this.summary = data.summary;
                    this.recommendations = data.recommendations || [];
                    this.confidenceScore = data.confidenceScore || 0;
                    this.analysisDate = data.analysisDate;
                    this.hasAnalysis = true;
                    this.showToast('Analysis Complete', 'AI deal analysis results are ready.', 'success');
                }
            })
            .catch(error => console.error(error))
            .finally(() => { this.isLoading = false; });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get formattedDate() {
        if (!this.analysisDate) return '';
        return new Date(this.analysisDate).toLocaleDateString('en-US', {
            month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit'
        });
    }

    get confidenceClass() {
        if (this.confidenceScore >= 70) return 'confidence-high';
        if (this.confidenceScore >= 40) return 'confidence-medium';
        return 'confidence-low';
    }
}
