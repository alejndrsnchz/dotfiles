#!/usr/bin/env python3

import colorsys
import math
import os
import random
import signal
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image


# ============================================================
# CONFIGURATION
# ============================================================

OUTPUT = Path.home() / ".config/waybar/palette.css"

# Waybar position.
# Change to "bottom" if your Waybar is at the bottom.
BAR_POSITION = "top"

# Number of LAB clusters.
CLUSTERS = 14

# Maximum number of pixels analyzed.
SAMPLE_SIZE = 7000

# K-Means iterations.
ITERATIONS = 30

# Random seed = deterministic palettes.
RANDOM_SEED = 42

# Minimum saturation/chroma required for a real accent.
ACCENT_SATURATION = 0.25

# Minimum fraction of image required for an accent candidate.
#
# This prevents a tiny red/green object from taking over
# the entire Waybar.
MIN_ACCENT_RATIO = 0.012

# Threshold for deciding whether an image is effectively
# monochromatic.
#
# Lower = more aggressive color detection.
MONOCHROME_THRESHOLD = 0.075


# ============================================================
# BASIC COLOR FUNCTIONS
# ============================================================

def clamp(value, minimum=0.0, maximum=255.0):
    return max(minimum, min(maximum, value))


def rgb_to_hex(rgb):
    return "#{:02x}{:02x}{:02x}".format(
        int(clamp(rgb[0])),
        int(clamp(rgb[1])),
        int(clamp(rgb[2])),
    )


def mix(a, b, amount):
    """
    amount = 0 -> a
    amount = 1 -> b
    """
    return tuple(
        round(x + (y - x) * amount)
        for x, y in zip(a, b)
    )


def scale_rgb(rgb, amount):
    return tuple(
        round(clamp(x * amount))
        for x in rgb
    )


def rgb_luminance(rgb):
    """
    Relative luminance according to sRGB.
    """

    def linear(c):
        c = c / 255.0

        if c <= 0.04045:
            return c / 12.92

        return ((c + 0.055) / 1.055) ** 2.4

    r = linear(rgb[0])
    g = linear(rgb[1])
    b = linear(rgb[2])

    return (
        0.2126 * r +
        0.7152 * g +
        0.0722 * b
    )


def contrast_ratio(a, b):
    """
    WCAG contrast ratio.
    """

    l1 = rgb_luminance(a)
    l2 = rgb_luminance(b)

    if l1 < l2:
        l1, l2 = l2, l1

    return (l1 + 0.05) / (l2 + 0.05)


def rgb_to_hsv(rgb):
    r, g, b = [x / 255.0 for x in rgb]
    return colorsys.rgb_to_hsv(r, g, b)


def saturation(rgb):
    return rgb_to_hsv(rgb)[1]


# ============================================================
# RGB <-> CIELAB
# ============================================================

def srgb_to_linear(value):
    value /= 255.0

    if value <= 0.04045:
        return value / 12.92

    return ((value + 0.055) / 1.055) ** 2.4


def linear_to_srgb(value):
    value = max(0.0, min(1.0, value))

    if value <= 0.0031308:
        return 12.92 * value

    return 1.055 * (value ** (1 / 2.4)) - 0.055


def rgb_to_xyz(rgb):
    r = srgb_to_linear(rgb[0])
    g = srgb_to_linear(rgb[1])
    b = srgb_to_linear(rgb[2])

    x = (
        r * 0.4124564 +
        g * 0.3575761 +
        b * 0.1804375
    )

    y = (
        r * 0.2126729 +
        g * 0.7151522 +
        b * 0.0721750
    )

    z = (
        r * 0.0193339 +
        g * 0.1191920 +
        b * 0.9503041
    )

    return (
        x * 100,
        y * 100,
        z * 100,
    )


