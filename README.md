# MAX Patches

The patch collection for [MAX Patcher](https://github.com/sufiyan-sabeel/max-patcher), maintained
independently of Morphe Patches, from which it is inherited.

**Status: initialising.** This repository currently holds the licensing, the compatibility policy
and the inherited inventory. The patch sources and extensions themselves (353 patch files across
YouTube, YouTube Music and Reddit) are imported in Phase 4, together with the build pipeline.

## What a patch collection is

A patch is a Kotlin module that declares what it changes, which apps and versions it applies to,
and what it depends on. Many patches also ship an *extension* — Java code injected into the target
app that does the work at runtime. A bundle is the signed `.mpp` archive that MAX Patcher downloads.

## Rules this collection follows

1. **No inherited compatibility claim.** A version is marked supported only after a patch run
   against that exact APK produced an installable result. Upstream's declarations are a starting
   hypothesis, not evidence. See [COMPATIBILITY.md](COMPATIBILITY.md).
2. **No invented resource identifiers.** If a patch needs a resource that the target APK does not
   have, the patch fails and says so. It does not get a guessed id, and it does not get an exception
   swallowed to look successful.
3. **Attribution travels.** Every patch keeps its upstream copyright header, and NOTICE is
   redistributed with every bundle.
4. **Dependencies are honoured.** A patch that depends on another runs after it, and a failed
   dependency fails its dependents. That behaviour is a feature.

## Inherited inventory

| App | Patch files | Declared target versions |
|---|---|---|
| YouTube (`com.google.android.youtube`) | 205 | 8, from 20.26.46 to 21.45.82 |
| YouTube Music (`com.google.android.apps.youtube.music`) | 63 | 6, from 9.15.51 to 9.46.51 |
| Reddit (`com.reddit.frontpage`) | 37 | 7, from 2024.02.0 to 2026.46.0 |
| Shared, used by the above | 42 | n/a |

Counts are from the upstream tree at Morphe Patches `2.3.0-dev.6`; the released `2.2.0` list
contains 202 patches.

## Licence

GPLv3. See [NOTICE](NOTICE).
