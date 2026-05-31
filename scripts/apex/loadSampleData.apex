// =============================================================================
// Revenue Intelligence Platform — Sample Data Loader
// =============================================================================
//
// PREREQUISITE: Deploy RIP_SampleDataLoader.cls first
//   sf project deploy start --source-dir force-app/main/default/classes/RIP_SampleDataLoader.cls
//
// RUN OPTIONS (Developer Console → Debug → Open Execute Anonymous Window):
//
// Option 1 — Load sample data (first run):
//   RIP_SampleDataLoader.load();
//
// Option 2 — Reload (deletes existing RIP demo data first):
//   RIP_SampleDataLoader.load(true);
//
// =============================================================================

RIP_SampleDataLoader.load();

// Expected output in debug log:
//   Accounts:         50
//   Opportunities:   200
//   Risk Alerts:      50
//   Deal Analyses:    50
//   Approval Audits:  50
