#!/usr/bin/env python3
"""Reconstruct M173's owner-approved raster reference as editable SVG layers.

Coordinates follow the left icon in the Notion reference (747 x 731 tile).
The three surfaces are one continuous ribbon: rear, right return, and front.
Only vector artwork is generated here; Apple Icon Composer renders materials.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "ios-native/App/IconComposerAssets/Mobius"
OUT.mkdir(parents=True, exist_ok=True)

LAYERS = [
    ("01-rear-ribbon", "rear", """M 125 493
      C 113 451 136 398 189 375 C 220 362 245 362 270 373
      C 246 369 232 387 228 420 C 222 455 232 492 270 498
      C 308 493 334 464 358 434 L 421 351
      C 502 268 589 221 658 245 C 744 270 786 353 790 446
      C 777 375 741 323 689 319 C 631 310 572 349 488 430
      L 424 508 C 353 583 285 623 222 601
      C 167 584 141 547 125 493 Z"""),
    ("02-right-return", "return", """M 615 334
      C 668 330 700 406 690 463 C 686 490 673 509 650 524
      C 718 529 775 490 790 446 C 781 365 742 323 689 315
      C 662 312 639 318 615 334 Z"""),
    ("03-front-ribbon", "front", """M 125 493
      C 93 419 130 339 203 298 C 270 261 341 277 421 351
      C 447 378 470 411 488 430 C 561 512 608 539 680 521
      C 736 507 775 483 790 446 C 793 525 754 590 687 617
      C 594 655 511 600 424 508 L 358 434
      C 319 393 294 379 270 373 C 221 356 172 376 143 411
      C 121 438 119 470 125 493 Z"""),
]
DEFS = """<defs>
  <linearGradient id="rear" gradientUnits="userSpaceOnUse" x1="130" y1="400" x2="780" y2="400">
    <stop offset="0" stop-color="#0058FF"/><stop offset="0.2" stop-color="#7552FF"/>
    <stop offset="0.4" stop-color="#BF2EF5"/><stop offset="0.68" stop-color="#FF2998"/>
    <stop offset="0.86" stop-color="#FF596C"/><stop offset="1" stop-color="#FFAE32"/>
  </linearGradient>
  <linearGradient id="return" gradientUnits="userSpaceOnUse" x1="653" y1="324" x2="729" y2="518">
    <stop offset="0" stop-color="#DE176A"/><stop offset="0.34" stop-color="#FF3461"/>
    <stop offset="0.72" stop-color="#FF9E28"/><stop offset="1" stop-color="#FFDA38"/>
  </linearGradient>
  <linearGradient id="front" gradientUnits="userSpaceOnUse" x1="177" y1="330" x2="671" y2="601">
    <stop offset="0" stop-color="#00D5EC"/><stop offset="0.18" stop-color="#159FFF"/>
    <stop offset="0.37" stop-color="#9857FF"/><stop offset="0.56" stop-color="#F54BCD"/>
    <stop offset="0.74" stop-color="#FF7A70"/><stop offset="0.9" stop-color="#FFD43B"/>
    <stop offset="1" stop-color="#FFEB45"/>
  </linearGradient>
</defs>"""
START = '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">\n'
TRANSFORM = "matrix(1.3708166 0 0 1.4008208 -105.5528782 -92.4541728)"

def shape(d, fill):
    return f'<path transform="{TRANSFORM}" fill="{fill}" d="{d}"/>\n'

for name, gradient, d in LAYERS:
    (OUT / f"{name}.svg").write_text(START + DEFS + "\n" + shape(d, f"url(#{gradient})") + "</svg>\n")
(OUT / "megrum-mobius.svg").write_text(START + DEFS + "\n" + "".join(shape(d, f"url(#{g})") for _, g, d in LAYERS) + "</svg>\n")
(OUT / "megrum-mobius-mono.svg").write_text(START + "".join(shape(d, "#FFFFFF") for _, _, d in LAYERS) + "</svg>\n")
print(f"Created five editable SVG sources in {OUT}")
