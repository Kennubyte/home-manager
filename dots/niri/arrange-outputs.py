#!/usr/bin/env python3
"""Keep the external (HDMI) monitor above the laptop panel in niri.

Everything is computed from whatever is actually connected, so any monitor
works at any resolution:

  * external (non-eDP) outputs are placed in a row above the internal panel,
    centered on each other;
  * each output gets its native resolution (the EDID preferred mode) at the
    highest refresh rate available for that resolution. This is applied
    whenever niri itself is sitting at the plain EDID preferred mode, which is
    what happens on a fresh hotplug or after a config reload - so a manually
    chosen mode is left alone.

Usage:
    arrange-outputs.py          arrange once and exit
    arrange-outputs.py --watch  keep watching and fix things up (runs at startup)
"""

import fcntl
import json
import subprocess
import sys
import time

POLL_INTERVAL = 1.0
INTERNAL_PREFIX = "eDP"
LOG = "/tmp/niri-arrange-outputs.log"
LOCK = "/tmp/niri-arrange-outputs.lock"


def log(msg):
    line = time.strftime("[%Y-%m-%d %H:%M:%S] ") + msg
    print(line, flush=True)
    try:
        with open(LOG, "a") as fh:
            fh.write(line + "\n")
    except OSError:
        pass


def query_outputs():
    """Return the outputs JSON, or None if niri could not be reached."""
    try:
        proc = subprocess.run(
            ["niri", "msg", "-j", "outputs"],
            capture_output=True, text=True, timeout=10,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    if proc.returncode != 0:
        return None
    try:
        return json.loads(proc.stdout)
    except ValueError:
        return None


def output_cmd(name, *args):
    try:
        proc = subprocess.run(
            ["niri", "msg", "output", name, *args],
            capture_output=True, text=True, timeout=10,
        )
    except (OSError, subprocess.TimeoutExpired) as err:
        log(f"{name}: command failed: {err}")
        return False
    if proc.returncode != 0:
        log(f"{name}: niri msg output {name} {' '.join(args)}: "
            f"{(proc.stderr or proc.stdout).strip()}")
        return False
    return True


def best_mode_index(out):
    """Index of native resolution @ highest refresh, and of the preferred mode."""
    modes = out.get("modes") or []
    if not modes:
        return None, None
    pref = next((i for i, m in enumerate(modes) if m.get("is_preferred")), 0)
    pw, ph = modes[pref]["width"], modes[pref]["height"]
    best = pref
    for i, mode in enumerate(modes):
        if (mode["width"], mode["height"]) == (pw, ph):
            if mode["refresh_rate"] > modes[best]["refresh_rate"]:
                best = i
    return best, pref


def mode_string(mode):
    return "{}x{}@{:.3f}".format(
        mode["width"], mode["height"], mode["refresh_rate"] / 1000
    )


def desired_positions(enabled):
    """Map of output name -> (x, y): externals on top, internals below."""
    rows = [
        [o for o in enabled if not o["name"].startswith(INTERNAL_PREFIX)],
        [o for o in enabled if o["name"].startswith(INTERNAL_PREFIX)],
    ]
    top_w = sum(o["logical"]["width"] for o in rows[0])
    bottom_w = sum(o["logical"]["width"] for o in rows[1])
    # The bottom (laptop panel) row is the reference; the top (external) row is
    # shifted so both rows share the same horizontal center. Offsetting both
    # rows would cancel out and leave them misaligned.
    starts = [round((bottom_w - top_w) / 2), 0]

    pos = {}
    y = 0
    for row, x in zip(rows, starts):
        for out in row:
            pos[out["name"]] = (x, y)
            x += out["logical"]["width"]
        if row:
            y = max(o["logical"]["height"] for o in row)

    if pos:
        min_x = min(px for px, _ in pos.values())
        if min_x != 0:
            pos = {name: (px - min_x, py) for name, (px, py) in pos.items()}
    return pos


def fix_positions():
    """Move outputs into place. Returns True while something still needs moving.

    niri re-places any output still on "auto" position whenever another output
    is positioned, so this is retried until the layout settles.
    """
    outputs = query_outputs()
    if outputs is None:
        return False

    enabled = [o for o in outputs.values() if o.get("logical")]
    pending = False
    for name, (x, y) in desired_positions(enabled).items():
        logical = outputs[name]["logical"]
        if (logical["x"], logical["y"]) != (x, y):
            log(f"{name}: position -> {x},{y} "
                f"(was {logical['x']},{logical['y']})")
            output_cmd(name, "position", "set", str(x), str(y))
            pending = True
    return pending


def apply_modes(outputs):
    for out in outputs.values():
        if not out.get("logical"):
            continue
        best, pref = best_mode_index(out)
        if best is None:
            continue
        current = out.get("current_mode")
        # Only step in while niri is at the EDID default mode: that means it
        # just picked the mode itself for a newly connected (or re-detected)
        # monitor, and we can upgrade it to the best one.
        if best != current and current == pref:
            mode = out["modes"][best]
            log(f"{out['name']}: mode -> {mode_string(mode)} "
                f"(native resolution @ highest refresh)")
            output_cmd(out["name"], "mode", mode_string(mode))


def arrange():
    outputs = query_outputs()
    if outputs is None:
        return
    apply_modes(outputs)
    for _ in range(3):
        if not fix_positions():
            return
        time.sleep(0.2)


def main():
    watch = "--watch" in sys.argv[1:]

    if not watch:
        outputs = query_outputs()
        if outputs is None:
            log("could not query outputs")
            return 1
        arrange()
        return 0

    lock = open(LOCK, "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        # Another watcher is already running.
        return 0

    log("watching for output changes")
    while True:
        if query_outputs() is None:
            time.sleep(2)
            continue
        try:
            arrange()
        except Exception as err:  # never die on an unexpected hiccup
            log(f"error: {err}")
        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    sys.exit(main())
