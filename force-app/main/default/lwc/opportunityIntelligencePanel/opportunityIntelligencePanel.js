import { LightningElement, api, wire } from 'lwc';
import getOpportunityIntelligence from '@salesforce/apex/RiskAlertService.getOpportunityIntelligence';

export default class OpportunityIntelligencePanel extends LightningElement {
    @api recordId;

    opportunityName = '';
    healthScore = 0;
    riskLevel = '';
    forecastCategory = '';
    revenueConfidence = 0;
    discountPercentage = 0;
    approvalStatus = '';
    alerts = [];
    isLoading = true;

    @wire(getOpportunityIntelligence, { opportunityId: '$recordId' })
    wiredIntelligence({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.opportunityName = data.opportunityName || '';
            this.healthScore = data.healthScore || 0;
            this.riskLevel = data.riskLevel || '';
            this.forecastCategory = data.forecastCategory || '';
            this.revenueConfidence = data.revenueConfidence || 0;
            this.discountPercentage = data.discountPercentage || 0;
            this.approvalStatus = data.approvalStatus || '';
            this.alerts = data.alerts || [];
        } else if (error) {
            console.error('Intelligence panel error:', error);
        }
    }

    get hasAlerts() {
        return this.alerts.length > 0;
    }

    get alertCount() {
        return this.alerts.length;
    }

    get riskBadgeClass() {
        const level = (this.riskLevel || '').toLowerCase();
        return `intel-badge badge-${level}`;
    }
}
