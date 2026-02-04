# Code Review Principles

Project-agnostic principles for effective code review.

---

## Review Focus Areas

| Area | Questions to Ask |
|------|------------------|
| **Correctness** | Does the code implement requirements accurately? |
| **Functionality** | Is the logic sound? Are edge cases handled? |
| **Design** | Is the solution architecture appropriate? |
| **Complexity** | Is the code as simple as possible but no simpler? |
| **Testing** | Is there adequate test coverage? |
| **Performance** | Are there obvious performance issues? |
| **Security** | Are there security vulnerabilities? |
| **Maintainability** | Is the code readable and well-structured? |

---

## Pre-Review Checklist (Author)

Before requesting review:
- [ ] Code compiles/runs without errors
- [ ] All tests pass locally
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] PR description clearly explains changes
- [ ] Related documentation updated

---

## Communication Guidelines

### Be Constructive
- Focus on the code, not the person
- Explain reasoning behind suggestions
- Acknowledge good patterns and solutions
- Frame feedback objectively

### Be Clear
- Distinguish between blocking issues and suggestions
- Use prefixes to indicate severity:
  - `[blocking]` - Must fix before merge
  - `[suggestion]` - Consider for improvement
  - `[nit]` - Minor style preference
  - `[question]` - Seeking clarification

### Be Helpful
- Provide actionable suggestions, not just criticism
- Include code examples when proposing alternatives
- Link to relevant documentation or patterns

### Example Feedback

```markdown
// Poor
"This is wrong."

// Better
"[blocking] This query is vulnerable to SQL injection.
Consider using parameterized queries:
`db.query('SELECT * FROM users WHERE id = ?', [userId])`"

// Poor
"Why did you do it this way?"

// Better
"[question] I see you chose to use a Map here instead of an object.
Was this for a specific performance reason, or would an object work?"
```

---

## Review Efficiency

### Keep PRs Focused
- Review smaller, focused PRs (ideally under 400 lines)
- Large PRs can be split into logical chunks
- Each PR should represent a complete, reviewable unit

### Timely Feedback
- Provide feedback within 24 hours when possible
- If review will be delayed, communicate that
- Set team expectations for response times

### Use Automation
- Let linters catch style issues
- Use static analysis for common bugs
- Reserve human review for design and logic

### Prioritize Feedback
- Focus on high-level concerns first, then details
- Major architectural issues > minor style issues
- Blocking issues > nice-to-haves

---

## Triage Framework

For each issue found, assess:

### Severity
| Level | Description | Action |
|-------|-------------|--------|
| **Blocking** | Correctness, security, data loss risk | Must fix before merge |
| **Important** | Performance, maintainability concerns | Should fix, may defer with justification |
| **Minor** | Style, naming, documentation | Nice to fix, not required |

### Effort
| Level | Description |
|-------|-------------|
| **Low** | < 15 minutes, isolated change |
| **Medium** | 15-60 minutes, may touch multiple files |
| **High** | > 60 minutes, significant refactor |

### Decision Matrix
- **Security issues**: Always address now
- **Low effort + in modified files**: Address now
- **High effort + outside scope**: Defer (create follow-up task)
- **Style/convention**: Let linter handle

---

## Responding to Reviews (Author)

- Respond to all comments, even if just acknowledging
- Be open to suggestions and alternative approaches
- Ask for clarification if feedback is unclear
- Mark conversations as resolved when addressed
- Don't take feedback personally

---

## Review Checklist

When reviewing code:

- [ ] Understand the context (read PR description, linked issues)
- [ ] Check correctness against requirements
- [ ] Verify edge cases are handled
- [ ] Look for security vulnerabilities
- [ ] Assess test coverage adequacy
- [ ] Check for obvious performance issues
- [ ] Verify code follows project conventions
- [ ] Distinguish blocking from non-blocking issues
- [ ] Provide actionable feedback
- [ ] Acknowledge what's done well
