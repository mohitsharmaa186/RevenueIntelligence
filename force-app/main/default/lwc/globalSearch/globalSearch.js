import { LightningElement } from 'lwc';
import search from '@salesforce/apex/GlobalSearchService.search';

export default class GlobalSearch extends LightningElement {
    searchTerm = '';
    results = null;
    isLoading = false;
    hasSearched = false;
    debounceTimer;

    handleSearchInput(event) {
        this.searchTerm = event.target.value;
        clearTimeout(this.debounceTimer);

        if (this.searchTerm.length < 2) {
            this.results = null;
            this.hasSearched = false;
            return;
        }

        this.debounceTimer = setTimeout(() => {
            this.performSearch();
        }, 300);
    }

    performSearch() {
        this.isLoading = true;
        search({ searchTerm: this.searchTerm })
            .then(data => {
                this.results = data;
                this.hasSearched = true;
            })
            .catch(error => {
                console.error('Search error:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    get hasOpportunities() {
        return this.results?.opportunities?.length > 0;
    }

    get hasAccounts() {
        return this.results?.accounts?.length > 0;
    }

    get hasContacts() {
        return this.results?.contacts?.length > 0;
    }

    get hasRiskAlerts() {
        return this.results?.riskAlerts?.length > 0;
    }

    get hasAnyResults() {
        return this.hasOpportunities || this.hasAccounts || this.hasContacts || this.hasRiskAlerts;
    }

    get noResults() {
        return this.hasSearched && !this.hasAnyResults;
    }
}
