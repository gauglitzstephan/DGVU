# 101_STRUCTURE.md

Version: v0.3
Status: FROZEN (Change-Intent Applied: AuditLog + Catalog Read-Only + No Asset Deletion)

---

## Δ Change Summary (from v0.2 FROZEN)

This revision introduces the minimum structural additions required by the approved Change-Intent:

1. Adds tenant entity: `AuditLog` (append-only, insert-only for app user)
2. Forbids Asset deletion (deactivation only)
3. Hardens runtime catalog immutability: system-global catalogs are read-only for the application user

No other entities or relationships are added.

---

## 0. Scope of This Document (101 Only)

Defines structure only:

- entities and their identity
- relationships and cardinalities
- system-global catalogs and immutability boundaries
- structural invariants
- versioning principles for structural elements

This document does NOT define:

- status computation
- deadline calculation
- triggers / reminders
- exports
- timing behavior
- permissions enforcement logic

Those belong to 102/103.

---

## 1. Structural System Boundary

### 1.1 Product Boundary (Structural)

A multi-tenant SaaS that provides a deterministic container for:

- registering assets (work equipment)
- assigning a single inspection interval per asset (from a fixed catalog)
- recording an immutable inspection history per asset
- producing structured exports (representation only; behavior not specified here)

### 1.2 Multi-Tenancy Boundary

- System supports multiple Organisations sharing infrastructure.
- Each Organisation is an isolated tenant context.
- No data may be shared across organisations except system-global catalogs.

---

## 2. System-Global Catalogs (Immutable by Default)

Catalogs are system-global, identical for all organisations, and not customer-configurable.

### 2.1 Object Class Catalog (`ObjectClass`)

**Identity**

- `object_class_id` (system-global stable identifier)

**Core fields**

- `name`
- `description` (optional)
- `is_active` (catalog lifecycle flag; no deletion semantics)

**Invariant**

- Organisations cannot create/rename/modify object classes.
- Organisations may only enable/disable usage via OrganisationObjectClass.

### 2.2 Interval Catalog (`IntervalOption`)

**Allowed values (authoritative)**

- 3 months, 6 months, 12 months, 24 months

**Identity**

- `interval_option_id` (system-global stable identifier)

**Core fields**

- `months` (integer; must be one of {3,6,12,24})
- `is_active`

**Invariants**

- No custom interval frameworks.
- No mapping from object class to interval.

---

## 3. Tenant Entities

### 3.1 Organisation (`Organisation`)

**Identity**

- `organisation_id`

**Core fields**

- `name`
- `created_at`
- `is_active`

**Invariants**

- All tenant-owned entities reference exactly one organisation_id.
- Cross-organisation references are forbidden (except system-global catalogs).

### 3.2 Location (`Location`)

**Identity**

- `location_id`
- `organisation_id`

**Core fields**

- `name`
- `address` (optional)
- `is_active`

**Invariant**

- Location belongs to exactly one Organisation.

### 3.3 ResponsibleRole (`ResponsibleRole`)

**Identity**

- `responsible_role_id`
- `organisation_id`

**Core fields**

- `name`
- `notification_email` (exactly one email address)
- `is_active`

**Invariants**

- Organisation-local.
- Exactly one email address (no arrays, no CC lists, no distribution logic).

### 3.4 User (`User`)

**Identity**

- `user_id`
- `organisation_id`

**Core fields**

- `email`
- `role` (enum: ADMIN, OWNER, VIEWER)
- `is_active`

**Invariant**

- User belongs to exactly one Organisation.

### 3.5 AuditLog (`AuditLog`) **(NEW in v0.3)**

Append-only audit trail for explainable destructive/mutating actions.

**Identity**

- `audit_log_id`
- `organisation_id`

**Core fields**

- `occurred_at_utc` (timestamp)
- `actor_user_id` (nullable only for system jobs)
- `action_type` (system-defined enum)
- `target_entity_type` (string; e.g., ASSET, INSPECTION_RECORD)
- `target_entity_id` (opaque id)
- `payload_json` (JSON; may contain full snapshots depending on action; content constraints defined in 103)

**Structural invariants**

- Tenant-isolated: AuditLog belongs to exactly one organisation_id.
- Insert-only for the application user:
    - application access must not UPDATE or DELETE AuditLog rows
- AuditLog is not a workflow engine and carries no decision logic.

**Minimum action types (authoritative set for Phase 1)**

- CREATE_ASSET
- TOGGLE_ASSET_ACTIVE
- CHANGE_ASSET_INTERVAL
- CREATE_INSPECTION_RECORD
- DELETE_INSPECTION_RECORD

