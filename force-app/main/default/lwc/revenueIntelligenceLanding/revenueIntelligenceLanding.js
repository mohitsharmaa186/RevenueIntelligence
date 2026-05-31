import { LightningElement } from 'lwc';

export default class RevenueIntelligenceLanding extends LightningElement {
    features = [
        {
            id: '1',
            icon: 'standard:opportunity',
            title: 'Pipeline Intelligence',
            description: 'Real-time visibility into pipeline revenue, deal health scores, and forecast categories.'
        },
        {
            id: '2',
            icon: 'utility:warning',
            title: 'Risk Detection',
            description: 'Automated risk alerts identify at-risk deals before they slip, with recommended actions.'
        },
        {
            id: '3',
            icon: 'standard:approval',
            title: 'Smart Approvals',
            description: 'Metadata-driven discount approval routing to the right leader based on deal size.'
        },
        {
            id: '4',
            icon: 'standard:bot',
            title: 'AI Insights',
            description: 'AI-powered deal analysis with win probability, risk explanation, and next-best actions.'
        }
    ];
}
