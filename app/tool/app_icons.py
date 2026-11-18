"""Generates all BLACKFOX monochrome Kitsune icons and logos across Android,
Android TV, macOS, Windows, Linux, Core, and Web Dashboard.

Concept:
- Main Logo / Icon: A mysterious young male character with long flowing dark
  hair framing the face, wearing a traditional Japanese Kitsune fox mask,
  rendered strictly in black, white, and grayscale.
- Tray / Status Icons: High-contrast monochrome Kitsune fox mask silhouette
  with monochrome state indicators (white dot for connected, hollow/silver ring
  for idle/asleep, exclamation badge for error, 4-stage arc while connecting).

Run from app/ (needs Pillow):
    python tool/app_icons.py
or on Windows without Python/Pillow:
    powershell -NoProfile -ExecutionPolicy Bypass -File ../scripts/generate-icons.ps1
"""
import os
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
APP = os.path.join(HERE, '..')
CORE = os.path.join(APP, '..', 'core')
RES = os.path.join(APP, 'android', 'app', 'src', 'main', 'res')

ART = 0.66
BLACK = (8, 8, 10, 255)
DENSITY = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
WINDOWS_SIZES = [16, 20, 24, 32, 40, 48, 64, 128, 256]
MACOS_SIZES = [16, 32, 64, 128, 256, 512, 1024]
TRAY_SIZES = [16, 20, 24, 32, 48, 64]

ADAPTIVE = '''<?xml version="1.0" encoding="utf-8"?>
<!-- The launcher icon on Android 8+: the BLACKFOX Kitsune symbol over obsidian black. -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
'''

# Strictly monochrome palette
DOT_GOOD = (255, 255, 255)
DOT_SET = (220, 220, 228)
DOT_BAD = (180, 180, 190)
TRAY_TILE = (18, 18, 22, 255)


def pt(x, y, s):
    return (x * s, y * s)


