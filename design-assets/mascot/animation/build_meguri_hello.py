"""Split the scarf tails from the Creator vector trace and build the final Lottie."""

from __future__ import annotations

import copy
import json
import math
from pathlib import Path


HERE = Path(__file__).parent
SOURCE = HERE / "meguri-hello-creator.json"
OUTPUT = HERE / "meguri-hello-v1.json"
TAIL_GROUPS = {"Group 4", "Group 5", "Group 6", "Group 10", "Group 12"}
BASE_ANCHOR = (627.0000186082794, 627.0000186082794)
TAIL_ANCHOR = (968.0, 756.0)
EASE = {"o": {"x": 0.4, "y": 0}, "i": {"x": 0.2, "y": 1}}


def animated(values: list[tuple[int, list[float]]]) -> dict:
    keyframes = [{"t": frame, "s": value, **EASE} for frame, value in values]
    keyframes[-1] = {"t": values[-1][0], "s": values[-1][1]}
    return {"a": 1, "k": keyframes}


def build() -> None:
    data = json.loads(SOURCE.read_text())
    blink, body, raster = data["layers"]
    assert raster["hd"] is True and raster["ty"] == 2
    assert body["ty"] == 4 and blink["ty"] == 0

    tail = copy.deepcopy(body)
    tail["nm"] = "Scarf tails — independent follow-through"
    tail["ind"] = 2
    body["nm"] = "Meguri — face, body and wrapped scarf"
    body["ind"] = 3
    tail["shapes"] = [shape for shape in body["shapes"] if shape["nm"] in TAIL_GROUPS]
    body["shapes"] = [shape for shape in body["shapes"] if shape["nm"] not in TAIL_GROUPS]
    assert {shape["nm"] for shape in tail["shapes"]} == TAIL_GROUPS

    # Keep the scarf junction on the same moving character, while rotating only
    # its two free ends around the knot near the right side of the neck.
    positions = [(0, 256, 256), (8, 256, 260), (20, 256, 224),
                 (32, 256, 254), (39, 256, 258), (48, 256, 256),
                 (90, 256, 256)]
    scales = [(0, 41, 41), (8, 42, 39.5), (20, 40, 42),
              (32, 43, 39), (39, 40.5, 41.5), (48, 41, 41),
              (90, 41, 41)]
    body_rotation = {0: 0, 8: -1, 20: -2.5, 32: 1.5, 39: 0.9, 48: 0, 90: 0}
    tail_rotation = {0: 0, 8: -3, 20: 5, 32: -6, 39: 5, 48: -2, 90: 0}
    pivot_delta = (TAIL_ANCHOR[0] - BASE_ANCHOR[0],
                   TAIL_ANCHOR[1] - BASE_ANCHOR[1])
    tail_positions = []
    assert len(positions) == len(scales)
    for (frame, x, y), (_, sx, sy) in zip(positions, scales):
        angle = math.radians(body_rotation[frame])
        dx = sx / 100 * pivot_delta[0]
        dy = sy / 100 * pivot_delta[1]
        tail_positions.append((frame, [
            round(x + dx * math.cos(angle) - dy * math.sin(angle), 3),
            round(y + dx * math.sin(angle) + dy * math.cos(angle), 3),
        ]))
    tail["ks"]["a"] = {"a": 0, "k": list(TAIL_ANCHOR)}
    tail["ks"]["p"] = animated(tail_positions)
    tail["ks"]["s"] = animated([
        (frame, [sx, sy]) for frame, sx, sy in scales
    ])
    tail["ks"]["r"] = animated([
        (frame, [body_rotation[frame] + tail_rotation[frame]])
        for frame in body_rotation
    ])

    # The PNG is a reference in Creator, but invisible. Deliver a compact,
    # fully vector runtime file with only the precomp used for the blink.
    data["layers"] = [blink, tail, body]
    used_assets = {blink["refId"]}
    data["assets"] = [asset for asset in data["assets"] if asset["id"] in used_assets]
    data["nm"] = "Megrum mascot Meguri — hello loop v1"
    OUTPUT.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")))
    print(f"{OUTPUT.name}: {OUTPUT.stat().st_size} bytes; 3 vector layers; 90 frames")


if __name__ == "__main__":
    build()
