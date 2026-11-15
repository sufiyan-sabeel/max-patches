# MAX Patches build dependencies

## The one registry dependency

`settings.gradle.kts` applies `id("app.morphe.patches") version "2.1.0"`, the patch Gradle plugin.
It is published only to `https://maven.pkg.github.com/MorpheApp/registry`, which authenticates every
request, so building this repository needs a personal access token with `read:packages`.

Set it once, as the `GHP_PACKAGES_TOKEN` secret in this repository, and locally in
`~/.gradle/gradle.properties`:

```properties
gpr.user=your-github-username
gpr.key=ghp_your_token
```

A `401` on `app.morphe.patches` means the token is missing or expired.

## Why this one is still here

MAX Patcher removed its registry dependency by building the engine and its libraries from source
(see `max-patcher/docs/DEPENDENCIES.md`). The same treatment is needed for this plugin: it lives in
the upstream `morphe-patches-library` repository, which would have to be vendored and its plugin
build rewritten. That is tracked work, not done yet.

## Everything else

Kotlin, the Android build tools and every library come from Maven Central and Google's Maven
repository, pinned in `gradle/libs.versions.toml`.
