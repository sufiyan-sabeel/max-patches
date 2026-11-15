# YouTube 21.45.82: the navigation-bar hook failure

**Status: unresolved, and deliberately untouched.** No fingerprint has been changed, no drawable name
has been guessed, and the eight dependent patches remain unsupported on 21.45.82.

This document records what is established from source, what is not established, and exactly what the
APK will settle.

---

## 1. The failure, as reported

```
NavigationBarHookPatch.navigationBarHookPatch fails:
Could not find resource type: DRAWABLE name: yt_fill_bell_black_24
```

Environment: YouTube `com.google.android.youtube` 21.45.82, Android 16 / API 36, Vivo V2521,
MAX Manager 0.1.0, MAX Engine 2.3.1, MAX Patches 2.3.0-dev.7.

## 2. Established from source, no APK needed

**The throw site.** `resourceLiteral` is defined in the engine as

```kotlin
fun resourceLiteral(
    type: ResourceType,
    name: String,
    exceptionIfResourceNotFound: Boolean = true,
    ...
) = LiteralFilter({ if (exceptionIfResourceNotFound || hasResourceId(type, name)) resourceId(type, name) else null }, …)
```

With the default, `resourceId(type, name)` calls `ResourceIds.get`, which throws
`PatchException("Could not find resource type: $type name: $name")` — the reported message, character
for character. The failure happens while the filter is *evaluated*, i.e. during fingerprint matching,
before any instruction is rewritten.

**The only site in the collection.** `yt_fill_bell_black_24` appears exactly once:

| File | Line | Use |
|---|---|---|
| `patches/src/main/kotlin/app/morphe/patches/youtube/misc/navigation/Fingerprints.kt` | 157 | `resourceLiteral(ResourceType.DRAWABLE, "yt_fill_bell_black_24")` inside `SetEnumMapFingerprint` |

A second bell name exists in the codebase, in the extension rather than in a fingerprint:
`extensions/youtube/src/main/java/app/morphe/extension/youtube/shared/NavigationBar.java:616` uses
`yt_fill_experimental_bell_vd_theme_24` for 20.31+. That tells us YouTube ships a bell drawable under a
different name in newer versions; it does **not** tell us what 21.45.82 ships, and it is not evidence
enough to substitute one name for the other.

**Why the whole hook patch dies.** `SetEnumMapFingerprint` is applied at the end of
`navigationBarHookPatch`'s `execute` block, unguarded by any version check:

```kotlin
// Fix YT bug of notification tab missing the filled icon.
val cairoNotificationEnumReference = ImageEnumConstructorFingerprint
    .instructionMatches.last().getInstruction<ReferenceInstruction>().reference

SetEnumMapFingerprint.let { … }        // ← line 358 in upstream dev.7, 386 in this repository's import
```

The block is a **cosmetic repair**: it fills in the notification tab's missing filled icon. It is not
load-bearing for any hook the patch installs above it. But because the fingerprint is fatal by default,
a missing drawable aborts the whole patch, and every dependent patch fails with it.

**The eight dependents**, each with the line that names the dependency:

| Patch | File:line of `navigationBarHookPatch,` |
|---|---|
| Navigation buttons | `youtube/layout/buttons/navigation/NavigationBarPatch.kt:212` |
| DeArrow | `youtube/layout/dearrow/DeArrowPatch.kt:57` |
| Change form factor | `youtube/layout/formfactor/ChangeFormFactorPatch.kt:42` |
| Hide layout components | `youtube/layout/hide/general/HideLayoutComponentsPatch.kt:122` |
| Hide horizontal shelves | `youtube/layout/hide/shelves/HideHorizontalShelvesPatch.kt:27` |
| Hide Shorts components | `youtube/layout/hide/shorts/HideShortsComponentsPatch.kt:175` |
| Open Shorts in regular player | `youtube/layout/shortsplayer/OpenShortsInRegularPlayerPatch.kt:39` |
| AI channel filter | `youtube/misc/aislist/AiSListPatch.kt:45` |
| Series tracker | `youtube/video/series/SeriesTrackerPatch.kt:83` |

Nine files, eight dependents plus `NavigationBarPatch`, which both depends on the hook and uses it.

**Upstream has not fixed it.** Comparing this repository's import (upstream `dev` at `581b162d`,
version 2.3.0-dev.6) against upstream `dev` at `197969bc` (version **2.3.0-dev.7**):

- `Fingerprints.kt` is **byte-identical** — the fatal `resourceLiteral` line is unchanged.
- `NavigationBarHookPatch.kt` differs only in imports and one refactor (`addPatchInterface` replacing a
  hand-built `ImmutableMethod`), which shifted the `SetEnumMapFingerprint` block from line 386 to 358.

