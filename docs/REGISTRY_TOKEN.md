# The registry token, and why this repository needs one

## Short answer

Building MAX Patches needs **one** secret, `GHP_PACKAGES_TOKEN`, a GitHub personal access token with
the single scope `read:packages`. It is used by exactly one step in one workflow, to resolve one
artifact: the `app.morphe.patches` Gradle plugin.

## Exactly where it is used

| Place | What it does |
|---|---|
| `settings.gradle.kts`, `pluginManagement` | declares `maven.pkg.github.com/MorpheApp/registry` as a plugin repository and reads `gpr.user` / `gpr.key` |
| `.github/workflows/validate.yml`, step *Gradle registry credentials* | writes `gpr.user` and `gpr.key` into `~/.gradle/gradle.properties` before Gradle runs |
| `.github/workflows/release.yml`, same step | identical, for the release job |

Nothing else needs it. Maven Central, Google's Maven repository and the plugin portal are public and
already listed ahead of the registry in `pluginManagement`.

## Minimum permission

| Token kind | Setting | Works? |
|---|---|---|
| Classic PAT | scope **`read:packages`** only | **Yes** — this is the one to use |
| Fine-grained PAT | *Packages: Read* | Only if the package owner grants this repository access; MorpheApp's packages belong to another account, so this is unreliable |
| `GITHUB_TOKEN` | automatic | **No** — it only reads packages owned by the same account |

Do not add `repo`, `workflow`, `admin:*` or anything else. The build reads; it never publishes.

## Why it cannot be removed by changing a repository

Checked directly, in this order:

| Location | Result |
|---|---|
| `maven.pkg.github.com/MorpheApp/registry` (plugin marker POM) | **401** — authentication required |
| `repo1.maven.org` (Maven Central) | **404** — not published there |
| `plugins.gradle.org` (plugin portal) | **303 redirect to Maven Central**, which then returns **404** |

So the plugin exists only on the Morphe GitHub Packages registry. There is no public mirror to point at.

## Setting it up

1. GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)** →
   **Generate new token (classic)**.
2. Name: `max-patches-read-packages`. Expiry: whatever you will renew.
3. Tick **one** scope: `read:packages`.
4. Generate, copy once.
5. In **this** repository: Settings → Secrets and variables → Actions → New repository secret, name
   `GHP_PACKAGES_TOKEN`, paste, save.

Locally, the same two lines in `~/.gradle/gradle.properties` (never in the repository):

```properties
gpr.user=your-github-username
gpr.key=ghp_your_token
```

The workflows write those values from the secret at run time and never echo them. Nothing prints the
token, and a failure says `401`, not the value.

## What happens without it

`validate.yml` fails at *Build and test* with:

```
Could not resolve app.morphe.patches:app.morphe.patches.gradle.plugin:2.1.0
   > Received status code 401 from server: Unauthorized
```

That is the expected failure, not a bug in the patch collection. **No compilation has been claimed
until this secret exists and a run goes green.**

## The way to remove the dependency properly

Fork or reimplement the `app.morphe.patches` Gradle plugin and vendor it, the way MAX Patcher already
vendors the engine, ARSCLib and smali. Then this repository, like the app, needs no registry and no
token at all.

It is not a small job: the plugin owns the whole patch build — compiling patches against the engine
API, building the extension modules, packaging and signing the `.mpp` bundle, and generating
`patches-list.json`. Its source is not in `morphe-patches` or `morphe-patches-library` (that repository
is 78 files and contains no Gradle plugin), so vendoring means obtaining and maintaining a
plugin the upstream project does not publish openly.

Until that is done, the token is the honest answer, and the secret is the smallest possible one.
