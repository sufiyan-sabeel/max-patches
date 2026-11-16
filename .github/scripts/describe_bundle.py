#!/usr/bin/env python3
"""Describe a patch bundle without publishing anything.

Prints the SHA-256 of each .mpp and whether its zip comment carries a signature, plus the public key
it names. That key is public by design — it is what the manager checks a bundle against — so printing
it is safe; the private key is never touched.
"""
import glob
import hashlib
import zipfile

paths = sorted(glob.glob("patches/build/libs/*.mpp"))
if not paths:
    raise SystemExit("no .mpp produced in patches/build/libs/")

for path in paths:
    digest = hashlib.sha256(open(path, "rb").read()).hexdigest()
    print("%s" % path)
    print("  sha256: %s" % digest)
    comment = zipfile.ZipFile(path).comment.decode("utf-8", "replace").strip()
    if comment.startswith("MorpheSig1"):
        parts = comment.split()
        key = parts[1] if len(parts) > 1 else "?"
        print("  signed: yes, public key %s…" % key[:12])
    elif comment:
        print("  signed: no, comment reads %r" % comment[:40])
    else:
        print("  signed: no (no archive comment)")
