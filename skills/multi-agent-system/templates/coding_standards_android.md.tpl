# Coding Standards

## Architecture

{{ARCHITECTURE}}

## Kotlin

- Idiomatic Kotlin: immutability, sealed state/events, extension functions for mapping.
- Coroutines + Flow; `StateFlow` in ViewModels; structured concurrency only.
- No `!!`; typed errors or sealed error states across layers.

## Jetpack Compose

- UDF: events up, state down; ViewModel owns business state.
- `rememberSaveable` for UI survival across process death where needed.
- `derivedStateOf` for expensive derivations; keyed lazy lists.
- Side effects: `LaunchedEffect` / `DisposableEffect` with correct keys.
- Material 3 theme tokens; no hard-coded colors outside theme.
- Performance: stable params, avoid heavy work in composition body.

## Responsive & Adaptive UI

- Prefer **WindowSizeClass** and project adaptive utilities over fixed phone layouts.
- Handle fontScale, orientation, and window insets (system bars, IME).
- Compact / medium / expanded layouts where UI would otherwise break on tablet or foldable.
- Minimum 48dp touch targets; support accessibility font scaling without clipping.

## DI & Data

- Hilt constructor injection; correct scopes.
- Repository pattern for all data access; no network/DB in Composables.

## Testing

- ViewModel: JUnit + Turbine + fake repositories.
- Compose UI tests for critical user flows when adding screens.
- No trivial tests; no testing of framework internals.

## Naming

- Descriptive names; event handlers use `handle` prefix (e.g. `handleClick`).

## Code Quality

- Early returns; minimal scope diffs.
- Match existing conventions; reuse components before creating new ones.
- Comments only for non-obvious business logic.
