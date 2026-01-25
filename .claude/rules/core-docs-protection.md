---
paths:
  - "_docs/prd.md"
  - "_docs/architecture.md"
  - "_docs/best-practices.md"
---

# Core Documentation Rules

Core documentation defines the project's requirements, design, and standards. These files are authored by humans and should not be modified by agents.

## File Purposes

| File | Purpose | Author |
|------|---------|--------|
| prd.md | Product requirements, features, goals | Human (product) |
| architecture.md | System design, tech stack, structure | Human (architect) |
| best-practices.md | Coding standards, conventions | Human (tech lead) |

## Agent Permissions

| Operation | Permitted |
|-----------|-----------|
| Read for context | Yes |
| Reference in plans | Yes |
| Quote in reviews | Yes |
| Modify content | No |
| Suggest changes | Yes (in chat, not file) |

## When Documentation Seems Outdated

If core documentation conflicts with codebase reality:

1. **Do NOT modify the documentation**
2. Report discrepancy to user:
   ```
   DISCREPANCY: Documentation may need update
   File: [doc file path]
   Section: [relevant section]
   Documentation states: [what doc says]
   Codebase shows: [what code does]
   Recommendation: [suggested doc update]
   ```
3. Continue following documentation unless user directs otherwise
4. User may update documentation or confirm code should match docs

## Derived Information

Agents may create derived artifacts that reference core docs:
- Implementation plans (reference architecture.md)
- Code reviews (reference best-practices.md)
- Test scenarios (reference prd.md acceptance criteria)

These derived artifacts go in session context or memory bank, not in _docs/.

## Rationale

Core documentation represents human decisions about:
- What to build (prd.md)
- How to build it (architecture.md)
- Quality standards (best-practices.md)

Agents implement these decisions; they don't make them.
