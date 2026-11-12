"""Build a reproducible installation ZIP with one OreGlow directory."""
import hashlib
import re
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def build():
    addon = ROOT / "OreGlow"
    toc = (addon / "OreGlow.toc").read_text()
    version = re.search(r"^## Version: (\d+\.\d+\.\d+)$", toc, re.M)[1]
    if f'O.version = "{version}"' not in (addon / "Core.lua").read_text():
        raise ValueError("TOC and Lua versions differ")
    for line in toc.splitlines():
        if line and not line.startswith("#") and not (addon / line).is_file():
            raise ValueError(f"Missing TOC file: {line}")
    files = {f"OreGlow/{p.name}": p for p in sorted(addon.iterdir()) if p.is_file()}
    for name in ("README.md", "LICENSE", "CHANGELOG.md"):
        files[f"OreGlow/{name}"] = ROOT / name
    for name in ("API.md", "TESTING.md"):
        files[f"OreGlow/docs/{name}"] = ROOT / "docs" / name
    dist = ROOT / "dist"
    dist.mkdir(exist_ok=True)
    target = dist / f"OreGlow-{version}.zip"
    with zipfile.ZipFile(target, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, source in sorted(files.items()):
            if source.is_symlink():
                raise ValueError(f"Symlink not permitted: {source}")
            info = zipfile.ZipInfo(name, date_time=(2026, 11, 12, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, source.read_bytes())
    with zipfile.ZipFile(target) as archive:
        assert archive.testzip() is None
        assert {name.split("/")[0] for name in archive.namelist()} == {"OreGlow"}
        assert "OreGlow/OreGlow.toc" in archive.namelist()
        assert all(not name.startswith("OreGlow/tests/") for name in archive.namelist())
    checksum = hashlib.sha256(target.read_bytes()).hexdigest()
    (dist / "SHA256SUMS.txt").write_text(f"{checksum}  {target.name}\n")
    print(f"{target.name}: {len(files)} files, {target.stat().st_size:,} bytes")
    return target


if __name__ == "__main__":
    build()
