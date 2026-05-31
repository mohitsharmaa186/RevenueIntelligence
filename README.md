# Revenue Intelligence Platform

Enterprise-grade Salesforce application for sales leaders to identify at-risk deals, monitor opportunity health, manage discount approvals, forecast revenue, and generate AI-powered insights.

Built as a portfolio-quality, production-ready Salesforce ISV product deployable to Developer Edition orgs.

---

## Architecture Overview

```
force-app/main/default/
├── applications/          # Revenue Intelligence Lightning App
├── classes/               # Apex (Service Layer, Selectors, Handlers, Tests)
├── customMetadata/        # Approval Rule records (metadata-driven)
├── externalCredentials/   # OpenAI API credential
├── flexipages/            # Record pages & app home
├── flows/                 # Deal Submission Wizard (Screen Flow)
├── lwc/                   # Lightning Web Components
├── messageChannels/       # Lightning Message Service
├── namedCredentials/      # OpenAI Named Credential
├── objects/               # Custom objects, fields, validation rules
├── permissionsets/        # Role-based access (Rep, Manager, VP)
├── tabs/                  # Custom object tabs
└── triggers/              # OpportunityTrigger (Handler Pattern)
```

### Design Patterns

| Pattern | Implementation |
|---------|---------------|
| Trigger Handler | `TriggerHandler` → `OpportunityTriggerHandler` |
| Service Layer | `DealHealthService`, `RiskAlertService`, `ApprovalService`, `AIDealAnalysisService` |
| Selector | `OpportunitySelector`, `RiskAlertSelector`, `ApprovalRuleSelector` |
| Constants | `RIP_Constants` — no hardcoded IDs or thresholds |
| Custom Metadata | `Approval_Rule__mdt` — dynamic approval routing |
| Utility | `RIP_Util` — shared helpers |

---

## Prerequisites

