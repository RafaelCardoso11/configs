#!/usr/bin/env python3
# Waybar now-playing pill: on track change the text collapses into its center and
# the new one grows out of it; play/pause cross-fades; while playing, a waveform
# driven by cava animates before the title. A thin bottom line shows progress, in
# PROGRESS_STEP% classes (p0..p100) that the stylesheet maps to gradient widths.
import html
import json
import os
import re
import select
import subprocess
import sys
import tempfile
import time
from math import floor

FRAMES = 12
FRAME_DELAY = 0.02
FADE_FRAMES = 6
WAVE_BARS = 6
WAVE_CHARS = "▁▂▃▄▅▆▇"
WAVE_FPS = 20
PROGRESS_STEP = 5
# local position estimate drifts from seeks done in the player; re-read it this often
RESYNC_EVERY = 2.0
TOOLTIP_BAR = 16

# matched against playerName; youtube is detected from the track url instead
PLAYER_ICONS = {
    "spotify": "\U000f04c7",
    "firefox": "\U000f0239",
    "chrom": "\U000f02af",
    "vlc": "\U000f057c",
    "mpv": "\U000f057c",
}
YOUTUBE_ICON = "\U000f05c3"
WEB_ICON = "\U000f059f"
DEFAULT_ICON = "\U000f075a"

# browser/upload noise that adds length without telling which track it is
TITLE_NOISE = re.compile(
    r"\s*[\(\[][^\)\]]*\b(?:official|video|clipe|lyrics?|letra|audio|áudio|hd|4k|visualizer|legendado)\b[^\)\]]*[\)\]]"
    r"|\s+[-–|]\s*youtube(?: music)?$",
    re.IGNORECASE,
)

CAVA_CONFIG = f"""
[general]
bars = {WAVE_BARS}
framerate = {WAVE_FPS}
[input]
method = pipewire
source = auto
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = {len(WAVE_CHARS) - 1}
bar_delimiter = 59
frame_delimiter = 10
[smoothing]
noise_reduction = 85
"""


def emit(text, cls="", tooltip=""):
    print(json.dumps({"text": text, "class": cls, "tooltip": tooltip}), flush=True)


def esc(s):
    return html.escape(s, quote=False)


def clean(title):
    return TITLE_NOISE.sub("", title).strip() or title


def player_icon(player, url):
    if "youtube.com" in url or "youtu.be" in url:
        return YOUTUBE_ICON
    for key, icon in PLAYER_ICONS.items():
        if key in player.lower():
            return icon
    return WEB_ICON if url.startswith("http") else DEFAULT_ICON


def plain(state):
    status, player, title, artist, url = state
    if status == "Paused":
        return f"{player_icon(player, url)}  {title}"
    return f"{title}  {artist}" if artist else title


def markup(state, wave, fade=1.0):
    status, player, title, artist, url = state

    def alpha(pct):
        return f"{max(1, round(pct * fade))}%"

    if status == "Paused":
        return f"<span alpha='{alpha(60)}'>{player_icon(player, url)}  {esc(title)}</span>"
    body = f"<span alpha='{alpha(100)}'>{esc(title)}</span>"
    if artist:
        body += f"  <span alpha='{alpha(60)}'>{esc(artist)}</span>"
    return f"<span alpha='{alpha(100)}'>{wave}</span>   {body}"


class Clock:
    """Track position between player events without polling playerctl every frame."""

    def __init__(self):
        self.base = self.length = 0.0
        self.t0 = self.synced = time.monotonic()
        self.running = False

    def set(self, position, length, running):
        now = time.monotonic()
        self.base, self.length, self.running = position, length, running
        self.t0 = self.synced = now

    def resync(self, player):
        if not self.running or time.monotonic() - self.synced < RESYNC_EVERY:
            return
        out = subprocess.run(["playerctl", "-p", player, "position"],
                             capture_output=True, text=True).stdout.strip()
        try:
            self.set(float(out), self.length, True)
        except ValueError:
            self.synced = time.monotonic()

    def position(self):
        pos = self.base + (time.monotonic() - self.t0 if self.running else 0)
        return min(pos, self.length) if self.length else pos

    def fraction(self):
        return self.position() / self.length if self.length else None


def fmt_time(sec):
    sec = int(sec)
    h, rem = divmod(sec, 3600)
    return f"{h}:{rem // 60:02}:{rem % 60:02}" if h else f"{rem // 60}:{rem % 60:02}"


