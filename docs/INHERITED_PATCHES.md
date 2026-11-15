# Inherited patch inventory

Source: Morphe Patches at `2.3.0-dev.6` (`581b162d41dffa4c2ae988c1b391da276d96db9d`) and the
released `2.2.0` (`44031c561ea048c8f196877f30a49c13bfd6afb6`).

## Size

| App | `*Patch.kt` files | Patches in the generated list |
|---|---|---|
| YouTube | 205 | 118 |
| YouTube Music | 63 | 57 |
| Reddit | 37 | 32 |
| Shared (used by the above) | 42 | — |
| `all` (app-agnostic) | 6 | — |
| **Total patch files** | **353** | **212 (dev), 202 (2.2.0)** |

The gap between patch files and listed patches is expected: some files hold several patches, some
hold helpers, and shared patches are not listed on their own.

## Import order for Phase 4

1. Build scaffolding: `settings.gradle.kts`, `build.gradle.kts`, `gradle.properties`, the wrapper,
   and the `patches`/`extensions` module layout.
2. Shared and `all` patches, because everything depends on them.
3. YouTube, in dependency order: settings and shared first, then the eight NavigationBarHookPatch
   dependents.
4. YouTube Music and Reddit.
5. Regenerate `patches-list.json` from the build, never by hand.

## Known-bad at import time

The eight patches listed in `COMPATIBILITY.md` under the NavigationBarHookPatch defect are imported
as **unsupported on YouTube 21.45.82**, with the reason recorded. Importing them as experimental
would repeat the unevidenced claim this project exists to avoid.
