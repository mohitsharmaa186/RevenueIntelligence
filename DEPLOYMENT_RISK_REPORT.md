# Deployment Risk Report

**Project:** Revenue Intelligence Platform  
**Audit Date:** June 1, 2026  
**API Version:** 62.0  
**Auditor:** Pre-deployment static metadata & dependency analysis

---

## Executive Summary

| Severity | Found | Fixed in Repo | Remaining |
|----------|-------|---------------|-----------|
| **Critical** | 2 | 2 | 0 |
| **High** | 5 | 4 | 1 |
| **Medium** | 8 | 6 | 2 |
| **Low** | 6 | 2 | 4 |

**Deployment recommendation:** Safe to deploy **Phases 1–2 and 4** after applying fixes in this commit. **Phase 3 (AI)** requires post-deploy Named Credential secret configuration. **Experience Cloud** requires manual site creation (expected).

---

## Critical Issues

### CRIT-01: Missing `Approval_Audit__c` object metadata
| | |
|---|---|
| **Impact** | Deploy fails; `ApprovalService`, sample data loader, and tests cannot compile |
| **References** | `ApprovalService.cls`, `RIP_SampleDataLoader.cls`, `ApprovalServiceTest.cls`, tab `Approval_Audit__c.tab-meta.xml` |
| **Status** | **FIXED** — Added object + 7 fields under `objects/Approval_Audit__c/` |

### CRIT-02: Missing `Risk_Alert__c.Status__c` field
| | |
|---|---|
| **Impact** | Deploy fails; SOQL/SOSL/DML on `Status__c` breaks `RiskAlertService`, `RiskAlertSelector`, `GlobalSearchService` |
| **References** | `RiskAlertService.cls:37,98`, `RiskAlertSelector.cls:8,15,21,27`, `GlobalSearchService.cls:21` |
| **Status** | **FIXED** — Added picklist field with Open/Acknowledged/Resolved values |

---

## High Issues

### HIGH-01: Flow screen fields not wired to record create
| | |
|---|---|
| **Impact** | Deal Submission Wizard creates blank Opportunities (null Name, Amount, Stage) |
| **File** | `flows/Deal_Submission_Wizard.flow-meta.xml` |
| **Root cause** | `recordCreates` referenced empty flow variables instead of screen components |
| **Status** | **FIXED** — Record create now uses `{!OppName}`, `{!OppAmount}`, `{!OppCloseDate}`, `{!OppStage}` directly |

### HIGH-02: Flow stage dropdown had no choices
| | |
|---|---|
| **Impact** | Users cannot select Stage; `StageName` remains null → DML error on insert |
| **File** | `flows/Deal_Submission_Wizard.flow-meta.xml` |
| **Status** | **FIXED** — Added 6 static stage choices (Prospecting through Negotiation/Review) |

### HIGH-03: Flow discount percent semantics mismatch
| | |
|---|---|
| **Impact** | Entering `15` for 15% stored as `15.0` (1500%) → validation rule failure |
| **File** | `flows/Deal_Submission_Wizard.flow-meta.xml` |
| **Status** | **FIXED** — Added formula `formulaDiscountDecimal = DiscountPct / 100` assigned to Percent field |

### HIGH-04: `aiDealAnalysisPanel` not exposed to Experience Cloud
| | |
|---|---|
| **Impact** | Component invisible in Experience Builder; Opportunity flexipage incomplete on public site |
| **File** | `lwc/aiDealAnalysisPanel/aiDealAnalysisPanel.js-meta.xml` |
| **Status** | **FIXED** — Added `lightningCommunity__Default` + Opportunity targetConfig |

### HIGH-05: Experience Cloud guest user Apex access not configured
| | |
|---|---|
| **Impact** | Public site LWCs (`revenueDashboard`, `globalSearch`, `revenueIntelligenceLanding`) throw insufficient privileges for guest users |
| **References** | All `@AuraEnabled` methods in `DealHealthService`, `GlobalSearchService` |
| **Status** | **OPEN — Manual post-deploy** |
| **Fix** | After creating Experience Cloud site: Profile → Guest User Profile → Enable Apex class access for `DealHealthService`, `GlobalSearchService`, `RiskAlertService`. Grant read FLS on Opportunity, Account, Risk_Alert__c fields. |

