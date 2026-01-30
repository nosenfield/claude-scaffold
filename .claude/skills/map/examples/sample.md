# Exploration: authentication

Generated: 2026-01-15T14:32:00Z
Depth: medium

## Summary

The authentication system handles user login, session management, and token refresh. It uses JWT tokens with a refresh token rotation strategy, integrating with the UserService for credential validation and EventBus for login/logout events.

## Files Found

### Core Files
- `/src/auth/AuthService.ts` - Main service orchestrating authentication flows
- `/src/auth/TokenManager.ts` - JWT generation, validation, and refresh logic
- `/src/auth/SessionStore.ts` - In-memory and Redis-backed session persistence

### Supporting Files
- `/src/auth/guards/AuthGuard.ts` - Route protection middleware
- `/src/auth/strategies/JwtStrategy.ts` - Passport JWT strategy implementation
- `/src/auth/dto/LoginDto.ts` - Request validation for login endpoint

### Configuration
- `/src/auth/auth.config.ts` - Token expiry, secret keys, refresh settings
- `/src/auth/constants.ts` - Error codes and magic strings

## Architecture Observations

- Uses strategy pattern for authentication methods (JWT, OAuth planned)
- TokenManager is stateless; session state lives in SessionStore
- Refresh tokens are rotated on each use (rotation strategy prevents replay)
- Events emitted: `user.login`, `user.logout`, `token.refresh`, `session.expired`

## Entry Points

- `/src/auth/AuthService.ts` - Start here for understanding auth flows
- `/src/auth/auth.module.ts` - Module registration and dependency injection

## Related Systems

- **UserService** - Provides credential validation and user lookup
- **EventBus** - Receives auth events for audit logging and notifications
- **ApiGateway** - Consumes AuthGuard for protected routes
- **RefreshScheduler** - Background job that cleans expired sessions

## Dependencies

### External
- `jsonwebtoken` - JWT signing and verification
- `passport` - Authentication middleware framework
- `passport-jwt` - JWT strategy for Passport
- `ioredis` - Redis client for distributed session storage

### Internal
- `@/modules/user` - UserService, UserRepository
- `@/modules/events` - EventBus
- `@/shared/config` - Environment configuration
