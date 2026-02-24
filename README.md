# Inspection Tracking System — Specification-Governed Repository

This repository operates under a Specification-First discipline.

Authoritative documents:

- specs/intent/INTENT-000.md
- specs/scope/SCOPE-010.md
- specs/structure/101_STRUCTURE.md
- specs/behavior/102_BEHAVIOR.md
- specs/trust/103_TRUST.md

The specifications define:

- Product intent
- Explicit scope boundaries
- Structural invariants
- Behavioral rules
- Trust guarantees

No behavior may be introduced that is not explicitly defined in these specifications.

Implementation is performed exclusively via:

- Atomic tasks
- Task-first prompts
- Explicit spec references

If a requested change is not supported by the specs:
A Change-Intent process is mandatory.

This repository enforces a No Silent Drift doctrine.