def xyz_to_lab(xyz):
    x, y, z = xyz

    # D65 reference white.
    x /= 95.047
    y /= 100.000
    z /= 108.883

    delta = 6 / 29

    def f(value):
        if value > delta ** 3:
            return value ** (1 / 3)

        return (
            value / (3 * delta ** 2)
            + 4 / 29
        )

    fx = f(x)
    fy = f(y)
    fz = f(z)

    return (
        116 * fy - 16,
        500 * (fx - fy),
        200 * (fy - fz),
    )


def rgb_to_lab(rgb):
    return xyz_to_lab(rgb_to_xyz(rgb))


def lab_to_rgb(lab):
    L, a, b = lab

    fy = (L + 16) / 116
    fx = a / 500 + fy
    fz = fy - b / 200

    delta = 6 / 29

    def inverse(value):
        if value > delta:
            return value ** 3

        return (
            3 * delta ** 2 *
            (value - 4 / 29)
        )

    x = 95.047 * inverse(fx)
    y = 100.000 * inverse(fy)
    z = 108.883 * inverse(fz)

    x /= 100
    y /= 100
    z /= 100

    r = (
        x * 3.2404542 +
        y * -1.5371385 +
        z * -0.4985314
    )

    g = (
        x * -0.9692660 +
        y * 1.8760108 +
        z * 0.0415560
    )

    b = (
        x * 0.0556434 +
        y * -0.2040259 +
        z * 1.0572252
    )

    return (
        round(clamp(linear_to_srgb(r) * 255)),
        round(clamp(linear_to_srgb(g) * 255)),
        round(clamp(linear_to_srgb(b) * 255)),
    )


def lab_distance(a, b):
    return math.sqrt(
        (a[0] - b[0]) ** 2 +
        (a[1] - b[1]) ** 2 +
        (a[2] - b[2]) ** 2
    )


def lab_chroma(lab):
    """
    Distance from neutral gray in LAB.
    """
    return math.sqrt(
        lab[1] ** 2 +
        lab[2] ** 2
    )


# ============================================================
# IMAGE SAMPLING
# ============================================================

def load_image(path):
    image = Image.open(path).convert("RGB")

    # 500x500 is enough for palette extraction and still cheap.
    image.thumbnail((500, 500))

    return image


def sample_pixels(image):
    pixels = list(image.getdata())

    if len(pixels) <= SAMPLE_SIZE:
        return pixels

    random.seed(RANDOM_SEED)

    return random.sample(
        pixels,
        SAMPLE_SIZE
    )


# ============================================================
# SPATIAL WEIGHTING
# ============================================================

def pixel_weight(x, y, width, height):
    """
    Give slightly more importance to the region around Waybar.

    This is intentionally subtle. We don't want the top strip
    to completely dominate the global palette.
    """

    if BAR_POSITION == "top":
        distance = y / max(1, height - 1)

    else:
        distance = 1 - (y / max(1, height - 1))

    # Highest weight near the bar.
    # Falls gradually toward the opposite side.
    return 1.0 + 0.35 * (1.0 - distance)


def weighted_samples(image):
    width, height = image.size

    pixels = []

    for y in range(height):
        for x in range(width):
            rgb = image.getpixel((x, y))

            weight = pixel_weight(
                x,
                y,
                width,
                height
            )

            # We represent weighting by repeated samples.
            #
            # Since weight is only 1.0-1.35, this remains cheap.
            copies = 1

            if weight > 1.20:
                copies = 2

            pixels.extend([rgb] * copies)

    if len(pixels) > SAMPLE_SIZE:
        random.seed(RANDOM_SEED)
        pixels = random.sample(
            pixels,
            SAMPLE_SIZE
        )

    return pixels


# ============================================================
# K-MEANS++
# ============================================================

def initialize_centers(points, k):
    """
    K-Means++ initialization in LAB.
    """

    if not points:
        return []

    centers = [
        random.choice(points)
    ]

    while len(centers) < min(k, len(points)):
        distances = []

        for point in points:
            distance = min(
                lab_distance(point, center)
                for center in centers
            )

            distances.append(distance ** 2)

        total = sum(distances)

        if total <= 0:
            break

        target = random.random() * total
        accumulated = 0.0

        for point, distance in zip(
            points,
            distances
        ):
            accumulated += distance

            if accumulated >= target:
                centers.append(point)
                break

    return centers


