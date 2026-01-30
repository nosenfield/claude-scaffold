# Exploration: {target}

Generated: {ISO timestamp}
Depth: {quick|medium|thorough}

## Summary

[2-3 sentence overview of what was found. Include the primary purpose of this system/feature and its role in the codebase.]

## Files Found

[List files discovered, grouped logically. Include brief description of each file's relevance.]

### Core Files
- `/absolute/path/to/file.ts` - [brief description of relevance]
- `/absolute/path/to/other.ts` - [brief description]

### Supporting Files
- `/absolute/path/to/helper.ts` - [brief description]

### Configuration
- `/absolute/path/to/config.ts` - [brief description]

## Architecture Observations

[Key patterns, structures, or design decisions observed.]

- [Pattern or structure observed, e.g., "Uses repository pattern for data access"]
- [Dependency relationship, e.g., "AuthService depends on TokenManager and UserRepository"]
- [Design decision, e.g., "Events are handled via pub/sub through EventBus"]

## Entry Points

[Primary file(s) to start with when working on this target. These are the recommended starting points for understanding or modifying this system.]

- `/absolute/path/to/main-entry.ts` - [why this is a good starting point]
- `/absolute/path/to/secondary.ts` - [alternative entry point if applicable]

## Related Systems

[Other systems, features, or modules that interact with this target. Useful for understanding impact radius.]

- **[System Name]** - [How it relates, e.g., "Consumes auth tokens for API requests"]
- **[System Name]** - [How it relates, e.g., "Triggers user events on state changes"]

## Dependencies

[External packages or internal modules this system depends on.]

### External
- `package-name` - [purpose]

### Internal
- `@/modules/shared` - [purpose]
