from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parent.parent
ANDROID_SIZES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

IOS_ICONS = [
    (40, "Icon-App-20x20@2x.png"),
    (60, "Icon-App-20x20@3x.png"),
    (29, "Icon-App-29x29@1x.png"),
    (58, "Icon-App-29x29@2x.png"),
    (87, "Icon-App-29x29@3x.png"),
    (40, "Icon-App-40x40@1x.png"),
    (80, "Icon-App-40x40@2x.png"),
    (120, "Icon-App-40x40@3x.png"),
    (120, "Icon-App-60x60@2x.png"),
    (180, "Icon-App-60x60@3x.png"),
    (76, "Icon-App-76x76@1x.png"),
    (152, "Icon-App-76x76@2x.png"),
    (167, "Icon-App-83.5x83.5@2x.png"),
    (1024, "Icon-App-1024x1024@1x.png"),
]


def make_icon(size, ios=False):
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    s = size / 1024.0

    if ios:
        draw.rectangle((0, 0, size, size), fill=(255, 255, 255, 255))
    else:
        margin = 88 * s
        radius = 210 * s
        draw.rounded_rectangle(
            (margin, margin, size - margin, size - margin),
            radius=radius,
            fill=(255, 255, 255, 255),
            outline=(229, 231, 235, 255),
            width=int(4 * s),
        )

    wallet_left = 272 * s
    wallet_right = 752 * s
    wallet_top = 392 * s
    wallet_bottom = 632 * s
    wallet_radius = 62 * s
    draw.rounded_rectangle(
        (wallet_left, wallet_top, wallet_right, wallet_bottom),
        radius=wallet_radius,
        fill=(17, 24, 39, 255),
    )

    inner_margin = 26 * s
    draw.rounded_rectangle(
        (
            wallet_left + inner_margin,
            wallet_top + inner_margin,
            wallet_right - inner_margin,
            wallet_bottom - inner_margin,
        ),
        radius=wallet_radius - inner_margin,
        fill=(255, 255, 255, 255),
    )

    circle_center = int(wallet_right - 118 * s)
    circle_radius = int(46 * s)
    draw.ellipse(
        (
            circle_center - circle_radius,
            (wallet_top + wallet_bottom) / 2 - circle_radius,
            circle_center + circle_radius,
            (wallet_top + wallet_bottom) / 2 + circle_radius,
        ),
        fill=(17, 24, 39, 255),
    )

    dot_radius = int(24 * s)
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
    android_dest = ROOT / "android" / "app" / "src" / "main" / "res"
    for folder, size in ANDROID_SIZES.items():
        path = android_dest / f"mipmap-{folder}" / "ic_launcher.png"
        image = make_icon(1024).resize((size, size), Image.LANCZOS)
        image.save(path)
        print(f"wrote {path}")

    ios_dest = (
        ROOT
        / "ios"
        / "Runner"
        / "Assets.xcassets"
        / "AppIcon.appiconset"
    )
    for size, name in IOS_ICONS:
        image = make_icon(size, ios=True)
        image.save(ios_dest / name)
        print(f"wrote {ios_dest / name}")


if __name__ == "__main__":
    main()