def kmeans(points, k):
    """
    K-Means clustering in LAB.

    Returns clusters with:
      - LAB center
      - RGB center
      - pixel count
      - ratio
    """

    if not points:
        return []

    centers = initialize_centers(
        points,
        k
    )

    if not centers:
        return []

    assignments = [-1] * len(points)

    for _ in range(ITERATIONS):
        groups = [
            []
            for _ in centers
        ]

        changed = False

        # Assignment step.
        for index, point in enumerate(points):
            cluster_index = min(
                range(len(centers)),
                key=lambda i:
                    lab_distance(
                        point,
                        centers[i]
                    )
            )

            if assignments[index] != cluster_index:
                changed = True
                assignments[index] = cluster_index

            groups[cluster_index].append(point)

        # Update step.
        new_centers = []

        for index, group in enumerate(groups):
            if not group:
                new_centers.append(
                    centers[index]
                )
                continue

            L = sum(p[0] for p in group) / len(group)
            a = sum(p[1] for p in group) / len(group)
            b = sum(p[2] for p in group) / len(group)

            new_centers.append(
                (L, a, b)
            )

        movement = sum(
            lab_distance(a, b)
            for a, b in zip(
                centers,
                new_centers
            )
        )

        centers = new_centers

        if not changed or movement < 0.35:
            break

    # Build final clusters.
    clusters = []

    total = len(points)

    for index, center in enumerate(centers):
        count = assignments.count(index)

        if count == 0:
            continue

        clusters.append({
            "lab": center,
            "rgb": lab_to_rgb(center),
            "count": count,
            "ratio": count / total,
            "chroma": lab_chroma(center),
        })

    clusters.sort(
        key=lambda c: c["ratio"],
        reverse=True
    )

    return clusters


# ============================================================
# IMAGE COLOR ANALYSIS
# ============================================================

def calculate_colorfulness(clusters):
    """
    Weighted chroma.

    This is much better than simply checking whether
    one individual pixel is saturated.
    """

    if not clusters:
        return 0.0

    total = 0.0

    for cluster in clusters:
        # LAB chroma roughly normalized to 0..1.
        normalized_chroma = min(
            cluster["chroma"] / 100.0,
            1.0
        )

        total += (
            normalized_chroma *
            cluster["ratio"]
        )

    return total


def is_monochrome(clusters):
    """
    Detect grayscale / nearly grayscale wallpapers.

    We require BOTH:
      - low average chroma
      - no meaningful saturated cluster
    """

    if not clusters:
        return True

    colorfulness = calculate_colorfulness(
        clusters
    )

    meaningful_colors = [
        c
        for c in clusters
        if (
            c["ratio"] >= MIN_ACCENT_RATIO
            and
            saturation(c["rgb"]) >= 0.20
        )
    ]

    return (
        colorfulness < MONOCHROME_THRESHOLD
        and
        not meaningful_colors
    )


# ============================================================
# BACKGROUND
# ============================================================

def select_background(clusters):
    """
    Select a dark, sufficiently represented color.

    We don't simply choose the darkest color because that
    often selects a tiny black object.
    """

    candidates = []

    for cluster in clusters:
        rgb = cluster["rgb"]
        luminance = rgb_luminance(rgb)

        presence = math.sqrt(
            cluster["ratio"]
        )

        # Favor dark colors.
        darkness = 1.0 - luminance

        score = (
            darkness * 4.0
            + presence * 3.0
            + cluster["ratio"] * 2.0
        )

        candidates.append(
            (score, cluster)
        )

    if not candidates:
        return (12, 14, 18)

    return max(
        candidates,
        key=lambda x: x[0]
    )[1]["rgb"]


