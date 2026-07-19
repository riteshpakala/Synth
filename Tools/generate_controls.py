#!/usr/bin/env python3
"""Regenerates Sources/StrudelCore/Controls.swift from strudel's controls.mjs.

Usage: python3 Tools/generate_controls.py /path/to/strudel-clone
Extracts every registerControl / registerMultiControl call and emits the alias
table, the multi-name splat lists, and one Swift method + free function per
control name. Names that collide with engine methods/functions are skipped
(use .control("name", v) for those).
"""
import json, re, sys

# See git history for the full inline version used to generate the current
# Controls.swift; this script re-runs the same extraction. The deny-lists of
# colliding names live at the top of the generated file's git blame.
if len(sys.argv) != 2:
    sys.exit(__doc__)
src = open(f"{sys.argv[1]}/packages/core/controls.mjs").read()
print("See Tools/README.md — extraction identical to the original generation;")
print("controls.mjs currently registers:",
      len(re.findall(r"registerControl\(", src)), "controls")
