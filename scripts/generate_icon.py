from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parent.parent
SIZES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def make_icon(size):
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    s = size / 1024.0
    margin = 96 * s
    radius = 220 * s
    box = (margin, margin, size - margin, size - margin)

    for y in range(size):
        t = y / size
        color = lerp((59, 130, 246), (139, 92, 246), t)
        draw.line([(0, y), (size, y)], fill=color + (255,))

    overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    overlay_draw = ImageDraw.Draw(overlay)
    overlay_draw.rounded_rectangle(box, radius=radius, fill=(0, 0, 0, 255))
    canvas = Image.alpha_composite(canvas, overlay)
    draw = ImageDraw.Draw(canvas)

    wallet_left = 262 * s
    wallet_right = 762 * s
    wallet_top = 392 * s
    wallet_bottom = 632 * s
    wallet_radius = 64 * s
    draw.rounded_rectangle(
        (wallet_left, wallet_top, wallet_right, wallet_bottom),
        radius=wallet_radius,
        fill=(255, 255, 255, 255),
    )

    inner_margin = 24 * s
    draw.rounded_rectangle(
        (
            wallet_left + inner_margin,
            wallet_top + inner_margin,
            wallet_right - inner_margin,
            wallet_bottom - inner_margin,
        ),
        radius=wallet_radius - inner_margin,
        outline=(139, 92, 246, 255),
        width=int(14 * s),
    )

    circle_center = int(wallet_right - 120 * s)
    circle_radius = int(48 * s)
    draw.ellipse(
        (
            circle_center - circle_radius,
            (wallet_top + wallet_bottom) / 2 - circle_radius,
            circle_center + circle_radius,
            (wallet_top + wallet_bottom) / 2 + circle_radius,
        ),
        fill=(139, 92, 246, 255),
    )

    dot_radius = int(26 * s)
    draw.ellipse(
        (
            circle_center - dot_radius,
            (wallet_top + wallet_bottom) / 2 - dot_radius,
            circle_center + dot_radius,
            (wallet_top + wallet_bottom) / 2 + dot_radius,
        ),
        fill=(255, 255, 255, 255),
    )

    return canvas


def main():
    dest = ROOT / "android" / "app" / "src" / "main" / "res"
    for folder, size in SIZES.items():
        path = dest / f"mipmap-{folder}" / "ic_launcher.png"
        image = make_icon(1024).resize((size, size), Image.LANCZOS)
        image.save(path)
        print(f"wrote {path}")


if __name__ == "__main__":
    main()