# ============================================================
# FOREGROUND
# ============================================================

def make_readable_foreground(bg):
    """
    Fallback if no extracted color has enough contrast.
    """

    bg_luminance = rgb_luminance(bg)

    if bg_luminance < 0.45:
        target = (235, 235, 235)

    else:
        target = (25, 25, 25)

    # Find a conservative color with enough contrast.
    for amount in [
        0.0,
        0.15,
        0.30,
        0.45,
        0.60,
    ]:
        candidate = mix(
            bg,
            target,
            1.0 - amount
        )

        if contrast_ratio(
            candidate,
            bg
        ) >= 4.5:
            return candidate

    return target


def select_foreground(clusters, bg):
    """
    Foreground should be:
      - readable
      - sufficiently represented
      - not necessarily pure white
    """

    candidates = []

    for cluster in clusters:
        rgb = cluster["rgb"]

        contrast = contrast_ratio(
            rgb,
            bg
        )

        if contrast < 4.5:
            continue

        presence = math.sqrt(
            cluster["ratio"]
        )

        score = (
            min(contrast, 12.0) * 2.0
            + presence * 3.0
        )

        candidates.append(
            (score, rgb)
        )

    if not candidates:
        return make_readable_foreground(bg)

    return max(
        candidates,
        key=lambda x: x[0]
    )[1]


# ============================================================
# ACCENT
# ============================================================

def select_accent(clusters, bg):
    """
    Select an actual color from the wallpaper.

    Important:
    A tiny highly-saturated object should NOT win.
    """

    candidates = []

    for cluster in clusters:
        rgb = cluster["rgb"]

        h, s, v = rgb_to_hsv(rgb)

        if s < ACCENT_SATURATION:
            continue

        if v < 0.22:
            continue

        if cluster["ratio"] < MIN_ACCENT_RATIO:
            continue

        contrast = contrast_ratio(
            rgb,
            bg
        )

        if contrast < 2.0:
            continue

        # Saturation is important, but presence is also important.
        presence = math.sqrt(
            cluster["ratio"]
        )

        # LAB chroma rewards colors that are genuinely
        # chromatic instead of just RGB-saturated.
        chroma = min(
            cluster["chroma"] / 100.0,
            1.0
        )

        score = (
            s * 3.0
            + chroma * 4.0
            + presence * 4.0
            + min(contrast, 7.0) * 0.5
        )

        candidates.append(
            (score, rgb)
        )

    if not candidates:
        return None

    return max(
        candidates,
        key=lambda x: x[0]
    )[1]


# ============================================================
# SECONDARY ACCENT
# ============================================================

def hue_distance(a, b):
    distance = abs(a - b)

    return min(
        distance,
        1.0 - distance
    )


def select_secondary_accent(
    clusters,
    accent,
    bg
):
    """
    Finds another real color from the image,
    preferably with a different hue.
    """

    if accent is None:
        return None

    accent_hue = rgb_to_hsv(
        accent
    )[0]

    candidates = []

    for cluster in clusters:
        rgb = cluster["rgb"]

        h, s, v = rgb_to_hsv(rgb)

        if s < 0.20:
            continue

        if cluster["ratio"] < MIN_ACCENT_RATIO:
            continue

        distance = hue_distance(
            h,
            accent_hue
        )

        if distance < 0.12:
            continue

        contrast = contrast_ratio(
            rgb,
            bg
        )

        if contrast < 2.0:
            continue

        score = (
            distance * 4.0
            + s * 2.5
            + math.sqrt(cluster["ratio"]) * 3.0
            + min(contrast, 7.0) * 0.3
        )

        candidates.append(
            (score, rgb)
        )

    if not candidates:
        return None

    return max(
        candidates,
        key=lambda x: x[0]
    )[1]


# ============================================================
# MONOCHROME COLORS
# ============================================================

def monochrome_accent(bg, fg):
    """
    IMPORTANT:
    Never invent a hue for grayscale wallpapers.
    """

    bg_l = rgb_luminance(bg)

    if bg_l < 0.20:
        # Light gray accent.
        candidate = mix(
            bg,
            fg,
            0.55
        )

    else:
        # Dark gray accent.
        candidate = mix(
            fg,
            bg,
            0.65
        )

    return candidate


def monochrome_muted(bg, fg):
    return mix(
        fg,
        bg,
        0.55
    )


# ============================================================
# SEMANTIC COLORS
# ============================================================

def hsv_to_rgb(h, s, v):
    rgb = colorsys.hsv_to_rgb(
        h % 1.0,
        max(0.0, min(1.0, s)),
        max(0.0, min(1.0, v)),
    )

    return tuple(
        round(x * 255)
        for x in rgb
    )


def semantic_color(
    accent,
    bg,
    target_hue
):
    """
    Creates semantic colors while keeping them visually
    related to the extracted accent.

    We deliberately avoid extremely bright/pastel colors.
    """

    h, s, v = rgb_to_hsv(accent)

    # Preserve some saturation from the wallpaper.
    semantic_saturation = max(
        0.45,
        min(0.75, s)
    )

    # Avoid pastel-looking colors.
    semantic_value = max(
        0.55,
        min(0.90, v)
    )

    raw = hsv_to_rgb(
        target_hue,
        semantic_saturation,
        semantic_value
    )

    # Pull the semantic color slightly toward the
    # wallpaper accent so the UI doesn't look disconnected.
    result = mix(
        raw,
        accent,
        0.25
    )

    # Ensure minimum contrast against bg.
    if contrast_ratio(
        result,
        bg
    ) < 2.5:

        if rgb_luminance(bg) < 0.20:
            result = mix(
                result,
                (255, 255, 255),
                0.20
            )
        else:
            result = mix(
                result,
                (0, 0, 0),
                0.20
            )

    return result


# ============================================================
# PALETTE GENERATION
# ============================================================

def generate_palette(clusters):
    bg = select_background(
        clusters
    )

    fg = select_foreground(
        clusters,
        bg
    )

    monochrome = is_monochrome(
        clusters
    )

    accent = select_accent(
        clusters,
        bg
    )

    if monochrome or accent is None:

        # ----------------------------------------------------
        # GRAYSCALE MODE
        # ----------------------------------------------------

        accent = monochrome_accent(
            bg,
            fg
        )

        accent_alt = monochrome_muted(
            bg,
            fg
        )

        good = accent
        warning = accent
        critical = accent

    else:

        # ----------------------------------------------------
        # COLOR MODE
        # ----------------------------------------------------

        accent_alt = select_secondary_accent(
            clusters,
            accent,
            bg
        )

        if accent_alt is None:
            accent_alt = mix(
                accent,
                fg,
                0.30
            )

        # Conventional semantic hues, but restrained.
        good = semantic_color(
            accent,
            bg,
            0.38
        )

        warning = semantic_color(
            accent,
            bg,
            0.12
        )

        critical = semantic_color(
            accent,
            bg,
            0.00
        )

    # --------------------------------------------------------
    # SURFACES
    # --------------------------------------------------------

    bg_luminance = rgb_luminance(
        bg
    )

    if bg_luminance < 0.18:

        bg_alt = mix(
            bg,
            fg,
            0.10
        )

        surface = mix(
            bg,
            fg,
            0.16
        )

    else:

        bg_alt = mix(
            bg,
            (0, 0, 0),
            0.15
        )

        surface = mix(
            bg,
            fg,
            0.10
        )

    # Muted must remain readable but subordinate.
    muted = mix(
        fg,
        bg,
        0.48
    )

    return {
        "bg": bg,
        "bg_alt": bg_alt,
        "surface": surface,

        "fg": fg,
        "muted": muted,

        "accent": accent,
        "accent_alt": accent_alt,

        "good": good,
        "warning": warning,
        "critical": critical,
    }, monochrome


