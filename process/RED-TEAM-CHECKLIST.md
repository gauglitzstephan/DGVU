# RED-TEAM CHECKLIST — Anti-Drift Review

Purpose:
Ensure proposed spec changes do not violate foundational doctrines.

## Determinism

- No non-deterministic behavior introduced
- No hidden mutable state introduced
- Time model remains explicit

## Scope Discipline

- Change is reflected in SCOPE-010 if necessary
- No silent feature expansion

## Trust Integrity

- AuditLog remains append-only
- Atomicity guarantees preserved
- No destructive action without explainability

## Tenant Isolation

- organisation_id scoping preserved
- No cross-tenant leakage

## Verdict

PASS / PASS WITH NOTES / FAIL

Reviewer:
Date:
