#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = "==3.11.*"
# dependencies = ["leveldb", "lzstring"]
# ///
"""Dump a Chrome extension's chrome.storage data (LevelDB) as JSON.

Copies the LevelDB directory to a temp location so Chrome's lock doesn't
matter — read-only inspection while Chrome stays running.

Usage:
    dump-chrome-extension-storage <extension-id> [--profile Default] [--scope sync|local]

Example (Obsidian Web Clipper):
    dump-chrome-extension-storage cnjifjpddelmedmihgijeibhnjfabmlf

Requires `brew install snappy` (used by the bundled leveldb).
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
import tempfile
from pathlib import Path

import leveldb
import lzstring


def maybe_decompress_chunked_lz(value: object) -> object:
    """Web Clipper (and similar extensions) store large items as a JSON array
    of LZ-string-UTF16-compressed chunks. If `value` looks like such an array,
    decode and JSON-parse the result; otherwise return as-is.
    """
    if not (isinstance(value, list) and value and all(isinstance(x, str) for x in value)):
        return value
    joined = "".join(value)
    # The lzstring PyPI package has a bug: decompressFromUTF16 does
    # `compressed[index] - 32` without ord()-ing first. Passing a list of
    # code points avoids the str/int TypeError.
    codepoints = [ord(c) for c in joined]
    try:
        decompressed = lzstring.LZString().decompressFromUTF16(codepoints)
    except Exception:
        return value
    if not decompressed:
        return value
    try:
        return json.loads(decompressed)
    except json.JSONDecodeError:
        return decompressed


CHROME_ROOT = Path.home() / "Library/Application Support/Google/Chrome"


def storage_dir(extension_id: str, profile: str, scope: str) -> Path:
    folder = {"sync": "Sync Extension Settings", "local": "Local Extension Settings"}[scope]
    return CHROME_ROOT / profile / folder / extension_id


def dump(path: Path) -> dict[str, object]:
    out: dict[str, object] = {}
    db = leveldb.LevelDB(str(path))
    for raw_key, raw_val in db.RangeIter():
        key = bytes(raw_key).decode("utf-8", "replace")
        val_str = bytes(raw_val).decode("utf-8", "replace")
        try:
            parsed = json.loads(val_str)
        except json.JSONDecodeError:
            out[key] = val_str
            continue
        out[key] = maybe_decompress_chunked_lz(parsed)
    del db
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("extension_id", help="Chrome extension ID")
    parser.add_argument("--profile", default="Default", help="Chrome profile (default: Default)")
    parser.add_argument(
        "--scope",
        choices=("sync", "local"),
        default="sync",
        help="Which storage scope to read (default: sync)",
    )
    args = parser.parse_args()

    src = storage_dir(args.extension_id, args.profile, args.scope)
    if not src.is_dir():
        print(f"not found: {src}", file=sys.stderr)
        return 1

    with tempfile.TemporaryDirectory(prefix="chromext-") as tmp:
        copy = Path(tmp) / "db"
        shutil.copytree(src, copy)
        (copy / "LOCK").unlink(missing_ok=True)
        data = dump(copy)

    json.dump(data, sys.stdout, indent=2, ensure_ascii=False, sort_keys=True)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
