# Android Veteran Standards

Reference for Planner, Architect, Android Dev, Bug Fix, and Reviewer agents.
Read sections relevant to the handoff — do not load entire file into chat output.

## Kotlin (Idiomatic)

- Prefer **immutable** `val`, data classes, sealed interfaces/classes for UI state and events.
- Use **coroutines + Flow**; expose `StateFlow` from ViewModels; collect in UI with lifecycle awareness.
- `viewModelScope` / structured concurrency; never `GlobalScope`.
- Use `Result`, typed errors, or sealed error states — not bare exceptions across layers.
- Extension functions for mapping; avoid god objects and stringly-typed APIs.
- Prefer expression bodies, `when` exhaustiveness, and null-safe chains over nested if/else.
- Avoid `!!`; use `require`/`check` only for programmer invariants.
- Use `@Immutable` / `@Stable` on state models when appropriate for Compose skippability.

## Architecture (Production)

- **UDF**: Events up, State down. Single source of truth in ViewModel or presenter layer.
- **Layers**: UI (Compose) → ViewModel → UseCase (optional) → Repository → DataSource.
- **Repository pattern** mandatory for data access; no direct Retrofit/Room in Composables.
- **Hilt** for DI; constructor injection; correct scopes (`@Singleton`, `@ViewModelScoped`).
- **Navigation**: type-safe routes where project supports it; pass minimal args; use `SavedStateHandle` for process death.
- **Modularization**: feature modules must not depend on each other; shared code in `core:*`.
- No business logic in Composables beyond UI mapping.

## Jetpack Compose (Expert)

### State

- Hoist state to lowest common owner; ViewModel owns business state.
- `rememberSaveable` for UI state that survives config change / process death.
- `derivedStateOf` for expensive derivations; avoid recomputing in composition body.
- Minimize `mutableStateOf` in leaf composables when state belongs in ViewModel.
- One-off events: `Channel`/`SharedFlow` collected in `LaunchedEffect`, not stored in UI state.

### Performance

- Stable parameters; avoid passing unstable lambdas — use method references or `remember`.
- Keys on `LazyColumn`/`LazyRow` items; use `items(key = {})`.
- Avoid heavy work in `@Composable`; use `remember` or ViewModel.
- Prefer `Modifier` chains in correct order: size → layout → drawing → pointer.
- Use `Lazy*` layouts for lists; never `Column` + `forEach` for long lists.
- Profile recomposition mentally: flag reads of rapidly changing state high in tree.

### Side effects

- `LaunchedEffect(key)` for coroutines tied to composition lifecycle.
- `DisposableEffect` for register/unregister (listeners, callbacks).
- `SideEffect` only for non-Compose sync; prefer ViewModel for business side effects.

### Material 3

- Use theme tokens: `MaterialTheme.colorScheme`, `typography`, `shapes`.
- Prefer `Card`, `FilledTonalButton`, etc. over raw colors.
- Support light/dark if project theme supports it.

## Responsive & Adaptive UI

- Use **WindowSizeClass** (`WindowWidthSizeClass`, `HeightSizeClass`) — not raw dp hacks alone.
- Patterns: compact = single pane; medium/expanded = list-detail, two-pane (`TwoPane` / master-detail).
- Read **`LocalConfiguration`** for orientation; **`LocalDensity`** for fontScale — scale touch targets and spacing.
- **`BoxWithConstraints`** only when size-class insufficient; document why.
- Support **font scaling** (accessibility) — no fixed text clipping; use `TextOverflow` and flexible layouts.
- **Foldables / tablets**: test expanded width; avoid hard-coded phone-only widths.
- **Edge-to-edge**: respect `WindowInsets` / `systemBarsPadding` / `imePadding`.
- Reuse project responsive utilities if they exist (e.g. `ResponsiveDimens`, adaptive helpers in `core-ui`).
- Landscape: verify toolbars, sheets, and media controls remain usable.

## Accessibility

- `contentDescription` on meaningful icons/images; merge semantics where appropriate.
- Minimum 48dp touch targets; sufficient color contrast (WCAG-minded).
- Focus order and keyboard/D-pad where applicable.

## Data & Offline

- Repository returns `Flow` for observable data; single-shot via suspend functions.
- Handle loading / empty / error / content in `UiState` sealed hierarchy.
- Offline-first when product requires it; cache policy explicit in Repository.

## Testing

- **ViewModel**: JUnit + coroutines test + Turbine for Flow; fake repositories.
- **Compose UI**: `createComposeRule`, semantics, meaningful user flows.
- **Repository**: integration tests with in-memory Room / fake API.
- Do not test framework behavior; test business rules and state transitions.

## Performance & Release

- Avoid memory leaks: cancel jobs, clear listeners in `onCleared` / `DisposableEffect`.
- Large bitmaps/video: correct lifecycle; do not hold Activity context in ViewModel.
- R8/ProGuard: keep rules for reflective models when needed.
- ANR: no blocking main thread; use `withContext(Dispatchers.IO)`.

## Security

- No secrets in source; use BuildConfig/local.properties patterns already in project.
- Validate deep links and exported components.
- Encrypted storage for tokens when applicable (EncryptedSharedPreferences / DataStore).

## Gradle & Modules

- Version catalog (`libs.versions.toml`); align compileSdk/minSdk with project.
- New dependencies: minimal scope (`implementation` vs `api`); feature module boundaries respected.

## Bug-Fix Patterns (Common)

- Rotation / process death: `rememberSaveable`, ViewModel state, `SavedStateHandle`.
- Double-click / duplicate nav: debounce or `LaunchedEffect` job cancellation.
- Flow collection: use `repeatOnLifecycle(Lifecycle.State.STARTED)` in Activities/Fragments; in pure Compose use lifecycle-aware collection patterns.
- Compose state sync: `LaunchedEffect` loops that fight user input — prefer single writer.
- Media/editor: lifecycle of player/recorder tied to `DisposableEffect` / ViewModel `onCleared`.

## Reviewer Quick Gates (Android)

Before approving Android work, verify:

1. UiState covers loading/empty/error/success where applicable.
2. No business logic leaking into Composables.
3. Responsive behavior considered (width size class or project adaptive pattern).
4. Recomposition risks acceptable; lazy lists keyed.
5. Lifecycle and cancellation handled.
6. Lint clean on changed Kotlin files.
7. **Gradle build passes** on affected module(s) — see [build-test-visual-qa.md](build-test-visual-qa.md).
8. **Tests pass** for changed logic (or gap documented).
9. **Visual QA imagined** for any UI change — layout, states, theme, responsive configs.
