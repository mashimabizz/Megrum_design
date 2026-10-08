#!/usr/bin/env python3
"""Export actual Apple Icon Composer renditions and a labeled size review sheet."""
import json
import subprocess
import tempfile
import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "ios-native/App/IconComposerAssets/Mobius/Previews"
OUT.mkdir(parents=True, exist_ok=True)
ICTOOL = Path("/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool")
MODES = ["Default", "Dark", "TintedLight", "TintedDark", "ClearLight", "ClearDark"]
SIZES = [1024, 180, 120, 87, 60, 40, 29]

def save_png(image, destination):
    # Atomic replacement avoids in-place opens of cloud-provider placeholder files.
    temporary = destination.with_name(destination.stem + ".m173-new.png")
    image.save(temporary)
    os.replace(temporary, destination)

for generation in [27, 26]:
    for mode in MODES:
        for size in SIZES if generation == 27 else [1024]:
            name = f"iOS{generation}-{mode}-{size}.png"
            args = [str(ICTOOL), str(ROOT / "MegrumMobius.icon"), "--export-image",
                    "--output-file", str(OUT / name), "--platform", "iOS",
                    "--rendition", mode, "--width", str(size), "--height", str(size),
                    "--scale", "1", "--design-generation", str(generation)]
            if mode.startswith("Tinted"):
                args += ["--tint-color", "0.58", "--tint-strength", "0.8"]
            result = subprocess.run(args, capture_output=True, text=True, timeout=60)
            if result.returncode:
                raise RuntimeError(result.stderr or result.stdout)
            with Image.open(OUT / name) as im:
                assert im.size == (size, size), (name, im.size)
            print(name)

font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 20)
small = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 16)
sheet = Image.new("RGB", (1320, 1390), "#ECEFF4")
draw = ImageDraw.Draw(sheet)
draw.text((30, 20), "Megrum M173 | Apple Icon Composer 27 / ictool | iOS 27", font=font, fill="#202531")
draw.text((30, 52), "6 OS renditions. Clear = monochrome OS export; live wallpaper refraction requires device review.", font=small, fill="#424B5A")
for row, mode in enumerate(MODES):
    top = 110 + row * 208
    draw.text((25, top), mode, font=font, fill="#202531")
    # First column is a 1024 export reduced for display; others are exact pixels.
    for col, size in enumerate(SIZES):
        x = 200 + col * 155
        tile = Image.new("RGBA", (145, 180), "#F8FAFF" if "Dark" not in mode else "#171C27")
        im = Image.open(OUT / f"iOS27-{mode}-{size}.png").convert("RGBA")
        if size > 120:
            im = im.resize((120, 120), Image.Resampling.LANCZOS)
        tile.alpha_composite(im, ((145 - im.width) // 2, 20 + (120 - im.height) // 2))
        sheet.paste(tile.convert("RGB"), (x, top - 8))
        label = f"{size}px" + (" scaled" if size > 120 else " 1:1")
        draw.text((x + 5, top + 149), label, font=small, fill="#B9C4D7" if "Dark" in mode else "#424B5A")
sheet.save(OUT / "review-sheet.png")

overview = Image.new("RGB", (1440, 920), "#F0F2F6")
d = ImageDraw.Draw(overview)
d.text((30, 20), "Megrum | owner-approved asymmetrical Mobius | Apple-rendered previews", font=font, fill="#202531")
for index, mode in enumerate(MODES):
    x, y = 30 + (index % 3) * 470, 80 + (index // 3) * 420
    im = Image.open(OUT / f"iOS27-{mode}-1024.png").convert("RGBA").resize((360, 360), Image.Resampling.LANCZOS)
    bg = Image.new("RGBA", (360, 360), "#E7EBF2" if "Dark" not in mode else "#171C27")
    bg.alpha_composite(im)
    overview.paste(bg.convert("RGB"), (x + 40, y))
    d.text((x + 40, y + 370), mode, font=font, fill="#202531")
overview.save(OUT / "overview.png")
(OUT / "export-metadata.json").write_text(json.dumps({
    "source": "MegrumMobius.icon", "tool": str(ICTOOL),
    "version": "27.0 (129)", "platform": "iOS", "design_generations": [26, 27],
    "renditions": MODES, "sizes_iOS27": SIZES, "sizes_iOS26": [1024],
    "tint_color": 0.58, "tint_strength": 0.8,
    "clear_limitation": "OS shader export; live wallpaper and motion not tested by still exports",
}, indent=2) + "\n")
print("48 actual Apple exports and two review sheets verified")

# Existing Swift views keep their asset names and layout. Replace only artwork.
catalog = ROOT / "ios-native/App/Assets.xcassets"
with tempfile.TemporaryDirectory(prefix="megrum-m173-") as temporary:
    sources = {}
    for name in ["megrum-mobius", "megrum-mobius-mono"]:
        target = Path(temporary) / f"{name}.png"
        subprocess.run(["sips", "-s", "format", "png", str(OUT.parent / f"{name}.svg"),
                        "--out", str(target)], check=True, capture_output=True)
        sources[name] = Image.open(target).convert("RGBA")
    flat = Image.new("RGBA", (1024, 1024), "#F8FAFF")
    flat.alpha_composite(sources["megrum-mobius"])
    save_png(flat.convert("RGB"), catalog / "AppIcon.appiconset/App-Icon-1024x1024@1x.png")
    brand_images = []
    for scale in [1, 2, 3]:
        suffix = "" if scale == 1 else f"@{scale}x"
        for name, source, size in [("LaunchIcon", "megrum-mobius", 120),
                                   ("TabMeguriIcon", "megrum-mobius-mono", 25)]:
            save_png(sources[source].resize((size*scale, size*scale), Image.Resampling.LANCZOS),
                     catalog / f"{name}.imageset/{name}{suffix}.png")
        for mode in ["Default", "Dark"]:
            name = f"MegrumBrandIcon{suffix}" + ("-dark" if mode == "Dark" else "") + ".png"
            save_png(Image.open(OUT / f"iOS27-{mode}-1024.png").resize(
                (120*scale, 120*scale), Image.Resampling.LANCZOS),
                catalog / "MegrumBrandIcon.imageset" / name)
            entry = {"filename": name, "idiom": "universal", "scale": f"{scale}x"}
            if mode == "Dark":
                entry["appearances"] = [{"appearance": "luminosity", "value": "dark"}]
            brand_images.append(entry)
    (catalog / "MegrumBrandIcon.imageset/Contents.json").write_text(json.dumps(
        {"images": brand_images, "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
print("Fallback, launch, tab, and Light/Dark brand asset references updated")
