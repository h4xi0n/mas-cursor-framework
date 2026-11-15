# Backend Engineering Standards

Reference standards for [mas-backend-dev](../../mas-backend-dev/SKILL.md), [mas-architect](../../mas-architect/SKILL.md), [mas-api-contract](../../mas-api-contract/SKILL.md), and [mas-reviewer](../../mas-reviewer/SKILL.md) (Step 0n).

---

## 1. Clean Architecture & Layering Invariants

Backend services must adhere to Clean Architecture principles with strict dependency inversion:

```
┌────────────────────────────────────────────────────────┐
│ Presentation Layer (REST / gRPC / GraphQL Controllers) │
└───────────────────────────┬────────────────────────────┘
                            │ depends on
┌───────────────────────────▼────────────────────────────┐
│ Domain & Business Layer (Use Cases, Domain Entities)    │
└───────────────────────────▲────────────────────────────┘
                            │ inverted dependency
┌───────────────────────────┴────────────────────────────┐
│ Data & Persistence Layer (Repository Impl, Migrations) │
└────────────────────────────────────────────────────────┘
```

1. **Domain Layer**: Contains pure business entities and use case logic. It has zero external dependencies on web frameworks, ORMs, or database drivers.
2. **Repository Interfaces**: Defined in the domain layer. Concrete database implementations live in the persistence layer.
3. **Presentation Layer**: Thin HTTP/gRPC handlers that validate incoming payloads, invoke domain use cases, and format HTTP responses. Zero business logic in controllers.

---

## 2. Database Migration Hygiene

### Versioned Forward-Only Migrations
- All schema alterations must be captured in discrete, immutable, timestamped or sequentially numbered migration files (e.g. Flyway `V001__create_users.sql`, Prisma `migrations/20241115_init/migration.sql`, or Room `@Migration`).
- **Zero Runtime DDL**: Application startup code must **never** execute raw `CREATE TABLE`, `ALTER TABLE`, or `DROP TABLE` strings.
- **Backward Compatibility**: Migrations in production environments must be backward-compatible (expand-and-contract pattern). Adding non-nullable columns must provide explicit default values.
- **Rollback Verification**: For every forward migration, a clean reverse/down migration script or rollback procedure must be documented and verified.

---

## 3. SQL Injection Defense & Parameterization

### Zero String Interpolation Invariant
Raw string concatenation or template interpolation in SQL queries is strictly forbidden and constitutes a P0 security blocker.
- **Enforcement**: All database queries must use parameterized placeholders:
  - PostgreSQL / SQLite: `$1, $2` or `?` placeholders.
  - ORMs / Query Builders: Prisma parameters, SQLAlchemy `bindparam`, or Room `@Query("SELECT * FROM items WHERE id = :itemId")`.
- Dynamic table names or sort directions must validate against an explicit whitelist of allowed identifiers before execution.

---

## 4. Idempotency & State-Mutating Endpoints

To prevent duplicate side-effects from client retries or network drops:
1. **Idempotency Keys**: State-mutating endpoints (`POST /payments`, `POST /transfers`, `POST /orders`) must require an `Idempotency-Key` HTTP header.
2. **Deduplication Storage**: The backend must cache the response payload associated with each `Idempotency-Key` in Redis or PostgreSQL with a 24-hour TTL:
   - If the same key arrives while the initial request is in-flight: return HTTP 409 Conflict or wait.
   - If the key has already been completed: return the cached response payload immediately with an `Idempotent-Replayed: true` header.

---

## 5. Authentication, Authorization & RBAC

- **Route Protection**: Every endpoint is private by default. Public endpoints must be explicitly annotated (e.g. `@PublicRoute` or unauthenticated whitelist).
- **JWT Validation**: Verify signature, expiration (`exp`), issuer (`iss`), and audience (`aud`). Never store sensitive session state in unencrypted JWT claims.
- **Role-Based Access Control (RBAC)**: Enforce role checks in middleware or domain use cases (e.g. `UserRole.ADMIN`, `UserRole.EDITOR`), not scattered in UI presentation code.

---

## 6. Multi-Stack Reference Architectures

### A. Kotlin / Ktor / Exposed Stack
```kotlin
// Domain Interface
interface UserRepository {
    suspend fun findById(id: UUID): User?
    suspend fun save(user: User): User
}

// Controller Handler
fun Route.userRoutes(userService: UserService) {
    post("/api/v1/users") {
        val request = call.receive<CreateUserRequest>()
        val user = userService.createUser(request.toCommand())
        call.respond(HttpStatusCode.Created, user.toResponse())
    }
}
```

### B. Python / FastAPI / Pydantic Stack
```python
from fastapi import APIRouter, Depends, Header, HTTPException, status
from pydantic import BaseModel, EmailStr

router = APIRouter(prefix="/api/v1/users", tags=["users"])

class CreateUserSchema(BaseModel):
    email: EmailStr
    full_name: str

    model_config = {"extra": "forbid"}

@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_user(
    payload: CreateUserSchema,
    idempotency_key: str = Header(..., alias="Idempotency-Key"),
    service: UserService = Depends(get_user_service),
):
    return await service.create_user(payload, idempotency_key)
```

### C. TypeScript / Node / Prisma Stack
```typescript
import { Router, Request, Response } from 'express';
import { z } from 'zod';

const CreateUserDto = z.object({
  email: z.string().email(),
  name: z.string().min(2),
}).strict();

export const userRouter = Router();

userRouter.post('/', async (req: Request, res: Response) => {
  const validated = CreateUserDto.parse(req.body);
  const user = await userService.registerUser(validated);
  return res.status(201).json(user);
});
```
