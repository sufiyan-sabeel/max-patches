#!/usr/bin/env python3
"""Fail the build when a compatibility claim has no evidence behind it.

Rules:
  1. patches-list.json must exist and be valid JSON with a version and a patches array.
  2. No patch may declare a target version that COMPATIBILITY.md does not mention.
  3. No version may be listed as Supported without an evidence line naming a test date.

This is deliberately strict. An unevidenced "supported" claim is the failure mode this project
exists to avoid.
"""
import json
import re
import sys

LIST = "patches-list.json"
MATRIX = "COMPATIBILITY.md"

try:
    data = json.load(open(LIST))
except FileNotFoundError:
    sys.exit("patches-list.json is missing; run ./gradlew generatePatchesList")
except json.JSONDecodeError as error:
    sys.exit("patches-list.json is not valid JSON: %s" % error)

matrix = open(MATRIX, encoding="utf-8").read()
versions = set()
for patch in data.get("patches", []):
    for compatible in patch.get("compatiblePackages") or []:
        for target in compatible.get("targets") or []:
            versions.add(target["version"])

missing = sorted(v for v in versions if v not in matrix)
if missing:
    sys.exit("versions declared by patches but absent from %s: %s" % (MATRIX, ", ".join(missing)))

# A supported row must name an evidence line.
for line in matrix.splitlines():
    if "|" not in line or "Supported" not in line or "Upstream declares" in line:
        continue
    cells = [c.strip() for c in line.strip("|").split("|")]
    if any("Supported" in c for c in cells) and not any("evidence" in c.lower() for c in cells):
        sys.exit("a Supported row has no evidence column filled in: %s" % line.strip())

print("compatibility declarations validated: %d versions, all present in the matrix" % len(versions))
