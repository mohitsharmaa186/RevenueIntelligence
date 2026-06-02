import { LightningElement, api, wire } from 'lwc';
import getDealHealth from '@salesforce/apex/DealHealthService.getDealHealth';

export default class DealHealthCard extends LightningElement {
    @api recordId;

    healthScore = 0;
    riskLevel = '';
    revenueConfidence = 0;
    forecastCategory = '';
    discountPercentage = 0;
    approvalStatus = '';
    isLoading = true;

    @wire(getDealHealth, { opportunityId: '$recordId' })
    wiredHealth({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.healthScore = data.healthScore ?? 0;
            this.riskLevel = data.riskLevel ?? 'Unknown';
            this.revenueConfidence = data.revenueConfidence ?? 0;
            this.forecastCategory = data.forecastCategory ?? '';
            this.discountPercentage = data.discountPercentage ?? 0;
            this.approvalStatus = data.approvalStatus ?? '';
        } else if (error) {
            console.error('Deal health error:', error);
        }
    }

    get healthScoreDisplay() {
        return Math.round(this.healthScore);
    }

    get healthClass() {
        if (this.healthScore >= 70) return 'health-excellent';
        if (this.healthScore >= 40) return 'health-warning';
        return 'health-critical';
    }

    get riskBadgeClass() {
        const level = (this.riskLevel || '').toLowerCase();
        return `risk-badge risk-${level}`;
    }

    get confidenceDisplay() {
        return Math.round(this.revenueConfidence) + '%';
    }

    get discountDisplay() {
        return (this.discountPercentage * 100).toFixed(1) + '%';
    }

    get scoreRingStyle() {
        const pct = this.healthScore;
        const color = pct >= 70 ? '#2e844a' : pct >= 40 ? '#fe9339' : '#ea001e';
        return `background: conic-gradient(${color} ${pct * 3.6}deg, #ecebea 0deg)`;
    }
}