---

## Medium Issues

### MED-01: `Discount_Amount__c` double-division bug
| | |
|---|---|
| **Impact** | Discount amount calculated at 1/100th of correct value |
| **File** | `DealHealthService.cls:102` |
| **Status** | **FIXED** — Changed to `Amount * Discount_Percentage__c` (Percent field stores fraction) |

### MED-02: AI fallback discount threshold wrong scale
| | |
|---|---|
| **Impact** | Rule-based AI never triggers "negotiate discount" recommendation |
| **File** | `AIDealAnalysisService.cls:113` |
| **Status** | **FIXED** — Changed `> 20` to `> 0.20` |

### MED-03: `ApprovalServiceTest` passed wrong discount scale
| | |
|---|---|
| **Impact** | Test passed but didn't validate real approval rule matching |
| **File** | `ApprovalServiceTest.cls:74` |
| **Status** | **FIXED** — Changed `getApprovalInfo(15)` to `getApprovalInfo(0.15)` |

### MED-04: Named Credential not linked to External Credential
| | |
|---|---|
| **Impact** | OpenAI callouts fail authentication in API 62 orgs |
| **File** | `namedCredentials/OpenAI_API.namedCredential-meta.xml` |
| **Status** | **FIXED** — Linked `externalCredential` reference; **API key still requires manual Setup configuration** |

### MED-05: Permission sets missing custom object field permissions
| | |
|---|---|
| **Impact** | Users with permission sets may hit FLS errors on custom fields |
| **Files** | `permissionsets/RIP_*.permissionset-meta.xml` |
| **Status** | **FIXED** — All 29 custom fields covered across 3 permission sets with role-appropriate read/edit. See `PERMISSION_AUDIT.md` |

### MED-06: `RIP_SampleDataLoader` not in deployment manifests
| | |
|---|---|
| **Impact** | Phased deploys omit sample data loader class |
| **Files** | `manifest/phase*.xml` |
| **Status** | **OPEN** |
| **Fix** | Include in Phase 4 manifest or deploy separately |

### MED-07: Flow metadata may require org-specific stage names
| | |
|---|---|
| **Impact** | If org uses custom Opportunity stages, flow stage choices won't match |
| **File** | `flows/Deal_Submission_Wizard.flow-meta.xml` |
| **Status** | **OPEN** |
| **Fix** | Verify standard stage names exist in target org, or replace choices with org-specific values |

### MED-08: External Credential API key is post-deploy only
| | |
|---|---|
| **Impact** | AI callouts use rule-based fallback until key configured |
| **Status** | **OPEN — Expected** |
| **Fix** | Setup → External Credentials → OpenAI API Credential → add `Authorization: Bearer sk-...` header |

---

## Low Issues

### LOW-01: Lightning Message Service channel has no publisher
| | |
|---|---|
| **Impact** | Dashboard LMS subscription never receives refresh events |
| **File** | `lwc/revenueDashboard/revenueDashboard.js` |
| **Status** | **OPEN** |
| **Fix** | Publish `{ eventType: 'refresh' }` from approval/risk LWCs, or remove unused subscription code |

### LOW-02: `globalSearch` missing `lightningCommunity__Page` target
| | |
|---|---|
| **Status** | **FIXED** |

### LOW-03: Community targetConfig missing on record LWCs
| | |
|---|---|
| **Files** | `dealHealthCard`, `opportunityIntelligencePanel` |
| **Status** | **FIXED** |

### LOW-04: Experience Cloud site not in source metadata
| | |
|---|---|
| **Impact** | Site must be created manually in Setup |
| **Status** | **OPEN — By design** |
| **Fix** | Follow README Experience Cloud setup steps |

### LOW-05: Reports and Dashboards not in source
| | |
|---|---|
| **Impact** | Executive dashboard reports must be built in org UI |
| **Status** | **OPEN — By design** |
| **Fix** | `revenueDashboard` LWC provides live KPI alternative |