**A line-number discrepancy worth resolving.** The reported frame is `NavigationBarHookPatch.kt:387`.
Upstream dev.7 has that block at **358**; this repository's import has it at **386**. The report is
therefore closer to this repository's tree than to upstream dev.7 — while the bundle identifies itself
as 2.3.0-dev.7, which is upstream's version string, not this repository's (0.1.0). Before fixing
anything, we should know which tree produced the failing run, because the fix goes in one of them.

## 3. Not established, and not to be guessed

- Whether `yt_fill_bell_black_24` was renamed, removed, or merely moved in 21.45.82.
- Which drawable the notification tab uses in 21.45.82.
- Whether the enclosing method's shape still matches `SetEnumMapFingerprint`'s other two filters
  (`Integer.valueOf` within 10 instructions, then `EnumMap.put` within 10).
- Whether `ImageEnumConstructorFingerprint` (`TAB_ACTIVITY_CAIRO`) still matches, and whether
  `NavigationEnumFingerprint`, `InitializeButtonsFingerprint` and `PivotBar*` still match.

Every one of those is answerable from the APK, and none of them from the source.

## 4. What the APK will settle: the inspection protocol

`tools/apk-resource-audit.sh <youtube.apk>` runs the whole thing and writes evidence files. It does not
modify anything. It answers:

1. **Identity.** SHA-256 of the APK and its signing certificate, so the result is tied to one file and
   the certificate can be checked against the two the compatibility declaration accepts.
2. **Presence.** Does `drawable/yt_fill_bell_black_24` exist? (yes / no, printed explicitly)
3. **Candidates.** Every drawable whose name mentions `bell` or `notification` — the list from which the
   replacement must come, if there is one.
4. **Structure.** Every method holding `EnumMap.put(Enum, Object)`, with the integer constants near it,
   so the notification-tab map can be identified and compared against the fingerprint's shape.

Then, by hand:

```bash
# the resource id of whichever name the audit found
aapt2 dump resources youtube-21.45.82.apk | grep -A2 "drawable/<chosen name>"

# the method, decompiled, to confirm the EnumMap.put shape
baksmali d youtube-21.45.82.apk -o out/smali
grep -rl "Ljava/util/EnumMap;->put" out/smali | head
```

## 5. Decision tree, once the APK is in hand

| Finding | Correct fix |
|---|---|
| The drawable exists under the same name, and only the enclosing method changed | the fingerprint's structure filters need updating; the resource name stays |
| The drawable exists under a **different** name that is unambiguously the same icon | version-aware fingerprint: keep the old one for older versions, add the new one gated on `is_21_45_or_greater`, chosen by version, never by "whichever matches" |
| The icon was **removed** and the tab uses a different mechanism | the cosmetic repair no longer applies to that version: skip *that block only*, guarded by a version check, with a log line, and leave the hooks intact |
| The enclosing method no longer has the `Integer.valueOf` → `EnumMap.put` shape | the repair cannot be applied safely: skip it, as above, and record why |

In every branch, the hooks that the eight patches actually need are untouched, the dependency is not
disabled, and no exception is suppressed: the *cosmetic repair* becomes conditional, which is what it
always was.

Two things are explicitly **not** acceptable and will not be done:

- substituting a different drawable to make the lookup succeed;
- catching the `PatchException` so the patch reports success while the icon stays broken.

## 6. Regression tests to add with the fix

None of these exist yet, because each needs the APK:

1. **Missing drawable** — fingerprint evaluated against an APK without the name: the hook patch must
   still complete, and the repair must report that it was skipped.
2. **Replacement drawable** — against 21.45.82: the repair applies, and the resulting APK installs.
3. **Supported versions** — the same patch run against 21.30.216 and 21.43.523: the repair applies as
   before, no regression.
4. **Unsupported version** — a version below the declared minimum is refused with the compatibility
   message, not a stack trace.
5. **Dependency failure** — a dependent patch whose dependency fails is reported as failed, with the
   dependency named; it must never be reported as successful.

Until 2 and 3 pass, 21.45.82 stays **unsupported** for the eight patches, and the compatibility matrix
says so.

## 7. What is needed to proceed

**A legitimately obtained YouTube 21.45.82 APK**, matching the arm64 build the device runs, plus
confirmation of which tree produced the failing run (this repository's import, or upstream dev.7).

With those two things the audit script answers every open question in §3 in one run, and the fix
follows from the decision tree rather than from a guess.
