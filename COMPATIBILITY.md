# Compatibility matrix

Every claim here is a claim about a specific APK. Three states, and no fourth:

| State | Meaning |
|---|---|
| **Supported** | A patch run against this exact app version produced an APK that installed and worked. Recorded with the date, the device and the patch set. |
| **Experimental** | It runs, or is expected to, but has not been verified end to end. Available to users who opt in. |
| **Unsupported** | It does not work on this version, for a stated reason. |

Nothing in this file is inherited as "supported". Upstream's declarations are reproduced below as
**experimental at best**, because no MAX build has been produced or installed yet.

## Tracked apps

### YouTube — `com.google.android.youtube`

| Version | Upstream declares | MAX state | Evidence |
|---|---|---|---|
| 21.45.82 | experimental | **Unsupported for 8 patches**, experimental otherwise | See the NavigationBarHookPatch defect below |
| 21.44.528 | experimental | experimental | none |
| 21.43.523 | experimental | experimental | none |
| 21.30.216 | stable | experimental | none |
| 21.28.208 | stable | experimental | none |
| 21.23.492 | stable | experimental | none |
| 20.51.39 | stable | experimental | none |
| 20.26.46 | stable | experimental | none |

### YouTube Music — `com.google.android.apps.youtube.music`

| Version | Upstream declares | MAX state |
|---|---|---|
| 9.46.51, 9.45.51, 9.44.52 | experimental | experimental |
| 9.30.53, 9.20.53, 9.15.51 | stable | experimental |

### Reddit — `com.reddit.frontpage`

| Version | Upstream declares | MAX state |
|---|---|---|
| 2026.46.0, 2026.45.0, 2026.44.0 | experimental | experimental |
| 2026.40.0, 2026.24.0, 2026.10.0, 2024.02.0 | stable | experimental |

## The NavigationBarHookPatch defect, and the eight patches it blocks

On YouTube 21.45.82 the `navigationBarHookPatch` fails while patching:

```
Could not find resource type: DRAWABLE name: yt_fill_bell_black_24
```

Cause, traced through the source: `SetEnumMapFingerprint` in
`patches/.../youtube/misc/navigation/Fingerprints.kt` begins with
`resourceLiteral(ResourceType.DRAWABLE, "yt_fill_bell_black_24")`, and `resourceLiteral` is fatal by
default when the APK does not carry that name. The surrounding block is a cosmetic repair — it fills
in YouTube's missing notification-tab icon — and it is not guarded by any version check, so it takes
the whole hook patch down with it.

Because a failed dependency fails its dependents, these eight patches fail on 21.45.82 as well:

| Patch | File |
|---|---|
| AI channel filter | `youtube/misc/aislist/AiSListPatch.kt` |
| Navigation buttons | `youtube/layout/buttons/navigation/NavigationBarPatch.kt` |
| DeArrow | `youtube/layout/dearrow/DeArrowPatch.kt` |
| Change form factor | `youtube/layout/formfactor/ChangeFormFactorPatch.kt` |
| Hide layout components | `youtube/layout/hide/general/HideLayoutComponentsPatch.kt` |
| Hide horizontal shelves | `youtube/layout/hide/shelves/HideHorizontalShelvesPatch.kt` |
| Hide Shorts components | `youtube/layout/hide/shorts/HideShortsComponentsPatch.kt` |
| Open Shorts in regular player | `youtube/layout/shortsplayer/OpenShortsInRegularPlayerPatch.kt` |
| Series tracker | `youtube/video/series/SeriesTrackerPatch.kt` |

Nine rows for eight dependents: `NavigationBarPatch.kt` is both a dependent and a user of the same
hook. All are **unsupported on 21.45.82** until the fix is verified against a real APK.

### Fix status: not started, deliberately

The fix needs the target APK's resource table. Which drawable replaced `yt_fill_bell_black_24` in
21.45.82 is not knowable from source, and guessing it would be exactly the invented resource id this
project forbids. The plan, in order:

1. Dump the resource table of a legitimately obtained 21.45.82 APK (`aapt2 dump resources`, or the
   ARSCLib the engine already uses) and list every `drawable` whose name mentions `bell` or
   `notification`.
2. Compare with 21.43.523 and 21.44.528 to find the version where the rename happened.
3. Guard the cosmetic repair by resource existence so the hook patch stops failing when neither name
   is present, then add a version-aware fingerprint for the name that actually exists.
4. Regression-test all eight patches against 21.45.82, 21.44.528, 21.43.523 and 21.30.216.
5. Only then move 21.45.82 from unsupported to experimental for those patches.

## How a row earns "supported"

A row moves to supported when a log records: the app version and its signature, the exact patch set,
the engine version and the bundle version, the device and Android version, that the patched APK
installed, and that the patch's feature was observed working. Anything less stays experimental.