# ============================================================
# CSS GENERATION
# ============================================================

def write_css(
    palette,
    wallpaper,
    monochrome
):
    lines = [
        "/* ==================================================",
        "   AUTO-GENERATED WAYBAR PALETTE",
        "   ================================================== */",
        "",
        f"/* Wallpaper: {wallpaper} */",
        f"/* Mode: {'monochrome' if monochrome else 'color'} */",
        "",
    ]

    for name, rgb in palette.items():
        lines.append(
            f"@define-color {name} "
            f"{rgb_to_hex(rgb)};"
        )

    lines.append("")

    content = "\n".join(lines)

    OUTPUT.parent.mkdir(
        parents=True,
        exist_ok=True
    )

    # Atomic write:
    # Waybar will never see half-written CSS.
    fd, temporary = tempfile.mkstemp(
        prefix="palette-",
        suffix=".css",
        dir=OUTPUT.parent
    )

    try:
        with os.fdopen(
            fd,
            "w",
            encoding="utf-8"
        ) as file:
            file.write(content)

        os.replace(
            temporary,
            OUTPUT
        )

    except Exception:
        try:
            os.unlink(temporary)
        except OSError:
            pass

        raise


# ============================================================
# WAYBAR RELOAD
# ============================================================

def reload_waybar():
    """
    SIGUSR2 tells Waybar to reload CSS.
    """

    try:
        subprocess.run(
            ["pkill", "-SIGUSR2", "waybar"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
    except Exception as error:
        print(
            f"warning: could not reload Waybar: {error}",
            file=sys.stderr
        )


# ============================================================
# DEBUG OUTPUT
# ============================================================

def print_palette(
    palette,
    monochrome,
    colorfulness
):
    print()
    print(
        f"Colorfulness: {colorfulness:.3f}"
    )

    print(
        f"Mode: "
        f"{'MONOCHROME' if monochrome else 'COLOR'}"
    )

    print()
    print("Palette:")
    print()

    for name, rgb in palette.items():
        print(
            f"  {name:12} "
            f"{rgb_to_hex(rgb)}"
        )

    print()


# ============================================================
# MAIN
# ============================================================

def main():
    if len(sys.argv) != 2:
        print(
            f"Usage: {sys.argv[0]} /path/to/wallpaper",
            file=sys.stderr
        )
        sys.exit(1)

    wallpaper = os.path.expanduser(
        sys.argv[1]
    )

    if not os.path.isfile(wallpaper):
        print(
            f"error: wallpaper does not exist:\n"
            f"{wallpaper}",
            file=sys.stderr
        )
        sys.exit(1)

    print(
        f"Analyzing wallpaper:\n"
        f"  {wallpaper}"
    )

    random.seed(
        RANDOM_SEED
    )

    image = load_image(
        wallpaper
    )

    pixels = weighted_samples(
        image
    )

    if not pixels:
        print(
            "error: no pixels found",
            file=sys.stderr
        )
        sys.exit(1)

    print(
        f"Sampled {len(pixels)} pixels"
    )

    print(
        f"Converting to CIELAB..."
    )

    lab_pixels = [
        rgb_to_lab(pixel)
        for pixel in pixels
    ]

    print(
        f"Running K-Means "
        f"({CLUSTERS} clusters)..."
    )

    clusters = kmeans(
        lab_pixels,
        CLUSTERS
    )

    if not clusters:
        print(
            "error: clustering failed",
            file=sys.stderr
        )
        sys.exit(1)

    colorfulness = calculate_colorfulness(
        clusters
    )

    palette, monochrome = generate_palette(
        clusters
    )

    write_css(
        palette,
        wallpaper,
        monochrome
    )

    print_palette(
        palette,
        monochrome,
        colorfulness
    )

    print(
        f"Written to:\n"
        f"  {OUTPUT}"
    )

    reload_waybar()

    print(
        "Waybar reload requested."
    )


if __name__ == "__main__":
    main()
