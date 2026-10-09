"""Measure stable side-walk head anchors without modifying source pixels."""
from pathlib import Path
import numpy as np
from PIL import Image
ROOT = Path(__file__).resolve().parents[2] / "assets/art"
def index(regions):
    for name in ("sailor", "bunny", "frog", "fox", "bear", "witch", "robot", "flame"):
        key = f"characters/walk/walk-{name}-hd.png"
        entries = regions[key]
        count = len(entries) // 4
        alpha = np.asarray(Image.open(ROOT / key).getchannel("A")) > 32
        for direction in (2, 3):
            frames = entries[direction * count:(direction + 1) * count]
            baseline = [max(v[2] for v in frames), max(v[3] for v in frames)]
            for entry in frames:
                x, y, width, height = entry[:4]
                head = np.argwhere(alpha[y:y + int(height * .35), x:x + width])
                pivot = float(head[:, 1].mean())
                entry[:] = entry[:4] + [entry[4] if len(entry) > 4 else [], pivot, baseline]
    return regions
if __name__ == "__main__":
    import json
    path = ROOT / "atlas-regions.json"
    path.write_text(json.dumps(index(json.loads(path.read_text())), ensure_ascii=False, indent=2) + "\n")
