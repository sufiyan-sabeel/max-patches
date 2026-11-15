# Writing a patch for MAX Patches

This is the short version. The engine's own guides (`engine/docs/1_patcher_intro.md` and the rest)
explain the API in depth and are inherited unchanged.

## Shape of a patch

```kotlin
val examplePatch = patch(
    name = "Example",
    description = "What the user sees it do."
) {
    dependsOn(sharedExtensionPatch, settingsPatch)   // runs after these, fails if they fail
    compatibleWith(COMPATIBILITY_YOUTUBE)            // which app and versions

    execute {
        // Bytecode edits, resource edits, or wiring to an extension class
    }
}
```

## Fingerprints

A fingerprint is how a patch finds code in a target APK after obfuscation. Rules learned the hard
way, all of them visible in the 21.45.82 defect:

- Prefer structure (opcode order, method calls, class casts) over names. Names get renamed; structure
  survives longer.
- If you must use a resource name, decide deliberately whether it is fatal when missing.
  `resourceLiteral(type, name, exceptionIfResourceNotFound = false)` returns null instead of throwing
  — but a fingerprint that quietly stops matching is its own bug, so pair it with a version check and
  a second fingerprint, not with silence.
- Never assume a fingerprint that matches on one version matches on the next. Version-gate it.

## Extensions

Extension code is Java, injected into the app. A patch declares the extension class by descriptor
(`Lapp/morphe/extension/...;`) and the build injects it. If the class name changes, every patch that
names it breaks — so extension class names are part of the compatibility surface.

## Testing

- Unit-test what can be tested without an APK: option parsing, resource lookups, helper logic.
- Everything else needs a real APK. Record what you tested in `COMPATIBILITY.md`.
