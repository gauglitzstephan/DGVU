# T-000 — Task Conventions (Authoritative)

Version: v1.0  
Status: ACTIVE

## 1. Definition of an Atomic Task

An atomic task represents exactly ONE coherent system change that:

- Is fully explainable by authoritative specs
- Can be implemented without guessing
- Has explicit acceptance criteria
- Does not introduce new behavior

## 2. Mandatory Task Header

Every task file MUST include:

- Task ID
- Title
- Status (DRAFT / READY / DONE)
- Spec references (path + version)
- Goal (single paragraph)
- Non-goals
- Acceptance criteria (testable)
- Out-of-scope statement

## 3. Spec Discipline

Tasks MUST:

- Reference exact spec versions
- Avoid interpretation
- Avoid scope expansion
- Stop if ambiguity exists

If ambiguity is detected:
Create a Change-Intent instead of guessing.

## 4. Definition of Done

A task is DONE only if:

- Acceptance criteria are satisfied
- No spec drift occurred
- No additional behavior was introduced
- Review confirms spec alignment
