#!/usr/bin/env python3
# Patch a Mach-O 64 dylib's cpusubtype field (offset 8) to arm64e (0x2).
#
# lld (Linux host) writes cpusubtype=0 (arm64) into the output Mach-O header
# even when invoked with -target arm64e, even though the object files it
# links are arm64e (PAC instructions present). The resulting dylib is rejected
# by dlopen inside an arm64e process (A12+ devices on Dopamine) — the load
# fails silently and the tweak's constructor never runs, so there is no menu
# bar and not even a log file. Patching the header subtype to 0x2 makes the
# kernel/dyld treat the dylib as arm64e, which matches the actual instructions.
import struct, sys

if len(sys.argv) != 2:
    print("usage: patch_arch.py <macho>", file=sys.stderr); sys.exit(2)
path = sys.argv[1]
d = bytearray(open(path, "rb").read())
if d[:4] != b"\xcf\xfa\xed\xfe":
    print("patch_arch: not a Mach-O 64 little-endian file; skipping", file=sys.stderr)
    sys.exit(0)
cpu, = struct.unpack_from("<I", d, 4)
sub, = struct.unpack_from("<I", d, 8)
if cpu != 0x100000C:
    print("patch_arch: not arm64/arm64e (cputype=0x%x); skipping" % cpu, file=sys.stderr)
    sys.exit(0)
if sub == 0x2:
    print("patch_arch: already arm64e; no change")
    sys.exit(0)
struct.pack_into("<I", d, 8, 0x2)
open(path, "wb").write(d)
print("patch_arch: cpusubtype 0x%x -> 0x2 (arm64e)" % sub)
