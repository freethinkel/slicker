#!/usr/bin/env python3
"""Print the sketchybar height for a given CGDirectDisplayID.
40 for built-in (notch), 30 for external.
Usage: display_bar_height.py <CGDirectDisplayID>
"""
import ctypes, ctypes.util, sys

cg = ctypes.CDLL(ctypes.util.find_library("CoreGraphics"))
cg.CGDisplayIsBuiltin.argtypes = [ctypes.c_uint32]
cg.CGDisplayIsBuiltin.restype = ctypes.c_bool

display_id = int(sys.argv[1])
print(40 if cg.CGDisplayIsBuiltin(display_id) else 30)