def classes(state, clock):
    cls = [state[0].lower()]
    frac = clock.fraction()
    if frac is not None:
        cls.append(f"p{floor(frac * 100 / PROGRESS_STEP) * PROGRESS_STEP}")
    return cls


def tooltip(state, clock):
    _, player, title, artist, _ = state
    text = f"{player}: {title} — {artist}" if artist else f"{player}: {title}"
    frac = clock.fraction()
    if frac is not None:
        filled = round(frac * TOOLTIP_BAR)
        text += (f"\n{fmt_time(clock.position())} / {fmt_time(clock.length)}"
                 f"\n{'━' * filled}{'─' * (TOOLTIP_BAR - filled)}")
    return text


def animate(text, cls, grow):
    steps = range(1, FRAMES + 1) if grow else range(FRAMES - 1, -1, -1)
    for i in steps:
        k = round(len(text) * i / FRAMES)
        start = (len(text) - k) // 2
        emit(esc(text[start:start + k]) or " ", cls)
        time.sleep(FRAME_DELAY)


def fade(old, new, wave):
    for i in range(FADE_FRAMES, 0, -1):
        emit(markup(old, wave, i / FADE_FRAMES), old[0].lower())
        time.sleep(FRAME_DELAY)
    for i in range(1, FADE_FRAMES + 1):
        emit(markup(new, wave, i / FADE_FRAMES), new[0].lower())
        time.sleep(FRAME_DELAY)


def to_seconds(us):
    try:
        return int(us) / 1e6
    except ValueError:
        return 0.0


def parse(line):
    parts = line.split("\t")
    if len(parts) != 7 or parts[0] not in ("Playing", "Paused") or not parts[2]:
        return None, 0.0, 0.0
    parts[2] = clean(parts[2])
    return tuple(parts[:5]), to_seconds(parts[5]), to_seconds(parts[6])


def last_line(fd, buf):
    chunk = os.read(fd, 65536)
    if not chunk:
        raise EOFError
    buf += chunk
    *lines, buf = buf.split(b"\n")
    return (lines[-1].decode(errors="replace") if lines else None), buf


def to_wave(frame):
    levels = [int(v) for v in frame.strip(";").split(";") if v.isdigit()]
    return "".join(WAVE_CHARS[l] for l in levels) or WAVE_CHARS[0] * WAVE_BARS


def main():
    players = subprocess.Popen(
        ["playerctl", "--follow", "metadata", "--format",
         "{{status}}\t{{playerName}}\t{{title}}\t{{artist}}\t{{xesam:url}}\t{{position}}\t{{mpris:length}}"],
        stdout=subprocess.PIPE,
    )
    cfg = tempfile.NamedTemporaryFile("w", prefix="waybar-cava-", suffix=".conf", delete=False)
    cfg.write(CAVA_CONFIG)
    cfg.close()
    cava = subprocess.Popen(["cava", "-p", cfg.name], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)

    pfd, cfd = players.stdout.fileno(), cava.stdout.fileno()
    pbuf = cbuf = b""
    state, wave, clock = None, WAVE_CHARS[0] * WAVE_BARS, Clock()

    try:
        while True:
            ready, _, _ = select.select([pfd, cfd], [], [])

            if cfd in ready:
                frame, cbuf = last_line(cfd, cbuf)
                if frame is not None:
                    wave = to_wave(frame)
                    if state and state[0] == "Playing" and pfd not in ready:
                        clock.resync(state[1])
                        emit(markup(state, wave), classes(state, clock), tooltip(state, clock))

            if pfd not in ready:
                continue
            line, pbuf = last_line(pfd, pbuf)
            if line is None:
                continue

            new, position, length = parse(line)
            if new is None:
                if state:
                    animate(plain(state), state[0].lower(), grow=False)
                emit("")
            elif state is None or new[2:4] != state[2:4]:
                if state:
                    animate(plain(state), state[0].lower(), grow=False)
                animate(plain(new), new[0].lower(), grow=True)
            elif new[0] != state[0]:
                fade(state, new, wave)
            if new:
                clock.set(position, length, new[0] == "Playing")
                emit(markup(new, wave), classes(new, clock), tooltip(new, clock))
            state = new
    except EOFError:
        return 1
    finally:
        players.kill()
        cava.kill()
        os.unlink(cfg.name)


if __name__ == "__main__":
    sys.exit(main())
