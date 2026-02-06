# Product Requirements Document

## Overview

[Product description, problem being solved, and target users. This section is intentionally flexible - write what communicates the vision effectively.]

## Goals

1. [Primary goal - what success looks like]
2. [Secondary goal]
3. [Additional goals as needed]

## Scope

### In Scope (MVP)

- [Capability or feature included in initial release]
- [Capability or feature included in initial release]
- [Capability or feature included in initial release]

### Out of Scope

- [Explicitly excluded - prevents scope creep during implementation]
- [Explicitly excluded]
- [Future consideration, not MVP]

---

## Requirements

Choose ONE structure below based on product type. Delete unused options.

<!-- OPTION A: Features (general products, utilities, tools) -->

### Feature: [Feature Name]

**Priority**: High | Medium | Low
**Description**: [What this feature does and why it matters]

**Acceptance Criteria**:
- [ ] [Testable condition that defines "done"]
- [ ] [Testable condition]
- [ ] [Testable condition]

**Technical Considerations**: [Optional - implementation hints, constraints, or patterns that inform architecture]

### Feature: [Feature Name]

**Priority**: High | Medium | Low
**Description**: [What this feature does]

**Acceptance Criteria**:
- [ ] [Testable condition]
- [ ] [Testable condition]

<!-- OPTION B: User Stories (stakeholder-oriented, enterprise products) -->

### Epic: [Epic Name]

#### US-1: [Story Title]

**As a** [user type]
**I want to** [action]
**So that** [benefit]

**Acceptance Criteria**:
- [ ] [Testable condition]
- [ ] [Testable condition]
- [ ] [Testable condition]

#### US-2: [Story Title]

**As a** [user type]
**I want to** [action]
**So that** [benefit]

**Acceptance Criteria**:
- [ ] [Testable condition]
- [ ] [Testable condition]

<!-- OPTION C: Systems (games, simulations, technical products) -->

### System: [System Name]

**Purpose**: [What this system handles]

| Parameter | Value | Notes |
|-----------|-------|-------|
| [Config] | [Default] | [Tuning notes] |
| [Config] | [Default] | [Tuning notes] |

**Behavior**:
- [How the system works]
- [Key interactions]

**Acceptance Criteria**:
- [ ] [Testable condition]
- [ ] [Testable condition]

---

## Technical Context

Information that informs architecture.md and technology choices.

### Constraints

| Type | Constraint | Rationale |
|------|------------|-----------|
| Technical | [e.g., Must run in browser] | [Why] |
| Performance | [e.g., < 100ms response time] | [Why] |
| Compatibility | [e.g., Support Safari 15+] | [Why] |

### Dependencies

| Dependency | Type | Notes |
|------------|------|-------|
| [External API, library, or service] | Required / Optional | [Version, availability] |
| [External API, library, or service] | Required / Optional | [Notes] |

### Technology Preferences

[Optional - if there are known stack requirements or preferences, note them here. Otherwise, let architecture.md determine stack.]

- [e.g., Must use TypeScript for type safety]
- [e.g., Prefer Postgres for relational data]

---

## Open Questions

Unresolved items that may block task creation or implementation. Resolve before finalizing task-list.json.

- [ ] [Question requiring decision]
- [ ] [Question requiring research]
- [ ] [Assumption needing validation]

---

## Appendix (Optional)

Include additional context as needed. Common appendices:

- **Glossary**: Domain-specific terms
- **User Personas**: If user context aids implementation decisions
- **Success Metrics**: If runtime metrics inform feature design
- **Wireframes/Mockups**: Visual references
- **Prior Art**: Reference implementations or competitors