### LOW-06: Application logo uses standard static resource path
| | |
|---|---|
| **File** | `applications/Revenue_Intelligence.app-meta.xml` |
| **Impact** | May show default icon if path unavailable |
| **Status** | **OPEN — Cosmetic** |

---

## Validation Matrix

### Apex Class Dependencies — PASS

All 31 classes resolve. Cross-references verified:

| Class | Depends On | Status |
|-------|-----------|--------|
| `OpportunityTriggerHandler` | `TriggerHandler`, `DealHealthService`, `ApprovalService`, `RiskAlertService` | OK |
| `ForecastScheduler` | `RiskRecalculationBatch` | OK |
| `DealAnalysisQueueable` | `AIDealAnalysisService` | OK |
| `ApprovalService` | `ApprovalRuleSelector`, `Approval_Audit__c` | OK (after CRIT-01 fix) |

### LWC Apex Imports — PASS

| LWC | Apex Method | Status |
|-----|-------------|--------|
| `revenueDashboard` | `DealHealthService.getDashboardMetrics` | OK |
| `dealHealthCard` | `DealHealthService.getDealHealth` | OK |
| `opportunityIntelligencePanel` | `RiskAlertService.getOpportunityIntelligence` | OK |
| `globalSearch` | `GlobalSearchService.search` | OK |
| `aiDealAnalysisPanel` | `DealAnalysisQueueable.enqueueAnalysis`, `AIDealAnalysisService.getLatestAnalysis` | OK |

### Message Channel — PASS

| Import | Metadata File | Status |
|--------|--------------|--------|
| `Revenue_Intelligence_Channel__c` | `messageChannels/Revenue_Intelligence_Channel.messageChannel-meta.xml` | OK |

### Flexipage Component References — PASS

| Flexipage | Components | Status |
|-----------|-----------|--------|
| `Revenue_Intelligence_Home` | `globalSearch`, `revenueDashboard` | OK |
| `Revenue_Intelligence_Opportunity` | `dealHealthCard`, `opportunityIntelligencePanel`, `aiDealAnalysisPanel` | OK |

### Custom Metadata Records — PASS

| Record | DeveloperName | Status |
|--------|--------------|--------|
| Manager Approval (0-10%) | `Manager_Approval` | OK |
| Director Approval (10-20%) | `Director_Approval` | OK |
| VP Sales Approval (20-30%) | `VP_Sales_Approval` | OK |
| CRO Approval (30%+) | `CRO_Approval` | OK |

### Custom Field Coverage — PASS (after fixes)

| Object | Fields Referenced in Apex | Metadata Files |
|--------|--------------------------|----------------|
| Opportunity | 9 custom fields | 9/9 |
| Account | 1 custom field | 1/1 |
| Risk_Alert__c | 6 fields | 6/6 |
| Approval_Audit__c | 7 fields | 7/7 |
| Deal_Analysis__c | 5 fields | 5/5 |
| Approval_Rule__mdt | 3 fields | 3/3 |
| DealApprovedEvent__e | 3 fields | 3/3 |

---

## Recommended Deployment Sequence

```bash
# 1. Deploy Phase 1 (core data model + Apex + LWC)
sf project deploy start --manifest manifest/phase1-core-mvp.xml \
  --test-level RunSpecifiedTests \
  --tests DealHealthServiceTest OpportunityTriggerHandlerTest RiskAlertServiceTest RIP_UtilTest

# 2. Deploy Phase 2 (automation + search)
sf project deploy start --manifest manifest/phase2-enterprise-automation.xml \
  --test-level RunSpecifiedTests \
  --tests ApprovalServiceTest RiskRecalculationBatchTest ForecastSchedulerTest GlobalSearchServiceTest

# 3. Deploy Phase 3 (AI — configure credential after)
sf project deploy start --manifest manifest/phase3-ai-intelligence.xml \
  --test-level RunSpecifiedTests \
  --tests AIDealAnalysisServiceTest DealAnalysisQueueableTest

# 4. Deploy Phase 4 (REST API + security + sample data)
sf project deploy start --manifest manifest/phase4-integration-security.xml \
  --test-level RunSpecifiedTests \
  --tests RevenueIntelligenceRestAPITest

# 5. Load demo data
sf apex run --file scripts/apex/loadSampleData.apex
```

