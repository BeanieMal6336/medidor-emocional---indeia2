#!/usr/bin/env python3
"""Gera icones Android, iOS basico e Windows a partir de assets/icons/app_icon.png."""
from pathlib import Path
try:
    from PIL import Image
except ImportError:
    raise SystemExit("Instale Pillow: pip install pillow")

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "icons" / "app_icon.png"
if not SRC.exists():
    raise SystemExit(f"Icone nao encontrado: {SRC}")

img = Image.open(SRC).convert("RGBA")

ANDROID = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}
for folder, size in ANDROID.items():
    out = ROOT / "android" / "app" / "src" / "main" / "res" / folder / "ic_launcher.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    img.resize((size, size), Image.Resampling.LANCZOS).save(out, "PNG")

ios_dir = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
ios_sizes = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}
for name, size in ios_sizes.items():
    img.resize((size, size), Image.Resampling.LANCZOS).save(ios_dir / name, "PNG")

win_ico = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
ico_sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
ico_images = [img.resize(s, Image.Resampling.LANCZOS) for s in ico_sizes]
ico_images[0].save(
    win_ico,
    format="ICO",
    sizes=[(i.width, i.height) for i in ico_images],
    append_images=ico_images[1:],
)

print("Icones gerados com sucesso.")