def symbol(size, include_frame=True):
    """Draws the BLACKFOX monochrome Kitsune character at 2x supersampling."""
    k = 2
    sz = size * k
    s = sz / 1000.0
    img = Image.new('RGBA', (sz, sz), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    pure_black = (8, 8, 10, 255)
    charcoal = (22, 22, 26, 255)
    dark_gray = (42, 42, 48, 255)
    mid_gray = (110, 110, 118, 255)
    silver = (195, 195, 202, 255)
    bone_white = (244, 244, 246, 255)
    pure_white = (255, 255, 255, 255)

    pad = round(40 * s)
    if include_frame:
        d.ellipse([pad, pad, sz - pad, sz - pad], fill=pure_black)

    # 1. Victorian Gothic collar
    collar = [pt(210, 920, s), pt(270, 760, s), pt(370, 710, s), pt(500, 790, s),
              pt(630, 710, s), pt(730, 760, s), pt(790, 920, s)]
    d.polygon(collar, fill=charcoal, outline=(220, 220, 225, 140))

    # 2. Long dark hair back volume
    hair_back = [pt(500, 160, s), pt(330, 200, s), pt(235, 350, s), pt(195, 560, s),
                 pt(180, 780, s), pt(240, 890, s), pt(310, 830, s), pt(350, 910, s),
                 pt(500, 860, s), pt(650, 910, s), pt(690, 830, s), pt(760, 890, s),
                 pt(820, 780, s), pt(805, 560, s), pt(765, 350, s), pt(670, 200, s)]
    d.polygon(hair_back, fill=pure_black)

    # 3. Lower jaw
    jaw = [pt(395, 620, s), pt(425, 715, s), pt(500, 755, s), pt(575, 715, s), pt(605, 620, s)]
    d.polygon(jaw, fill=mid_gray)

    # 4. Kitsune ears & mask
    ear_l = [pt(295, 335, s), pt(240, 105, s), pt(420, 235, s)]
    ear_r = [pt(705, 335, s), pt(760, 105, s), pt(580, 235, s)]
    d.polygon(ear_l, fill=bone_white, outline=pure_black)
    d.polygon(ear_r, fill=bone_white, outline=pure_black)
    d.polygon([pt(312, 310, s), pt(272, 152, s), pt(395, 245, s)], fill=dark_gray)
    d.polygon([pt(688, 310, s), pt(728, 152, s), pt(605, 245, s)], fill=dark_gray)

    mask_face = [pt(500, 210, s), pt(390, 235, s), pt(290, 330, s), pt(270, 465, s),
                 pt(335, 585, s), pt(440, 675, s), pt(500, 715, s), pt(560, 675, s),
                 pt(665, 585, s), pt(730, 465, s), pt(710, 330, s), pt(610, 235, s)]
    d.polygon(mask_face, fill=bone_white)
    mask_shadow = [pt(500, 210, s), pt(500, 715, s), pt(560, 675, s), pt(665, 585, s),
                   pt(730, 465, s), pt(710, 330, s), pt(610, 235, s)]
    d.polygon(mask_shadow, fill=silver)

    # Forehead mark & nose tip
    d.polygon([pt(500, 255, s), pt(522, 315, s), pt(500, 375, s), pt(478, 315, s)], fill=pure_black)
    d.polygon([pt(462, 595, s), pt(538, 595, s), pt(500, 645, s)], fill=pure_black)

    # Slit eyes
    d.polygon([pt(325, 415, s), pt(385, 395, s), pt(455, 445, s), pt(375, 450, s)], fill=pure_black)
    d.polygon([pt(675, 415, s), pt(615, 395, s), pt(545, 445, s), pt(625, 450, s)], fill=pure_black)

    # Hair strands framing the mask
    d.polygon([pt(390, 215, s), pt(320, 340, s), pt(275, 540, s), pt(245, 780, s), pt(295, 660, s), pt(345, 410, s)], fill=pure_black)
    d.polygon([pt(610, 215, s), pt(680, 340, s), pt(725, 540, s), pt(755, 780, s), pt(705, 660, s), pt(655, 410, s)], fill=pure_black)

    if include_frame:
        d.ellipse([pad, pad, sz - pad, sz - pad], outline=(235, 235, 240, 200), width=max(1, round(6 * s)))

    return img.resize((size, size), Image.LANCZOS)


def tile_art():
    return symbol(512, include_frame=True)


def art_layer(art, size, share):
    bbox = art.getchannel('A').getbbox()
    if bbox:
        art = art.crop(bbox)
    scale = size * share / max(art.size)
    w, h = max(1, round(art.width * scale)), max(1, round(art.height * scale))
    layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    layer.alpha_composite(art.resize((w, h), Image.LANCZOS), ((size - w) // 2, (size - h) // 2))
    return layer


def tile(glyph, size):
    return symbol(size, include_frame=True)


def android(glyph):
    for dpi, k in DENSITY.items():
        folder = os.path.join(RES, 'mipmap-' + dpi)
        os.makedirs(folder, exist_ok=True)
        px = round(108 * k)
        art_layer(glyph, px, ART).save(os.path.join(folder, 'ic_launcher_foreground.png'), optimize=True)
        Image.new('RGBA', (px, px), BLACK).save(os.path.join(folder, 'ic_launcher_background.png'), optimize=True)
        tile(glyph, round(48 * k)).save(os.path.join(folder, 'ic_launcher.png'), optimize=True)
    folder = os.path.join(RES, 'mipmap-anydpi-v26')
    os.makedirs(folder, exist_ok=True)
    with open(os.path.join(folder, 'ic_launcher.xml'), 'w', newline='\n') as f:
        f.write(ADAPTIVE)


def tv_banner(glyph):
    from PIL import ImageFont
    w, h = 320, 180
    out = Image.new('RGBA', (w, h), (10, 10, 13, 255))
    draw = ImageDraw.Draw(out)
    draw.rectangle([6, 6, w - 7, h - 7], outline=(255, 255, 255, 90), width=1)
    sym = symbol(104, include_frame=True)
    out.alpha_composite(sym, (18, 38))
    font = ImageFont.truetype(os.path.join(APP, 'assets', 'fonts', 'Vazirmatn-Bold.ttf'), 24)
    draw.text((132, 68), 'BLACKFOX', font=font, fill=(255, 255, 255, 255))
    folder = os.path.join(RES, 'drawable-xhdpi')
    os.makedirs(folder, exist_ok=True)
    out.save(os.path.join(folder, 'banner.png'), optimize=True)


def crisp(art, size):
    image = art_layer(art, size, 1.0)
    alpha = image.getchannel('A')
    rgb = image.convert('RGB').filter(ImageFilter.UnsharpMask(radius=0.6 if size <= 24 else 0.8, percent=120, threshold=0))
    rgb = ImageEnhance.Contrast(rgb).enhance(1.06)
    out = rgb.convert('RGBA')
    out.putalpha(alpha)
    return out


def write_ico(path, art):
    images = [crisp(art, n) if n <= 48 else art_layer(art, n, 1.0) for n in WINDOWS_SIZES]
    images[-1].save(path, format='ICO', sizes=[(n, n) for n in WINDOWS_SIZES], append_images=images[:-1])


def macos(glyph):
    folder = os.path.join(APP, 'macos', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    big = symbol(1024, include_frame=True)
    for n in MACOS_SIZES:
        big.resize((n, n), Image.LANCZOS).save(os.path.join(folder, 'app_icon_%d.png' % n), optimize=True)


def app_logo(tile_art_img):
    art_layer(tile_art_img, 256, 1.0).save(os.path.join(APP, 'assets', 'logo.png'), optimize=True)


def windows(tile_art_img):
    write_ico(os.path.join(APP, 'windows', 'runner', 'resources', 'app_icon.ico'), tile_art_img)


def core(tile_art_img):
    desktop = os.path.join(CORE, 'internal', 'desktop')
    write_ico(os.path.join(desktop, 'appicon.ico'), tile_art_img)
    art_layer(tile_art_img, 192, 1.0).save(os.path.join(CORE, 'internal', 'service', 'web', 'icon.png'), optimize=True)


def asleep(color):
    return tuple(round(c * 0.55) for c in color)


def tray_icon(filled=None, dot=None):
    n = 320
    img = Image.new('RGBA', (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([12, 12, n - 12, n - 12], fill=TRAY_TILE, outline=(220, 220, 225, 180), width=8)
    s = n / 100.0
    fox_poly = [pt(24, 16, s), pt(40, 30, s), pt(60, 30, s), pt(76, 16, s),
                pt(78, 48, s), pt(68, 68, s), pt(50, 84, s), pt(32, 68, s), pt(22, 48, s)]
    d.polygon(fox_poly, fill=(250, 250, 252, 255))
    d.polygon([pt(29, 48, s), pt(44, 53, s), pt(33, 56, s)], fill=(14, 14, 18, 255))
    d.polygon([pt(71, 48, s), pt(56, 53, s), pt(67, 56, s)], fill=(14, 14, 18, 255))
    if dot:
        d.ellipse([round(62 * s), round(62 * s), round(94 * s), round(94 * s)], fill=TRAY_TILE)
        d.ellipse([round(67 * s), round(67 * s), round(89 * s), round(89 * s)], fill=dot + (255,))
    return img.resize((80, 80), Image.LANCZOS)


def save_ico(path, big):
    images = [big.resize((n, n), Image.LANCZOS) for n in TRAY_SIZES]
    images[-1].save(path, format='ICO', sizes=[(n, n) for n in TRAY_SIZES], append_images=images[:-1])


def tray():
    app = os.path.join(APP, 'assets', 'tray')
    for old in os.listdir(app):
        os.remove(os.path.join(app, old))
    icons = {
        'off': tray_icon(),
        'on': tray_icon(dot=DOT_GOOD),
        'idle': tray_icon(dot=asleep(DOT_GOOD)),
        'error': tray_icon(dot=DOT_BAD),
    }
    for frame in range(1, 5):
        icons['busy%d' % frame] = tray_icon({frame - 1: (255, 255, 255)})
    for name, big in icons.items():
        save_ico(os.path.join(app, name + '.ico'), big)
        big.resize((64, 64), Image.LANCZOS).save(os.path.join(app, name + '.png'), optimize=True)
    folder = os.path.join(CORE, 'internal', 'desktop', 'tray')
    os.makedirs(folder, exist_ok=True)
    states = {
        'running': tray_icon(dot=DOT_GOOD),
        'set': tray_icon(dot=DOT_SET),
        'running-asleep': tray_icon(dot=asleep(DOT_GOOD)),
        'set-asleep': tray_icon(dot=asleep(DOT_SET)),
        'waiting': tray_icon({0: (255, 255, 255)}),
        'error': tray_icon(dot=DOT_BAD),
        'off': tray_icon(),
    }
    for name, big in states.items():
        save_ico(os.path.join(folder, name + '.ico'), big)
        big.resize((32, 32), Image.LANCZOS).save(os.path.join(folder, name + '.png'), optimize=True)


def main():
    square = tile_art()
    glyph = symbol(1024, include_frame=False)
    android(glyph)
    tv_banner(glyph)
    macos(glyph)
    windows(square)
    core(square)
    app_logo(square)
    tray()


if __name__ == '__main__':
    main()
