#!/usr/bin/env python3
"""Configure a disposable checkout and validate a signed Android App Bundle."""
import argparse
import hashlib
import json
import re
import struct
import subprocess
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

PACKAGE = "com.wizardshooter.game"
ANDROID = "{http://schemas.android.com/apk/res/android}"
MIN_TARGET = 36
MAX_VERSION_CODE = 2_100_000_000

def require(ok, message):
    if not ok:
        raise ValueError(message)

def version_args(code, name):
    require(1 <= code <= MAX_VERSION_CODE, "Invalid Play versionCode")
    require(re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+(?:-[A-Za-z0-9.]+)?", name), "Invalid version name")

def configure(root, code, name):
    version_args(code, name)
    path = root / "export_presets.cfg"
    text = path.read_text()
    marker = "[preset.1.options]\n"
    require(text.count(marker) == 1, "Release preset missing")
    head, tail = text.split(marker)
    for key, value in (("version/code", str(code)), ("version/name", json.dumps(name))):
        tail, n = re.subn(r"(?m)^" + re.escape(key) + r"=.*$", key + "=" + value, tail)
        require(n == 1, "Missing or duplicate version field")
    path.write_text(head + marker + tail)
    project = root / "project.godot"
    content, n = re.subn(r'(?m)^config/version=.*$', 'config/version=' + json.dumps(name), project.read_text())
    require(n == 1, "Missing project version")
    project.write_text(content)

def check_elf(data, label):
    require(data[:4] == b"\x7fELF" and data[4:6] == b"\x02\x01", label + ": expected little-endian ELF64")
    require(len(data) >= 64, label + ": truncated ELF")
    require(struct.unpack_from("<H", data, 18)[0] == 183, label + ": expected AArch64")
    offset = struct.unpack_from("<Q", data, 32)[0]
    size, count = struct.unpack_from("<HH", data, 54)
    require(size >= 56 and count > 0 and offset + size * count <= len(data), label + ": malformed program headers")
    loads = 0
    for index in range(count):
        kind, _, pos, addr, _, _, _, align = struct.unpack_from("<IIQQQQQQ", data, offset + index * size)
        if kind == 1:
            loads += 1
            require(align >= 16384 and align & (align - 1) == 0 and pos % 16384 == addr % 16384, label + ": non-16KB PT_LOAD")
    require(loads > 0, label + ": no load segments")

def bundletool(jar, *args):
    return subprocess.check_output(["java", "-jar", str(jar), *args], text=True)

def validate(bundle, jar, code, name, output):
    version_args(code, name)
    bundletool(jar, "validate", "--bundle=" + str(bundle))
    xml = bundletool(jar, "dump", "manifest", "--bundle=" + str(bundle), "--module=base")
    manifest = ET.fromstring(xml)
    require(manifest.get("package") == PACKAGE, "Unexpected package ID")
    require(manifest.get(ANDROID+"versionCode") == str(code), "Unexpected version code")
    require(manifest.get(ANDROID+"versionName") == name, "Unexpected version name")
    sdk = manifest.find("uses-sdk")
    require(sdk is not None and int(sdk.get(ANDROID+"targetSdkVersion", "0")) >= MIN_TARGET, "Target SDK too low")
    require(int(sdk.get(ANDROID+"minSdkVersion", "0")) == 24, "Unexpected min SDK")
    app = manifest.find("application")
    require(app is not None and app.get(ANDROID+"debuggable", "false") == "false", "Debuggable bundle")
    permissions = sorted({el.get(ANDROID+"name", "") for el in manifest if el.tag.startswith("uses-permission")})
    allow = {"android.permission.VIBRATE", "android.permission.WAKE_LOCK", PACKAGE+".DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"}
    require(set(permissions) <= allow, "Unexpected permissions: " + str(permissions))
    config = bundletool(jar, "dump", "config", "--bundle=" + str(bundle))
    require("PAGE_ALIGNMENT_16K" in config, "Bundle does not request 16KB alignment")
    with zipfile.ZipFile(bundle) as archive:
        libs = [p for p in archive.namelist() if p.endswith(".so")]
        require(libs and all(p.startswith("base/lib/arm64-v8a/") for p in libs), "Unexpected native ABI/module")
        for lib in libs:
            check_elf(archive.read(lib), lib)
        require(any(p.startswith("base/assets/") and (p.endswith(".pck") or p.endswith("project.binary")) for p in archive.namelist()), "Missing Godot assets")
    report = {"package":PACKAGE,"version_code":code,"version_name":name,"target_sdk":int(sdk.get(ANDROID+"targetSdkVersion")),
              "min_sdk":24,"debuggable":False,"permissions":permissions,"native_libraries":libs,
              "page_alignment":"16KB","sha256":hashlib.sha256(bundle.read_bytes()).hexdigest()}
    output.write_text(json.dumps(report, indent=2)+"\n")

def main():
    parser = argparse.ArgumentParser()
    subs = parser.add_subparsers(dest="command", required=True)
    p = subs.add_parser("configure")
    p.add_argument("--root", type=Path, required=True)
    p = subs.add_parser("validate")
    p.add_argument("--bundle", type=Path, required=True)
    p.add_argument("--bundletool", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    for p in subs.choices.values():
        p.add_argument("--code", type=int, required=True)
        p.add_argument("--name", required=True)
    a = parser.parse_args()
    if a.command == "configure":
        configure(a.root, a.code, a.name)
    else:
        validate(a.bundle, a.bundletool, a.code, a.name, a.output)

if __name__ == "__main__":
    main()
