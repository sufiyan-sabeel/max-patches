# Contributing to MAX Patches

## Before you change a patch

1. Read the patch's upstream history. Most patches were written for a specific app version and then
   maintained; a change that works on the newest version and breaks the older declared ones is a
   regression, not a fix.
2. Check `COMPATIBILITY.md` for the state of the versions you are touching.
3. Reproduce the problem on a real APK before changing a fingerprint.

## What a change must include

- The patch file, with its upstream copyright header intact.
- A fingerprint that matches for the reason you think it does — not by luck on one version.
- A regression test where the logic allows one.
- An entry in `COMPATIBILITY.md` if compatibility changes, with the evidence.
- A commit message that says which app version was tested.

## What is never acceptable

- Inventing resource ids, or hardcoding a numeric id that "seemed to work".
- Catching a patch exception to make a run look successful.
- Marking a version supported without an install test.
- Removing an upstream feature because it was inconvenient.
- Committing a signing key, a token, or anything from `~/.gradle/gradle.properties`.

## Licence

Contributions are GPLv3, and by submitting one you agree it can be distributed under the same terms
as the rest of this repository. Do not paste code from a project whose licence is incompatible.
