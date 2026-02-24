# Application Commands

This folder contains **atomic use-cases** (commands) that implement behavior strictly according to the authoritative specs.

Rules:
- Commands MUST be small and single-purpose.
- All mutating commands MUST run inside a single transaction boundary:
  - use `runInTransaction` from `src/infra/db/transaction.ts`
- Commands MUST be explicit about:
  - organisation_id scoping
  - actor_user_id attribution (when required)
  - AuditLog writes (when required by specs)
- Commands MUST NOT introduce new behavior beyond specs.

This folder contains no controllers, routes, or UI code.