---

## 4. Organisation Configuration (UI Filtering Only)

### 4.1 OrganisationObjectClass (`OrganisationObjectClass`)

**Identity**

- composite: (organisation_id, object_class_id)

**Core fields**

- `is_enabled`
- `enabled_at` (optional)

**Structural invariants**

- Purpose is UI filtering only (dropdown reduction).
- No industry presets; no auto-enablement.
- Asset can be created only if its object_class_id is enabled.

---

## 5. Core Domain Entity

### 5.1 Asset (`Asset`)

**Identity**

- `asset_id`
- `organisation_id`

**Required associations**

- `location_id` → Location (1)
- `object_class_id` → ObjectClass (1; must be enabled for org)
- `interval_option_id` → IntervalOption (1)
- `responsible_role_id` → ResponsibleRole (1)

**Core fields**

- `name`
- `last_inspection_date` (derived cache; behavior in 102)
- `inspector_name` (text)
- `serial_number` (optional; duplicates allowed)
- `inventory_number` (optional; duplicates allowed)
- `notes` (optional)
- `is_active`

**Structural invariants**

- Exactly one interval per Asset.
- Multi-regime tracking is represented as multiple Assets.
- Uniqueness guaranteed only by asset_id.

**Lifecycle invariant (HARD)**

- Asset deletion is forbidden in Phase 1.
- Only deactivation via is_active is allowed.
- Deactivation ≠ deletion; historical references remain valid.

---

## 6. Inspection History

### 6.1 InspectionRecord (`InspectionRecord`)

**Identity**

- `inspection_record_id`
- `organisation_id`
- `asset_id`

**Core fields**

- `inspection_date`
- `inspector_name`
- `interval_option_id_at_time` → IntervalOption (required)
- `recorded_at`
- `comment` (optional)

**Optional association**

- `document_id` → Document (optional)

**Invariants**

- Records are append-only in the sense that “update” is forbidden (behavior in 102).
- Records may be deleted (behavior in 102) but deletion must be explainable via AuditLog (trust in 103).

---

## 7. Optional Document Storage

### 7.1 Document (`Document`)

**Identity**

- `document_id`
- `organisation_id`

**Core fields**

- `file_name`
- `mime_type`
- `storage_pointer` (opaque)
- `uploaded_at`
- `uploaded_by_user_id` (optional)

**Invariants**

- No parsing / interpretation.
- Tenant isolation: Document bound to exactly one organisation_id.

---

## 8. Relationship Summary (Cardinalities)

- Organisation 1 ── * Location
- Organisation 1 ── * ResponsibleRole
- Organisation 1 ── * User
- Organisation 1 ── * Asset
- Organisation 1 ── * InspectionRecord
- Organisation 1 ── * Document
- Organisation 1 ── * AuditLog
- Asset 1 ── * InspectionRecord
- Asset * ── 1 Location
- Asset * ── 1 ResponsibleRole
- Asset * ── 1 ObjectClass (enabled by OrganisationObjectClass)
- Asset * ── 1 IntervalOption
- InspectionRecord * ── 0..1 Document
- Organisation 1 ── * OrganisationObjectClass
- ObjectClass 1 ── * OrganisationObjectClass

---

## 9. Structural Invariants (Authoritative)

### 9.1 Determinism & Anti-Drift

- No customer-defined object classes.
- No customer-defined intervals.
- No structural mapping of class → interval.
- No regulatory knowledge encoded in the data model.

### 9.2 Tenant Isolation

- All tenant-owned entities include organisation_id.
- Cross-organisation references forbidden (except system catalogs).

### 9.3 Flat Asset Model

- Exactly one interval per Asset.

### 9.4 Lifecycle Safety

- Deactivation ≠ deletion.
- Asset deletion forbidden.

### 9.5 Audit Explainability (Structural)

- Any destructive/mutating actions that affect auditability must be representable as AuditLog entries (details in 103).
- AuditLog is tenant-isolated and insert-only for the application user.

---

## 10. Versioning Principles (Structural)

### 10.1 Catalog Versioning

Catalog changes occur only via Phase 5 process.

### 10.2 Runtime Catalog Immutability (HARD)

For the application user at runtime:

- ObjectClass is READ-ONLY
- IntervalOption is READ-ONLY

Catalog edits occur only via controlled migrations in system updates.

### 10.3 Backward Compatibility

- Catalog identifiers remain stable.
- Retire via is_active=false.
- Tenant references remain valid.

---

End of 101_STRUCTURE.md v0.3
