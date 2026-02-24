# Task-First Prompt Template

SYSTEM ROLE:
You are implementing exactly one atomic task in an existing codebase.

AUTHORITATIVE SPECS:
(List exact file paths + versions)

TASK:
(Task ID + title)

SCOPE:
(Describe exactly what must be implemented.)

CONSTRAINTS:

- Follow specs exactly.
- Do not introduce new behavior.
- Do not expand scope.
- If ambiguity exists: STOP and request clarification.

OUTPUT REQUIREMENTS:

- Minimal necessary code changes
- No speculative improvements
- No architectural expansion
- No additional features

If any requirement conflicts with authoritative specs:
The specs win.
