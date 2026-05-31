# Permission Set Field-Level Security Audit

**Audit Date:** June 1, 2026  
**Scope:** All custom fields on Account, Opportunity, Risk_Alert__c, Approval_Audit__c, Deal_Analysis__c  
**Status:** **PASS — No permission-related gaps in permission sets**

---

## Custom Field Coverage Matrix

Every deployable custom field (29 total) is granted `readable=true` in all three permission sets.

| Field API Name | Rep | Manager | VP | Notes |
|----------------|-----|---------|-----|-------|
| **Account** | | | | |
| `Total_Pipeline_Value__c` | R | R | R | Rollup — read-only all roles |
| `Total_Won_Revenue__c` | R | R | R | Rollup — read-only all roles |
| **Opportunity** | | | | |
| `Health_Score__c` | R | R | R/W | System-calculated; VP override |
| `Risk_Level__c` | R | R | R/W | System-calculated; VP override |
| `Discount_Percentage__c` | R/W | R/W | R/W | Rep submits discounts |
| `Discount_Amount__c` | R | R | R/W | Trigger-calculated |
| `Approval_Status__c` | R | R/W | R/W | Manager+ approves |
| `Revenue_Confidence_Score__c` | R | R | R/W | System-calculated |
| `Forecast_Category__c` | R | R | R/W | System-calculated |
| `Days_Since_Last_Activity__c` | R | R | R | Formula — read-only all |
| `Revenue_Impact__c` | R | R | R | Formula — read-only all |
| **Risk_Alert__c** | | | | |
| `Opportunity__c` | R | R/W | R/W | |
| `Risk_Score__c` | R | R/W | R/W | |
| `Severity__c` | R | R/W | R/W | |
| `Reason__c` | R | R/W | R/W | |
| `Recommended_Action__c` | R | R/W | R/W | |
| `Status__c` | R | R/W | R/W | Manager acknowledges/resolves |
| **Approval_Audit__c** | | | | |
| `Opportunity__c` | R | R/W | R/W | |
| `Approver__c` | R | R/W | R/W | |
| `Action__c` | R | R/W | R/W | |
| `Comments__c` | R | R/W | R/W | |
| `Previous_Discount__c` | R | R/W | R/W | |
| `New_Discount__c` | R | R/W | R/W | |
| `Approval_Date__c` | R | R/W | R/W | |
| **Deal_Analysis__c** | | | | |
| `Opportunity__c` | R | R | R/W | |
| `AI_Summary__c` | R | R | R/W | Queueable-created |
| `Recommendations__c` | R | R | R/W | |
| `Confidence_Score__c` | R | R | R/W | |
| `Analysis_Date__c` | R | R | R/W | |

**Legend:** R = Read, R/W = Read + Edit

---

## Object Permission Coverage

| Object | Rep | Manager | VP |
|--------|-----|---------|-----|
| Account | Read | Read | Read (view all) |
| Opportunity | CRU | CRU | CRUD (modify/view all) |
| Risk_Alert__c | Read | CRU | CRUD (modify/view all) |
| Approval_Audit__c | Read | CRU | CRUD (modify/view all) |
| Deal_Analysis__c | Read | Read | CRUD (modify/view all) |

---

## Apex Class Access (@AuraEnabled Coverage)

All LWC-facing Apex classes are enabled in every role that uses the corresponding UI:

| Apex Class | Rep | Manager | VP | Used By |
|------------|-----|---------|-----|---------|
| `DealHealthService` | Yes | Yes | Yes | revenueDashboard, dealHealthCard |
| `RiskAlertService` | Yes | Yes | Yes | opportunityIntelligencePanel |
| `GlobalSearchService` | Yes | Yes | Yes | globalSearch |
| `ApprovalService` | Yes | Yes | Yes | Flow, approval UI |
| `AIDealAnalysisService` | Yes | Yes | Yes | aiDealAnalysisPanel |
| `DealAnalysisQueueable` | Yes | Yes | Yes | aiDealAnalysisPanel |
| `RevenueIntelligenceRestAPI` | — | — | Yes | REST integration |
| `RiskRecalculationBatch` | — | — | Yes | Batch jobs |
| `ForecastScheduler` | — | — | Yes | Scheduled jobs |

---

## Application Field Reference Cross-Check

Every custom field referenced in Apex selectors, services, SOSL, and LWCs is covered:

| Source | Fields Referenced | Permission Set Coverage |
|--------|-------------------|------------------------|
| `OpportunitySelector` | 9 Opportunity custom fields | 9/9 |
| `RiskAlertSelector` | 6 Risk_Alert__c fields | 6/6 |
| `GlobalSearchService` (SOSL) | Opportunity×4, Account×1, Risk_Alert__c×3 | All covered |
| `DealHealthService.getDealHealth` | 8 fields returned to LWC | 8/8 |
| `RiskAlertService.getOpportunityIntelligence` | Opportunity×6 + alerts×5 | 11/11 |
| `ApprovalService` | Approval_Audit__c×7, Opportunity.Approval_Status__c | 8/8 |
| `AIDealAnalysisService` | Deal_Analysis__c×5 | 5/5 |
| `RevenueIntelligenceRestAPI` | Opportunity×6 custom fields | 6/6 |

**Result: 29/29 custom fields — 100% coverage**

---

## Excluded from Permission Sets (By Design)

| Metadata Type | Reason |
|---------------|--------|
| `Approval_Rule__mdt` | Custom Metadata — no FLS; readable by all Apex |
| `DealApprovedEvent__e` | Platform Event — publish/subscribe via Apex, no FLS |
| Standard fields (Name, Amount, StageName, etc.) | Covered by standard object permissions + base profile |

---

## Remaining Non-Permission-Set Item

| ID | Item | Severity | Notes |
|----|------|----------|-------|
| HIGH-05 | Experience Cloud Guest User Profile | High | **Not a permission set** — requires manual Guest User Profile configuration in Setup for public site access. Permission sets cannot be assigned to guest users in all org configurations; use Profile → Apex Class Access + Guest User Object/FLS instead. |

---

## Verification Checklist

- [x] All 29 custom fields have `fieldPermissions` in RIP_Sales_Representative
- [x] All 29 custom fields have `fieldPermissions` in RIP_Sales_Manager
- [x] All 29 custom fields have `fieldPermissions` in RIP_VP_Sales
- [x] Formula/rollup fields set `editable=false` on all roles
- [x] All 5 custom objects have `objectPermissions` in all three sets
- [x] Account read access added for SOSL global search
- [x] All 6 `@AuraEnabled` classes enabled for roles using LWCs
- [x] Manager/VP approval fields grant `editable=true` where DML occurs
- [x] No orphaned field references in Apex without FLS coverage

**MED-05: RESOLVED**
