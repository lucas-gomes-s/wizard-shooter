"""Build a static web beta ZIP from an explicit runtime allowlist."""
from pathlib import Path
import zipfile
import sys

root = Path(__file__).resolve().parents[1]
out = Path(sys.argv[1] if len(sys.argv) > 1 else "dist/wizard-shooter-1.19.0-beta.1.zip")
out.parent.mkdir(parents=True, exist_ok=True)
files = [root / "index.html", root / "docs/WEB_BETA.md"]
for folder, pattern in [("js", "*.js"), ("styles", "*.css"), ("images/beta", "*.svg")]:
    files.extend(sorted((root / folder).glob(pattern)))
assert len(list((root / "images/beta").glob("*.svg"))) == 7
with zipfile.ZipFile(out, "w", compression=zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(files):
        archive.write(path, path.relative_to(root).as_posix())
with zipfile.ZipFile(out) as archive:
    assert archive.testzip() is None
print(f"{out}: {len(files)} files, {out.stat().st_size} bytes")