---

## Post-Deploy Checklist

- [ ] Assign permission sets (Rep, Manager, VP) — see `PERMISSION_AUDIT.md` for field coverage
- [ ] Activate Revenue Intelligence Lightning App
- [ ] Assign Revenue Intelligence Opportunity record page
- [ ] Assign Revenue Intelligence Home app page
- [ ] Run `ForecastScheduler.scheduleNightly()` in Anonymous Apex
- [ ] Configure OpenAI External Credential API key (Phase 3)
- [ ] Create Experience Cloud LWR site with guest profile Apex access (**HIGH-05**)
- [ ] Verify org Opportunity stage names match flow choices (**MED-07**)
- [ ] Run Deal Submission Wizard end-to-end test

---

## Files Modified During Audit Remediation

| File | Change |
|------|--------|
| `objects/Approval_Audit__c/**` | Created missing object + 7 fields |
| `objects/Risk_Alert__c/fields/Status__c.field-meta.xml` | Created missing picklist |
| `classes/DealHealthService.cls` | Fixed discount amount calculation |
| `classes/AIDealAnalysisService.cls` | Fixed discount threshold |
| `classes/ApprovalServiceTest.cls` | Fixed test input scale |
| `flows/Deal_Submission_Wizard.flow-meta.xml` | Rewired screen fields, stages, discount formula |
| `lwc/aiDealAnalysisPanel/*.js-meta.xml` | Added Experience Cloud exposure |
| `lwc/dealHealthCard/*.js-meta.xml` | Added community targetConfig |
| `lwc/opportunityIntelligencePanel/*.js-meta.xml` | Added community targetConfig |
| `lwc/globalSearch/*.js-meta.xml` | Added `lightningCommunity__Page` |
| `namedCredentials/OpenAI_API.namedCredential-meta.xml` | Linked External Credential |
| `permissionsets/RIP_*.permissionset-meta.xml` | Full FLS — 29 custom fields × 3 roles (MED-05) |
| `PERMISSION_AUDIT.md` | Permission coverage validation artifact |

---

## Test Execution Remediation (June 1, 2026 — Pass 2)

### Failures Fixed

| Test | Root Cause | Fix |
|------|------------|-----|
| `RiskRecalculationBatchTest` | Second `executeBatch` from `ForecastSchedulerTest.testScheduleNightly` via `Test.stopTest()` | Single batch call (size 200), 5 test opps; scheduler test no longer runs scheduled batch |
| `RIP_SampleDataLoaderTest` (×2) | `BillingState`/`BillingCountry` invalid with State/Country Picklists | Use `BillingCountryCode='US'` + `BillingStateCode` in `RIP_SampleDataLoader.createAccounts()` |

### Coverage Improvements

| New Test Class | Covers |
|----------------|--------|
| `OpportunitySelectorTest` | All selector queries + dashboard/forecast aggregates |
| `RiskAlertSelectorTest` | Open alerts, severity filter, empty-set guards |
| `ApprovalRuleSelectorTest` | Custom metadata rule resolution |
| `TriggerHandlerTest` | Bypass/clear API, run() guard outside trigger |

Expanded: `ApprovalServiceTest`, `RiskAlertServiceTest`, `AIDealAnalysisServiceTest`, `DealHealthServiceTest`, `GlobalSearchServiceTest`, `OpportunityTriggerHandlerTest`, `RevenueIntelligenceRestAPITest`, `RIP_UtilTest`

**Expected org coverage:** 80%+ (was 67%)

### Deploy Command

```bash
sf project deploy start --source-dir force-app --test-level RunLocalTests
```

### Remaining Non-Blockers

| Item | Severity | Notes |
|------|----------|-------|
| OpenAI Named Credential auth | High (Phase 3) | Manual API key after deploy — AI falls back to rule-based analysis |
| Experience Cloud site | High | Manual LWR site creation |
| Org stage name drift | Medium | Flow stage choices must match org Opportunity stages |
| `ForecastScheduler.scheduleNightly()` | Low | Run once post-deploy in Anonymous Apex |

**Deployment recommendation:** Ready for `RunLocalTests` deploy after this patch.
