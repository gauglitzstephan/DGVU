# 103_TRUST.md

Version: v0.2
Status: FROZEN (Aligned with 101 v0.3 and 102 v0.3)

---

## 0. Scope of This Document

This document defines:

- immutability guarantees
- mutation accountability
- deletion explainability
- atomicity requirements
- tenant isolation enforcement
- failure handling boundaries
- backup & recovery doctrine
- anti-drift controls

This document does not introduce new business behavior.

---

# 1. Trust Model Overview

The system guarantees:

- deterministic state reconstruction
- explainable destructive actions
- accountable mutations
- tenant isolation
- bounded recoverability

The system does NOT guarantee:

- legal compliance
- cryptographic non-repudiation
- zero data loss
- protection against malicious infrastructure operators

Infrastructure is assumed trusted (standard SaaS hosting).

---

# 2. AuditLog Immutability Model

## 2.1 Structural Foundation

AuditLog is a first-class entity (defined in 101 v0.3).

AuditLog is:

- tenant-scoped
- append-only
- insert-only for the application user

## 2.2 Database-Level Constraint

At runtime:

- Application DB user must have INSERT permission only on AuditLog.
- UPDATE and DELETE permissions must be denied.

This enforces insert-only immutability at infrastructure level.

---

# 3. Mutation Accountability

The following actions MUST generate an AuditLog entry:

- CREATE_ASSET
- TOGGLE_ASSET_ACTIVE
- CHANGE_ASSET_INTERVAL
- CREATE_INSPECTION_RECORD
- DELETE_INSPECTION_RECORD

Each AuditLog entry must contain:

- audit_log_id
- organisation_id
- occurred_at_utc
- actor_user_id
- action_type
- target_entity_type
- target_entity_id
- payload_json (when required; see below)

Minimal logging principle:

- No full change diffs except for deleted InspectionRecords.

---

# 4. Deletion Explainability

## 4.1 InspectionRecord Deletion

Deletion is allowed only under the atomic transaction rules defined in 102 v0.3.

Before deletion, system MUST write an AuditLog entry with full snapshot payload.

### Required payload_json fields for DELETE_INSPECTION_RECORD:

- inspection_record_id
- organisation_id
- asset_id
- inspection_date
- inspector_name
- interval_option_id_at_time
- comment (if present)
- document_id (if present)

This guarantees forensic reconstructability.

## 4.2 Asset Deletion

Asset deletion is forbidden in Phase 1.

Lifecycle is managed exclusively via is_active flag.

---

# 5. Atomicity Guarantees

The following operations MUST occur within a single atomic database transaction:

- Create InspectionRecord + AuditLog + cache recompute
- Delete InspectionRecord + AuditLog + cache recompute
- Create Asset + AuditLog
- Change Asset interval + AuditLog
- Toggle Asset active state + AuditLog

If any component fails:

- Entire transaction MUST rollback.

Deletion without successful AuditLog insert is forbidden.

---

# 6. Cache Integrity Guarantee

`Asset.last_inspection_date` is derived from InspectionRecord table.

Integrity rules:

- Always recomputed via aggregation.
- No incremental mutation logic.
- Authoritative truth = MAX(inspection_date) with defined tie-break.

If inconsistency detected:

- Recompute from InspectionRecord table.

---

# 7. Reminder Job Reliability Boundary

Reminder job:

- Executes daily at 07:00 UTC.
- No retry logic.
- No catch-up emails.

Failure handling:

- Missed run results in no reminders that day.
- Next scheduled execution resumes normally.

Reminder delivery is assistive, not safety-critical.

---

# 8. Export Integrity

Exports must include:

- export_timestamp_utc
- exporting_user_id

Exports rely on deterministic recomputation rules (102).

No digital signatures.
No cryptographic hashing.

Integrity is anchored in:

- immutable InspectionRecord policy
- accountable deletion logging
- atomic mutation rules

---

# 9. Tenant Isolation Enforcement

All tenant entities include organisation_id.

Trust invariants:

- All queries scoped by organisation_id.
- Cross-organisation joins forbidden.
- AuditLog entries are tenant-isolated.

No shared mutable state across tenants.

---

# 10. Catalog Drift Protection

Runtime invariant:

- ObjectClass and IntervalOption tables are READ-ONLY for application user.
- Changes occur only via controlled system migrations under Phase 5.

Silent runtime modification is prohibited.

---

# 11. Backup & Recovery Doctrine

Minimum guarantees:

- Daily full database backup.
- Recovery Point Objective (RPO): 24 hours.
- Recovery Time Objective (RTO): 48 hours.

In catastrophic failure:

- System restored from most recent daily backup.
- AuditLog and InspectionRecords restored together.

No partial restoration allowed.

---

# 12. Failure Scenarios

## 12.1 Partial Mutation Failure

If mutation transaction fails:

- No partial writes visible.
- No orphaned records.
- No missing AuditLog entries.

Atomicity guarantees consistency.

## 12.2 AuditLog Write Failure

If AuditLog insert fails:

- Associated destructive mutation MUST fail.
- No deletion may occur without audit entry.

## 12.3 Infrastructure Compromise

Out of scope:

- Protection against malicious DB administrators.
- Protection against cloud provider intervention.

Spec assumes trusted infrastructure.

---

# 13. No Silent Drift Rule

The following changes require:

- Change-Intent
- Spec revision
- Red-Team
- Re-Freeze

Examples:

- Allowing InspectionRecord updates
- Introducing soft-delete
- Adding retry logic for reminders
- Allowing Asset deletion
- Making catalogs writable at runtime
- Introducing compliance scoring or recommendations

No runtime drift allowed.

---

# 14. Reconstruction Guarantee

Given:

- InspectionRecords
- AuditLog
- Asset state
- IntervalOption catalog
- ObjectClass catalog
- UTC date context

System must reconstruct:

- historical inspection events
- responsible user actions
- current deterministic status

No hidden mutable state permitted.

---

End of 103_TRUST.md v0.2
