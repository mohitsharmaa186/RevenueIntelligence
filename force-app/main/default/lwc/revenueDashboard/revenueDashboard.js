import { LightningElement, wire, api } from 'lwc';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import REVENUE_CHANNEL from '@salesforce/messageChannel/Revenue_Intelligence_Channel__c';
import getDashboardMetrics from '@salesforce/apex/DealHealthService.getDashboardMetrics';

export default class RevenueDashboard extends LightningElement {
    @api recordId;

    pipelineRevenue = 0;
    atRiskRevenue = 0;
    healthyDeals = 0;
    riskDeals = 0;
    totalDeals = 0;
    wonRevenue = 0;
    isLoading = true;
    subscription = null;

    @wire(MessageContext)
    messageContext;

    @wire(getDashboardMetrics)
    wiredMetrics({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.pipelineRevenue = data.pipelineRevenue ?? 0;
            this.atRiskRevenue = data.atRiskRevenue ?? 0;
            this.healthyDeals = data.healthyDeals ?? 0;
            this.riskDeals = data.riskDeals ?? 0;
            this.totalDeals = data.totalDeals ?? 0;
            this.wonRevenue = data.wonRevenue ?? 0;
        } else if (error) {
            console.error('Dashboard metrics error:', error);
        }
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeFromMessageChannel();
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                REVENUE_CHANNEL,
                (message) => this.handleMessage(message)
            );
        }
    }

    unsubscribeFromMessageChannel() {
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
    }

    handleMessage(message) {
        if (message.eventType === 'refresh') {
            this.refreshMetrics();
        }
    }

    refreshMetrics() {
        this.isLoading = true;
        getDashboardMetrics()
            .then(data => {
                this.pipelineRevenue = data.pipelineRevenue ?? 0;
                this.atRiskRevenue = data.atRiskRevenue ?? 0;
                this.healthyDeals = data.healthyDeals ?? 0;
                this.riskDeals = data.riskDeals ?? 0;
                this.totalDeals = data.totalDeals ?? 0;
                this.wonRevenue = data.wonRevenue ?? 0;
            })
            .catch(error => console.error(error))
            .finally(() => { this.isLoading = false; });
    }

    get formattedPipeline() {
        return this.formatCurrency(this.pipelineRevenue);
    }

    get formattedAtRisk() {
        return this.formatCurrency(this.atRiskRevenue);
    }

    get formattedWon() {
        return this.formatCurrency(this.wonRevenue);
    }

    get healthPercentage() {
        if (this.totalDeals === 0) return 0;
        return Math.round((this.healthyDeals / this.totalDeals) * 100);
    }

    get riskPercentage() {
        if (this.totalDeals === 0) return 0;
        return Math.round((this.riskDeals / this.totalDeals) * 100);
    }

    get healthyBarStyle() {
        return `width: ${this.healthPercentage}%`;
    }

    get riskBarStyle() {
        return `width: ${this.riskPercentage}%`;
    }

    formatCurrency(value) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(value);
    }
}
