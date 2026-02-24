# 102_BEHAVIOR.md

Version: v0.3
Status: FROZEN (Aligned with 101 v0.3 — AuditLog + Atomicity + No Asset Deletion)

---

## Δ Change Summary (from v0.2 FROZEN)

This revision introduces:

1. Mandatory AuditLog coupling for defined mutations
2. Atomic DB transaction requirement for:
    - InspectionRecord create
    - InspectionRecord delete
    - Asset interval change
    - Asset activation toggle
    - Asset creation
3. Explicit prohibition of Asset deletion

No other behavioral changes.

---

# 1. Authoritative Time Model

(unchanged from v0.2)

- UTC only
- Date-only arithmetic
- Reminder job: 07:00 UTC daily

---

# 2. Canonical Inspection State

(unchanged logic; alignment clarified)

`Asset.last_inspection_date` is a derived cache of:

MAX(inspection_date) over InspectionRecords per Asset

Tie-break: greatest recorded_at → else deterministic ID order

Cache must be recomputed inside mutation transaction.

---

# 3. Deadline & Status Determination

(unchanged logic)

Status computed on-the-fly for UI/export.

Reminder job computes status at execution time.

Boundaries:

- Δ > 30 → GREEN
- 1 ≤ Δ ≤ 30 → YELLOW
- Δ ≤ 0 → RED
- No inspection history → RED
- is_active = false → excluded

---

# 4. Reminder Job (No Transition Memory)

(unchanged core rule)

Daily at 07:00 UTC:

For each active Asset:

If status ∈ {YELLOW, RED}
→ send one email to ResponsibleRole.notification_email

No retry.
No escalation.
No state memory.

---

# 5. InspectionRecord Mutation Rules (Atomic + Audited)

## 5.1 Create InspectionRecord

Must occur in a single atomic database transaction:

1. Insert InspectionRecord
2. Recompute Asset.last_inspection_date (aggregation)
3. Insert AuditLog entry:
    - action_type = CREATE_INSPECTION_RECORD
    - actor_user_id
    - target_entity_type = INSPECTION_RECORD
    - target_entity_id
    - occurred_at_utc
    - minimal payload (no full snapshot required)

If any step fails → entire transaction MUST rollback.

---

## 5.2 Delete InspectionRecord

Must occur in a single atomic database transaction:

1. Insert AuditLog entry with:
    - action_type = DELETE_INSPECTION_RECORD
    - full payload snapshot (as defined in 103)
2. Physically delete InspectionRecord
3. Recompute Asset.last_inspection_date (aggregation)

If AuditLog insert fails → deletion MUST NOT proceed.

No partial delete allowed.

---

## 5.3 Update InspectionRecord

Forbidden in Phase 1.

Correction = delete + create.

---

# 6. Asset Mutation Rules (Atomic + Audited)

## 6.1 Create Asset

Atomic transaction:

1. Insert Asset
2. Insert AuditLog entry:
    - action_type = CREATE_ASSET
    - actor_user_id
    - target_entity_id
    - occurred_at_utc

---

## 6.2 Change Asset.interval_option_id

Atomic transaction:

1. Update interval_option_id
2. Insert AuditLog entry:
    - action_type = CHANGE_ASSET_INTERVAL
    - actor_user_id
    - target_entity_id
    - occurred_at_utc

No modification of historical InspectionRecords.

---

## 6.3 Toggle Asset.is_active

Atomic transaction:

1. Update is_active
2. Insert AuditLog entry:
    - action_type = TOGGLE_ASSET_ACTIVE
    - actor_user_id
    - target_entity_id
    - occurred_at_utc

Reactivation resumes reminder job eligibility next cycle.

---

## 6.4 Asset Deletion

Forbidden in Phase 1.

Any attempt to delete must be rejected at application level.

---

# 7. Access Control (Unchanged)

ADMIN:

- Full tenant CRUD (subject to constraints above)

OWNER:

- CRUD on Assets + InspectionRecords
- No user management

VIEWER:

- Read-only

No privilege to alter AuditLog entries.

---

# 8. Export Behavior (Unchanged)

Exports recompute:

- next_due_date
- status
- include export_timestamp_utc
- include exporting_user_id

Exports do not include AuditLog contents.

---

# 9. Determinism Guarantees

For identical:

- persisted data
- UTC date context

System produces identical:

- status values
- reminder eligibility
- export content

Atomicity ensures no intermediate inconsistent states are externally observable.

---

End of 102_BEHAVIOR.md v0.3