- [Salesforce CLI](https://developer.salesforce.com/tools/sfdxcli) (v2.x)
- Salesforce Developer Edition org
- [VS Code](https://code.visualstudio.com/) with [Salesforce Extension Pack](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode)
- Node.js 18+ (for LWC linting, optional)
- OpenAI API key (Phase 3, optional — rule-based fallback included)

---

## Quick Start

```bash
# Clone / navigate to project
cd revenue-intelligence-platform

# Authenticate to your Developer Edition org
sf org login web --alias rip-dev --set-default

# Deploy all phases
sf project deploy start --source-dir force-app

# Run all tests
sf apex run test --test-level RunLocalTests --result-format human --code-coverage
```

---

## Phased Deployment

Each phase deploys independently without breaking previous phases.

### Phase 1 — Core Revenue Intelligence MVP

```bash
sf project deploy start --manifest manifest/phase1-core-mvp.xml --test-level RunSpecifiedTests \
  --tests DealHealthServiceTest --tests OpportunityTriggerHandlerTest \
  --tests RiskAlertServiceTest --tests RIP_UtilTest
```

**Includes:**
- Custom objects: `Risk_Alert__c`, `Approval_Audit__c`
- Opportunity fields: Health Score, Risk Level, Discount, Approval Status, etc.
- Account roll-up summaries: Total Pipeline Value, Total Won Revenue
- Validation rules (discount ≤ 50%, amount > 0, close date)
- Formula fields: Revenue Impact, Days Since Last Activity
- Apex: Trigger, Handler, Services, Selectors
- LWC: `revenueDashboard`, `dealHealthCard`, `opportunityIntelligencePanel`
- Flow: Deal Submission Wizard (5-step screen flow)
- Flexipages: Opportunity record page, App home page

### Phase 2 — Enterprise Automation

```bash
sf project deploy start --manifest manifest/phase2-enterprise-automation.xml --test-level RunSpecifiedTests \
  --tests ApprovalServiceTest --tests RiskRecalculationBatchTest \
  --tests ForecastSchedulerTest --tests GlobalSearchServiceTest
```

**Includes:**
- Custom Metadata: `Approval_Rule__mdt` with 4 approval tiers
- Approval engine: `ApprovalService` (metadata-driven, no hardcoded rules)
- SOSL: `GlobalSearchService` + `globalSearch` LWC
- Batch Apex: `RiskRecalculationBatch`
- Scheduled Apex: `ForecastScheduler` (nightly at 2 AM)
- Platform Events: `DealApprovedEvent__e`
- Lightning Message Service: `Revenue_Intelligence_Channel`
- Experience Cloud landing page: `revenueIntelligenceLanding`

### Phase 3 — AI Intelligence Layer

```bash
sf project deploy start --manifest manifest/phase3-ai-intelligence.xml --test-level RunSpecifiedTests \
  --tests AIDealAnalysisServiceTest --tests DealAnalysisQueueableTest
```

**Includes:**
- Custom object: `Deal_Analysis__c`
- Named Credential: `OpenAI_API`
- Queueable: `DealAnalysisQueueable`
- AI Service: `AIDealAnalysisService` (with rule-based fallback)
- LWC: `aiDealAnalysisPanel`

### Phase 4 — Integration & Security

```bash
sf project deploy start --manifest manifest/phase4-integration-security.xml --test-level RunSpecifiedTests \
  --tests RevenueIntelligenceRestAPITest
```

**Includes:**
- REST API: `/services/apexrest/revenueintelligence/opportunities` (GET/POST/PUT/DELETE)
- Permission Sets: Sales Representative, Sales Manager, VP Sales

### Full Deployment

```bash
sf project deploy start --manifest manifest/package.xml --test-level RunLocalTests
```

---

## Post-Deployment Configuration

### 1. Assign Permission Sets

Setup → Permission Sets → Assign to users:

| Permission Set | Role | Access Level |
|---------------|------|-------------|
| RIP Sales Representative | Sales Rep | Own records |
| RIP Sales Manager | Manager | Team records |
| RIP VP Sales | VP Sales | All records |

### 2. Activate Lightning App

Setup → App Manager → Find "Revenue Intelligence" → Edit → Assign to profiles.

### 3. Assign Record Page

Setup → Object Manager → Opportunity → Lightning Record Pages →
Activate `Revenue Intelligence Opportunity` for Desktop and Phone.

### 4. Assign App Home Page

Setup → App Manager → Revenue Intelligence → Edit → App Settings →
App Page → Select `Revenue Intelligence Home`.

### 5. Schedule Nightly Forecast Job

Execute in Developer Console or Anonymous Apex:

```apex
String jobId = ForecastScheduler.scheduleNightly();
System.debug('Scheduled job: ' + jobId);
```

### 6. Configure OpenAI (Optional — Phase 3)

1. Setup → Named Credentials → OpenAI API → Edit
2. Configure External Credential with your OpenAI API key
3. If not configured, AI analysis uses intelligent rule-based fallback

### 7. Experience Cloud Site (Manual Setup)

Experience Cloud sites require UI-based creation:

1. Setup → Digital Experiences → All Sites → New
2. Select **Build Your Own (LWR)** template
3. Site name: **Revenue Intelligence Platform**
4. Create site, then add pages:
   - **Home**: Add `revenueIntelligenceLanding` component
   - **Dashboard**: Add `revenueDashboard` component
5. Administration → Settings → Enable **Public Access**
6. Publish the site
7. Test in incognito mode — no login required

### 8. Add Deal Submission Flow to App

Setup → Flows → Deal Submission Wizard → Add to Utility Bar or Action.

---

## REST API Reference

**Base URL:** `{instance_url}/services/apexrest/revenueintelligence/opportunities`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/opportunities/` | List all open opportunities |
| GET | `/opportunities/{id}` | Get opportunity by ID |
| POST | `/opportunities/` | Create opportunity |
| PUT | `/opportunities/{id}` | Update opportunity |
| DELETE | `/opportunities/{id}` | Delete opportunity |

**Create Example:**

```bash
curl -X POST {instance_url}/services/apexrest/revenueintelligence/opportunities/ \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Enterprise Deal",
    "accountId": "001XXXXXXXXXXXX",
    "amount": 250000,
    "stageName": "Qualification",
    "closeDate": "2026-09-30",
    "discountPercentage": 0.10
  }'
```

---

## Lightning Web Components

| Component | Purpose | Targets |
|-----------|---------|---------|
| `revenueDashboard` | Executive KPI dashboard with LMS refresh | App Page, Home, Community |
| `dealHealthCard` | Circular health score with risk badge | Opportunity Record Page |
| `opportunityIntelligencePanel` | Risk alerts and intelligence metrics | Opportunity Record Page |
| `globalSearch` | SOSL-powered cross-object search | App Page, Home, Community |
| `aiDealAnalysisPanel` | AI deal analysis with recommendations | Opportunity Record Page |
| `revenueIntelligenceLanding` | Public Experience Cloud landing page | Community Page |

---

## Test Coverage

| Test Class | Covers |
|-----------|--------|
| `DealHealthServiceTest` | Health score calculation, dashboard metrics |
| `OpportunityTriggerHandlerTest` | Trigger handler, bypass, alert generation |
| `RiskAlertServiceTest` | Alert CRUD, intelligence panel, resolution |
| `ApprovalServiceTest` | Metadata-driven approval routing |
| `RiskRecalculationBatchTest` | Batch processing |
| `ForecastSchedulerTest` | Scheduled job execution |
| `GlobalSearchServiceTest` | SOSL search |
| `AIDealAnalysisServiceTest` | AI analysis + fallback |
| `DealAnalysisQueueableTest` | Async queueable execution |
| `RevenueIntelligenceRestAPITest` | REST API CRUD |
| `RIP_UtilTest` | Utility methods |

Target: **90%+ org-wide Apex coverage**

---

## Sample Demo Data

Load realistic demo data (50 Accounts, 200 Opportunities, 50 Risk Alerts, 50 Deal Analyses, 50 Approval Audits):

```bash
# Deploy the loader class
sf project deploy start --source-dir force-app/main/default/classes/RIP_SampleDataLoader.cls --source-dir force-app/main/default/classes/RIP_SampleDataLoaderTest.cls

# Run via SF CLI
sf apex run --file scripts/apex/loadSampleData.apex
```

Or in **Developer Console → Execute Anonymous**:

```apex
RIP_SampleDataLoader.load();        // First load
RIP_SampleDataLoader.load(true);     // Reload (deletes existing RIP demo data first)
```

All demo records are prefixed with `RIP -` for easy identification and cleanup.

| Object | Count | Details |
|--------|-------|---------|
| Account | 50 | Mixed industries, types, revenue ranges |
| Opportunity | 200 | Varied health scores, stages, discounts ($25K–$2.5M) |
| Risk_Alert__c | 50 | Linked to High/Critical deals with reasons & actions |
| Deal_Analysis__c | 50 | AI summaries, recommendations, confidence scores |
| Approval_Audit__c | 50 | Approved/Rejected/Escalated discount history |

A self-contained inline script (no class deploy needed) is at `scripts/apex/loadSampleDataInline.apex`.

---

## Interview Talking Points

1. **Architecture**: "I implemented Trigger Handler + Service Layer + Selector patterns with Custom Metadata-driven approval rules — zero hardcoded IDs."

2. **Health Score Algorithm**: "Multi-factor scoring: stage probability (30%), activity recency (30%), discount impact (20%), close date proximity (20%)."

3. **Scalability**: "Batch Apex recalculates health scores nightly; Platform Events decouple approval notifications; Queueable handles AI callouts asynchronously."

4. **Security**: "Three-tier permission sets with field-level security. REST API uses `with sharing` keyword."

5. **AI Integration**: "Named Credential for OpenAI with graceful rule-based fallback when API is unavailable — production-ready resilience."

6. **UI/UX**: "Enterprise dashboard inspired by Clari/Gong with KPI cards, health distribution charts, and Lightning Message Service for real-time updates."

---

## Project Structure

```
revenue-intelligence-platform/
├── force-app/main/default/     # All Salesforce metadata
├── manifest/                   # Phased deployment manifests
│   ├── phase1-core-mvp.xml
│   ├── phase2-enterprise-automation.xml
│   ├── phase3-ai-intelligence.xml
│   ├── phase4-integration-security.xml
│   └── package.xml             # Full deployment
├── sfdx-project.json
├── .forceignore
└── README.md
```

---

## License

Portfolio project — free to use, modify, and deploy for interview demonstrations.
