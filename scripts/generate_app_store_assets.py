from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ASSET_ROOT = ROOT / "AppStoreAssets"
ICON_SET = ROOT / "ToolVaultAI" / "Resources" / "Assets.xcassets" / "AppIcon.appiconset"

CHARCOAL = (10, 13, 17)
SURFACE = (23, 29, 35)
SURFACE_2 = (32, 40, 48)
STEEL = (62, 124, 160)
STEEL_DARK = (30, 58, 74)
ORANGE = (250, 106, 22)
ORANGE_DARK = (182, 70, 22)
GREEN = (66, 197, 116)
YELLOW = (255, 186, 57)
RED = (234, 72, 56)
WHITE = (246, 249, 252)
MUTED = (158, 171, 184)
BLACK = (0, 0, 0)


def font(size: int, weight: str = "regular") -> ImageFont.FreeTypeFont:
    candidates = {
        "regular": [
            "C:/Windows/Fonts/segoeui.ttf",
            "C:/Windows/Fonts/arial.ttf",
        ],
        "semibold": [
            "C:/Windows/Fonts/seguisb.ttf",
            "C:/Windows/Fonts/segoeuib.ttf",
            "C:/Windows/Fonts/arialbd.ttf",
        ],
        "bold": [
            "C:/Windows/Fonts/segoeuib.ttf",
            "C:/Windows/Fonts/arialbd.ttf",
        ],
        "black": [
            "C:/Windows/Fonts/segoeuib.ttf",
            "C:/Windows/Fonts/arialbd.ttf",
        ],
    }
    for candidate in candidates[weight]:
        path = Path(candidate)
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


def ensure_dirs() -> None:
    for path in [
        ASSET_ROOT / "iPhone_6_9",
        ASSET_ROOT / "iPhone_6_5",
        ASSET_ROOT / "iPad_13",
        ASSET_ROOT / "iPad_12_9",
        ASSET_ROOT / "SubscriptionReview",
        ASSET_ROOT / "SubscriptionPromotional",
        ASSET_ROOT / "Marketing",
        ICON_SET,
    ]:
        path.mkdir(parents=True, exist_ok=True)


def draw_gradient(draw: ImageDraw.ImageDraw, size: tuple[int, int]) -> None:
    w, h = size
    for y in range(h):
        t = y / max(1, h - 1)
        r = int(CHARCOAL[0] * (1 - t) + 18 * t)
        g = int(CHARCOAL[1] * (1 - t) + 24 * t)
        b = int(CHARCOAL[2] * (1 - t) + 30 * t)
        draw.line([(0, y), (w, y)], fill=(r, g, b))


def overlay_grid(im: Image.Image, opacity: int = 22) -> None:
    draw = ImageDraw.Draw(im, "RGBA")
    w, h = im.size
    step = max(48, w // 18)
    for x in range(-step, w + step, step):
        draw.line([(x, 0), (x + h // 3, h)], fill=(255, 255, 255, opacity), width=1)
    for y in range(0, h, step):
        draw.line([(0, y), (w, y)], fill=(255, 255, 255, opacity // 2), width=1)


def rounded(draw: ImageDraw.ImageDraw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def shadowed_panel(base: Image.Image, box, radius=26, fill=SURFACE, outline=(255, 255, 255, 28)):
    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow, "RGBA")
    x0, y0, x1, y1 = box
    sd.rounded_rectangle((x0, y0 + 18, x1, y1 + 18), radius=radius, fill=(0, 0, 0, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(24))
    base.alpha_composite(shadow)
    d = ImageDraw.Draw(base, "RGBA")
    d.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=1)


def text_size(draw: ImageDraw.ImageDraw, text: str, fnt) -> tuple[int, int]:
    box = draw.textbbox((0, 0), text, font=fnt)
    return box[2] - box[0], box[3] - box[1]


def wrap_text(draw: ImageDraw.ImageDraw, text: str, fnt, max_width: int) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        test = word if not current else current + " " + word
        if text_size(draw, test, fnt)[0] <= max_width:
            current = test
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def draw_wrapped(draw, text, xy, fnt, fill, width, line_gap=8):
    x, y = xy
    for line in wrap_text(draw, text, fnt, width):
        draw.text((x, y), line, font=fnt, fill=fill)
        y += text_size(draw, line, fnt)[1] + line_gap
    return y


def pill(draw, xy, text, fill, text_fill=WHITE, icon=None, pad_x=22, pad_y=10):
    x, y = xy
    f = font(27, "semibold")
    content = text if icon is None else f"{icon} {text}"
    tw, th = text_size(draw, content, f)
    rounded(draw, (x, y, x + tw + pad_x * 2, y + th + pad_y * 2), 999, fill)
    draw.text((x + pad_x, y + pad_y - 2), content, font=f, fill=text_fill)
    return x + tw + pad_x * 2


def draw_toolvault_mark(draw, x, y, size):
    rounded(draw, (x, y, x + size, y + size), int(size * 0.22), (255, 255, 255, 18), (255, 255, 255, 40), 2)
    cx, cy = x + size / 2, y + size / 2
    r = size * 0.28
    points = [
        (cx, cy - r),
        (cx + r * 0.85, cy - r * 0.28),
        (cx + r * 0.55, cy + r),
        (cx - r * 0.55, cy + r),
        (cx - r * 0.85, cy - r * 0.28),
    ]
    draw.polygon(points, fill=STEEL, outline=(145, 198, 222))
    draw.rounded_rectangle((cx - r * 0.42, cy - r * 0.05, cx + r * 0.42, cy + r * 0.56), radius=int(size * 0.06), fill=(8, 13, 18), outline=ORANGE, width=max(2, size // 28))
    draw.arc((cx - r * 0.35, cy - r * 0.42, cx + r * 0.35, cy + r * 0.25), 190, 350, fill=ORANGE, width=max(3, size // 22))
    draw.ellipse((cx - r * 0.08, cy + r * 0.20, cx + r * 0.08, cy + r * 0.36), fill=ORANGE)


def screenshot_base(size: tuple[int, int]) -> Image.Image:
    im = Image.new("RGBA", size, CHARCOAL + (255,))
    d = ImageDraw.Draw(im, "RGBA")
    draw_gradient(d, size)
    overlay_grid(im)
    w, h = size
    rail_w = max(24, w // 34)
    d.polygon(
        [(w - rail_w * 4, 0), (w - rail_w, 0), (w - rail_w * 7, h), (w - rail_w * 10, h)],
        fill=(250, 106, 22, 38),
    )
    d.polygon(
        [(0, h * 0.72), (rail_w * 4, h * 0.68), (rail_w * 7, h), (0, h)],
        fill=(62, 124, 160, 34),
    )
    d.rectangle((0, int(h * 0.995), w, h), fill=(250, 106, 22, 190))
    d.rectangle((0, int(h * 0.990), int(w * 0.38), h), fill=(62, 124, 160, 210))
    return im


def title_block(draw, title, subtitle, w, top, margin, scale):
    draw_toolvault_mark(draw, margin, top, int(88 * scale))
    draw.text((margin + int(112 * scale), top + int(5 * scale)), "ToolVault AI", font=font(int(34 * scale), "bold"), fill=WHITE)
    draw.text((margin + int(112 * scale), top + int(47 * scale)), "Premium tool inventory intelligence", font=font(int(22 * scale), "regular"), fill=MUTED)
    y = top + int(146 * scale)
    copy_width = int(w - 2 * margin - w * 0.16)
    draw_wrapped(draw, title, (margin, y), font(int(68 * scale), "black"), WHITE, copy_width, int(13 * scale))
    y += int(180 * scale)
    draw_wrapped(draw, subtitle, (margin, y), font(int(31 * scale), "regular"), MUTED, copy_width, int(10 * scale))


def draw_metric_card(base, box, label, value, tint):
    d = ImageDraw.Draw(base, "RGBA")
    shadowed_panel(base, box, 24, SURFACE)
    x0, y0, x1, y1 = box
    d.ellipse((x0 + 28, y0 + 28, x0 + 78, y0 + 78), fill=tint + (255,))
    d.text((x0 + 92, y0 + 27), label, font=font(25, "semibold"), fill=MUTED)
    d.text((x0 + 28, y0 + 94), value, font=font(45, "bold"), fill=WHITE)


def draw_dashboard_ui(base, box, compact=False):
    d = ImageDraw.Draw(base, "RGBA")
    shadowed_panel(base, box, 34, (17, 22, 28))
    x0, y0, x1, y1 = box
    d.text((x0 + 42, y0 + 38), "Dashboard", font=font(46, "bold"), fill=WHITE)
    d.text((x0 + 42, y0 + 96), "Inventory command center", font=font(25), fill=MUTED)
    cols = 2 if not compact else 1
    card_w = ((x1 - x0 - 84) - (cols - 1) * 24) // cols
    card_h = 150
    metrics = [
        ("Tracked tools", "186", ORANGE),
        ("Inventory value", "\u00a347,860", GREEN),
        ("High value", "42", STEEL),
        ("Need service", "11", YELLOW),
    ]
    cy = y0 + 165
    for i, item in enumerate(metrics):
        col = i % cols
        row = i // cols
        cx = x0 + 42 + col * (card_w + 24)
        draw_metric_card(base, (cx, cy + row * (card_h + 22), cx + card_w, cy + row * (card_h + 22) + card_h), *item)
    list_y = cy + (2 if not compact else 4) * (card_h + 22) + 12
    d.text((x0 + 42, list_y), "Recently added", font=font(31, "bold"), fill=WHITE)
    for i, (name, meta, price, color) in enumerate([
        ("Milwaukee M18 Impact Driver", "Power Tools - Van 2", "\u00a3180", ORANGE),
        ("Fluke 117 Multimeter", "Electrical - Lockup", "\u00a3240", STEEL),
        ("Stihl Cut-Off Saw", "Landscaping - Site A", "\u00a3350", YELLOW),
    ]):
        yy = list_y + 54 + i * 112
        rounded(d, (x0 + 42, yy, x1 - 42, yy + 88), 18, SURFACE_2, (255, 255, 255, 24), 1)
        d.ellipse((x0 + 66, yy + 22, x0 + 110, yy + 66), fill=color + (255,))
        d.text((x0 + 130, yy + 18), name, font=font(25, "semibold"), fill=WHITE)
        d.text((x0 + 130, yy + 51), meta, font=font(20), fill=MUTED)
        d.text((x1 - 150, yy + 29), price, font=font(25, "bold"), fill=WHITE)


def draw_inventory_ui(base, box):
    d = ImageDraw.Draw(base, "RGBA")
    shadowed_panel(base, box, 34, (17, 22, 28))
    x0, y0, x1, y1 = box
    d.text((x0 + 42, y0 + 38), "Inventory", font=font(46, "bold"), fill=WHITE)
    rounded(d, (x0 + 42, y0 + 108, x1 - 42, y0 + 170), 18, SURFACE_2, (255, 255, 255, 18), 1)
    d.text((x0 + 72, y0 + 124), "Search tools, serials, jobsites", font=font(24), fill=MUTED)
    chips = ["Power Tools", "Electrical", "Ladders"]
    x = x0 + 42
    for chip in chips:
        x = pill(d, (x, y0 + 198), chip, (ORANGE if chip == "Power Tools" else SURFACE_2), (BLACK if chip == "Power Tools" else WHITE)) + 12
    rows = [
        ("DEWALT Rotary Hammer", "Serial DW-9031 - Excellent", "\u00a3320", GREEN),
        ("Makita Circular Saw", "Blade due in 9 days - Good", "\u00a3145", STEEL),
        ("Rothenberger Press Tool", "Assigned to Maya - Good", "\u00a3720", ORANGE),
        ("Werner Extension Ladder", "Last seen: Unit 4 - Fair", "\u00a3210", YELLOW),
    ]
    for i, row in enumerate(rows):
        yy = y0 + 282 + i * 126
        rounded(d, (x0 + 42, yy, x1 - 42, yy + 102), 20, SURFACE_2, (255, 255, 255, 28), 1)
        d.rounded_rectangle((x0 + 68, yy + 22, x0 + 128, yy + 82), radius=14, fill=(10, 13, 17))
        d.rectangle((x0 + 88, yy + 36, x0 + 109, yy + 67), fill=row[3])
        d.text((x0 + 150, yy + 20), row[0], font=font(27, "bold"), fill=WHITE)
        d.text((x0 + 150, yy + 56), row[1], font=font(21), fill=MUTED)
        d.text((x1 - 150, yy + 36), row[2], font=font(27, "bold"), fill=WHITE)


def draw_scanner_ui(base, box):
    d = ImageDraw.Draw(base, "RGBA")
    shadowed_panel(base, box, 34, (17, 22, 28))
    x0, y0, x1, y1 = box
    d.text((x0 + 42, y0 + 38), "AI Tool Scanner", font=font(45, "bold"), fill=WHITE)
    photo = (x0 + 42, y0 + 115, x1 - 42, y0 + 470)
    rounded(d, photo, 28, (20, 29, 35), (255, 255, 255, 28), 1)
    # stylized tool photo
    px0, py0, px1, py1 = photo
    d.rounded_rectangle((px0 + 95, py0 + 120, px1 - 180, py0 + 195), radius=22, fill=(44, 52, 58))
    d.rounded_rectangle((px1 - 240, py0 + 98, px1 - 100, py0 + 245), radius=26, fill=ORANGE)
    d.rectangle((px0 + 170, py0 + 95, px0 + 210, py0 + 230), fill=(120, 130, 138))
    d.ellipse((px1 - 205, py0 + 140, px1 - 165, py0 + 180), fill=(8, 12, 16))
    d.text((px0 + 38, py1 - 62), "Photo analysis", font=font(25, "semibold"), fill=MUTED)
    y = y0 + 505
    for label, value, tint in [
        ("Possible category", "Power tool", ORANGE),
        ("Visible wear", "Moderate scuffs", YELLOW),
        ("Condition estimate", "Good", GREEN),
        ("Estimated resale range", "\u00a380 - \u00a3180", STEEL),
    ]:
        rounded(d, (x0 + 42, y, x1 - 42, y + 78), 18, SURFACE_2, (255, 255, 255, 26), 1)
        d.text((x0 + 68, y + 18), label, font=font(20), fill=MUTED)
        d.text((x1 - 340, y + 16), value, font=font(25, "bold"), fill=tint)
        y += 94


def draw_maintenance_ui(base, box):
    d = ImageDraw.Draw(base, "RGBA")
    shadowed_panel(base, box, 34, (17, 22, 28))
    x0, y0, x1, y1 = box
    d.text((x0 + 42, y0 + 38), "Maintenance + Theft", font=font(42, "bold"), fill=WHITE)
    cards = [
        ("Blade Change", "Makita Circular Saw", "Due today", YELLOW),
        ("Calibration", "Fluke 117 Multimeter", "Due in 12 days", STEEL),
        ("Missing Tool Report", "Stihl Cut-Off Saw", "Last known: Site A", RED),
        ("QR / NFC Ready", "Asset label placeholder", "Prepared for rollout", ORANGE),
    ]
    for i, (title, sub, meta, tint) in enumerate(cards):
        yy = y0 + 118 + i * 138
        rounded(d, (x0 + 42, yy, x1 - 42, yy + 112), 22, SURFACE_2, (255, 255, 255, 28), 1)
        d.ellipse((x0 + 72, yy + 30, x0 + 124, yy + 82), fill=tint + (255,))
        d.text((x0 + 148, yy + 22), title, font=font(28, "bold"), fill=WHITE)
        d.text((x0 + 148, yy + 59), sub, font=font(22), fill=MUTED)
        d.text((x1 - 310, yy + 42), meta, font=font(23, "semibold"), fill=tint)


def draw_reports_ui(base, box):
    d = ImageDraw.Draw(base, "RGBA")
    shadowed_panel(base, box, 34, (17, 22, 28))
    x0, y0, x1, y1 = box
    d.text((x0 + 42, y0 + 38), "Reports + Resale", font=font(43, "bold"), fill=WHITE)
    report = (x0 + 78, y0 + 130, x1 - 78, y0 + 520)
    rounded(d, report, 26, (239, 244, 246), None)
    d.text((report[0] + 35, report[1] + 32), "Insurance-ready inventory", font=font(31, "bold"), fill=(20, 24, 28))
    d.rectangle((report[0] + 35, report[1] + 95, report[2] - 35, report[1] + 100), fill=ORANGE)
    for i, line in enumerate(["High-value tools: 42", "Missing assets: 1", "Maintenance cost: \u00a31,240", "Estimated resale: \u00a347,860"]):
        d.text((report[0] + 35, report[1] + 140 + i * 48), line, font=font(24, "semibold"), fill=(41, 49, 56))
    d.text((x0 + 42, y0 + 570), "PDF exports, depreciation trends, and cautious AI value estimates.", font=font(25), fill=MUTED)
    # mini chart
    chart = [(x0 + 62, y0 + 640), (x1 - 62, y0 + 805)]
    rounded(d, (chart[0][0], chart[0][1], chart[1][0], chart[1][1]), 22, SURFACE_2, (255, 255, 255, 28), 1)
    pts = [(chart[0][0] + 30, chart[1][1] - 35), (chart[0][0] + 180, chart[0][1] + 90), (chart[0][0] + 345, chart[0][1] + 70), (chart[1][0] - 40, chart[0][1] + 40)]
    d.line(pts, fill=ORANGE, width=8)
    for px, py in pts:
        d.ellipse((px - 9, py - 9, px + 9, py + 9), fill=WHITE)


def draw_analytics_ui(base, box):
    d = ImageDraw.Draw(base, "RGBA")
    shadowed_panel(base, box, 34, (17, 22, 28))
    x0, y0, x1, y1 = box
    d.text((x0 + 42, y0 + 38), "Analytics + Teams", font=font(43, "bold"), fill=WHITE)
    chart_box = (x0 + 42, y0 + 118, x1 - 42, y0 + 410)
    rounded(d, chart_box, 24, SURFACE_2, (255, 255, 255, 26), 1)
    labels = ["Power", "Electrical", "Ladders", "Safety"]
    values = [230, 175, 125, 90]
    for i, (label, val) in enumerate(zip(labels, values)):
        bx = chart_box[0] + 45 + i * ((chart_box[2] - chart_box[0] - 120) // 4)
        by = chart_box[3] - 48 - val
        rounded(d, (bx, by, bx + 56, chart_box[3] - 48), 16, ORANGE if i == 0 else STEEL)
        d.text((bx - 10, chart_box[3] - 35), label, font=font(17), fill=MUTED)
    rows = [
        ("Assigned to Jordan", "Impact driver - return Friday", ORANGE),
        ("Assigned to Priya", "Inspection kit - Site B", STEEL),
        ("Overdue alert", "Ladder return pending", YELLOW),
    ]
    for i, (title, sub, tint) in enumerate(rows):
        yy = y0 + 450 + i * 118
        rounded(d, (x0 + 42, yy, x1 - 42, yy + 94), 20, SURFACE_2, (255, 255, 255, 28), 1)
        d.ellipse((x0 + 70, yy + 27, x0 + 110, yy + 67), fill=tint + (255,))
        d.text((x0 + 134, yy + 20), title, font=font(26, "bold"), fill=WHITE)
        d.text((x0 + 134, yy + 54), sub, font=font(21), fill=MUTED)


SCREENS = [
    ("01_dashboard", "Know every tool's value", "See total inventory value, high-value assets, maintenance risks, and missing-tool alerts at a glance.", draw_dashboard_ui),
    ("02_inventory", "Build a clean asset register", "Track category, brand, model, serial number, condition, storage location, assigned worker, photos, and notes.", draw_inventory_ui),
    ("03_ai_scanner", "Scan tools with cautious AI", "Upload or capture a photo to get possible category, visible wear, condition estimate, and resale range guidance.", draw_scanner_ui),
    ("04_maintenance_theft", "Reduce loss and downtime", "Log servicing, set reminders, mark missing tools, and prepare serial-number exports for reports.", draw_maintenance_ui),
    ("05_reports_resale", "Export reports that look ready", "Generate inventory, high-value, missing-tool, maintenance, insurance-ready, and resale summary PDFs.", draw_reports_ui),
    ("06_analytics_team", "Run teams with accountability", "Understand depreciation, maintenance costs, category mix, and worker assignments across jobsites.", draw_analytics_ui),
]


def make_phone_screenshot(name, title, subtitle, ui_drawer, size=(1242, 2688), folder="iPhone_6_5", suffix="iphone_65"):
    w, h = size
    im = screenshot_base((w, h))
    d = ImageDraw.Draw(im, "RGBA")
    margin = max(82, int(w * 0.066))
    title_block(d, title, subtitle, w, int(h * 0.032), margin, w / 1242)
    ui_drawer(im, (margin - 6, int(h * 0.307), w - margin + 6, h - int(h * 0.047)))
    path = ASSET_ROOT / folder / f"{name}_{suffix}.png"
    im.convert("RGB").save(path, quality=96)
    return path


def make_ipad_screenshot(name, title, subtitle, ui_drawer, size=(2048, 2732), folder="iPad_12_9", suffix="ipad_129"):
    w, h = size
    im = screenshot_base((w, h))
    d = ImageDraw.Draw(im, "RGBA")
    scale = w / 1896
    margin = max(120, int(w * 0.058))
    title_block(d, title, subtitle, w, int(h * 0.033), margin, scale)
    panel_top = int(h * 0.269)
    gutter = int(w * 0.043)
    left = (margin, panel_top, int(w * 0.478), h - int(h * 0.048))
    right = (int(w * 0.521), panel_top, w - margin, h - int(h * 0.048))
    draw_dashboard_ui(im, left, compact=True)
    ui_drawer(im, right)
    path = ASSET_ROOT / folder / f"{name}_{suffix}.png"
    im.convert("RGB").save(path, quality=96)
    return path


def make_subscription_square(filename, title, price, subtitle, features, promo=False):
    size = 1024
    im = screenshot_base((size, size))
    d = ImageDraw.Draw(im, "RGBA")
    draw_toolvault_mark(d, 64, 58, 96)
    d.text((182, 70), "ToolVault AI", font=font(38, "bold"), fill=WHITE)
    d.text((182, 120), "Subscription preview", font=font(22), fill=MUTED)
    shadowed_panel(im, (64, 210, 960, 914), 34, (17, 22, 28))
    d.text((108, 258), title, font=font(55, "black"), fill=WHITE)
    d.text((108, 328), subtitle, font=font(27), fill=MUTED)
    d.text((108, 410), price, font=font(66, "black"), fill=ORANGE)
    y = 510
    for item in features:
        d.ellipse((116, y + 8, 144, y + 36), fill=GREEN)
        d.line((123, y + 23, 131, y + 31, 141, y + 14), fill=BLACK, width=4)
        d.text((166, y), item, font=font(26, "semibold"), fill=WHITE)
        y += 56
    d.rounded_rectangle((108, 820, 916, 878), radius=18, fill=ORANGE)
    d.text((408, 834), "Continue", font=font(27, "bold"), fill=BLACK)
    subdir = "SubscriptionPromotional" if promo else "SubscriptionReview"
    path = ASSET_ROOT / subdir / filename
    im.convert("RGB").save(path, quality=96)
    return path


def make_subscription_review_screenshot(filename, title, price, subtitle, features):
    w, h = 1242, 2688
    im = screenshot_base((w, h))
    d = ImageDraw.Draw(im, "RGBA")
    margin = 82
    title_block(
        d,
        f"{title} review screen",
        f"{subtitle}. Shows the subscription option exactly as App Review will see it in the ToolVault AI paywall.",
        w,
        86,
        margin,
        1,
    )

    panel = (76, 825, w - 76, h - 125)
    shadowed_panel(im, panel, 34, (17, 22, 28))
    x0, y0, x1, y1 = panel
    d.text((x0 + 42, y0 + 42), "ToolVault AI Paywall", font=font(42, "bold"), fill=WHITE)
    d.text((x0 + 42, y0 + 96), "Subscription review preview", font=font(24), fill=MUTED)

    card = (x0 + 42, y0 + 175, x1 - 42, y0 + 1005)
    rounded(d, card, 30, SURFACE_2, (255, 255, 255, 34), 2)
    d.text((card[0] + 42, card[1] + 42), title, font=font(56, "black"), fill=WHITE)
    d.text((card[0] + 42, card[1] + 112), subtitle, font=font(28), fill=MUTED)
    d.text((card[0] + 42, card[1] + 198), price, font=font(66, "black"), fill=ORANGE)

    y = card[1] + 330
    for item in features:
        d.ellipse((card[0] + 52, y + 8, card[0] + 88, y + 44), fill=GREEN)
        d.line((card[0] + 62, y + 27, card[0] + 72, y + 38, card[0] + 84, y + 17), fill=BLACK, width=5)
        d.text((card[0] + 112, y), item, font=font(31, "semibold"), fill=WHITE)
        y += 72

    button_top = y + 34
    d.rounded_rectangle((card[0] + 42, button_top, card[2] - 42, button_top + 70), radius=22, fill=ORANGE)
    d.text((card[0] + 390, button_top + 18), "Continue", font=font(31, "bold"), fill=BLACK)

    disclaimer = (
        "Review note: no sign-in is required. Subscription entitlement state is simulated locally for review. "
        "AI resale values are informational estimates only, not insurance valuations or financial advice."
    )
    rounded(d, (x0 + 42, y0 + 1060, x1 - 42, y0 + 1260), 24, (20, 29, 35), (255, 255, 255, 28), 1)
    draw_wrapped(d, disclaimer, (x0 + 76, y0 + 1095), font(26), MUTED, x1 - x0 - 152, 10)

    path = ASSET_ROOT / "SubscriptionReview" / filename
    im.convert("RGB").save(path, quality=96)
    return path


def make_marketing_icon() -> Image.Image:
    size = 1024
    im = Image.new("RGBA", (size, size), CHARCOAL + (255,))
    d = ImageDraw.Draw(im, "RGBA")
    for y in range(size):
        t = y / size
        d.line([(0, y), (size, y)], fill=(int(10 + 12 * t), int(13 + 15 * t), int(17 + 18 * t), 255))
    overlay_grid(im, 16)
    d.polygon([(760, 0), (1024, 0), (830, 1024), (606, 1024)], fill=(250, 106, 22, 54))
    d.polygon([(0, 790), (248, 720), (440, 1024), (0, 1024)], fill=(62, 124, 160, 58))
    d.rectangle((0, 990, 1024, 1024), fill=(250, 106, 22, 190))
    d.rectangle((0, 970, 390, 1024), fill=(62, 124, 160, 190))
    shadowed_panel(im, (164, 164, 860, 860), 168, (18, 24, 30), (255, 255, 255, 34))
    draw_toolvault_mark(d, 258, 206, 508)
    d.rounded_rectangle((338, 724, 686, 804), radius=40, fill=ORANGE)
    d.text((421, 736), "AI", font=font(58, "black"), fill=BLACK)
    return im


def generate_icons():
    icon = make_marketing_icon()
    base_path = ASSET_ROOT / "Marketing" / "toolvault_ai_icon_1024.png"
    icon.convert("RGB").save(base_path, quality=96)
    entries = []
    specs = [
        ("iphone", "20x20", 2), ("iphone", "20x20", 3),
        ("iphone", "29x29", 2), ("iphone", "29x29", 3),
        ("iphone", "40x40", 2), ("iphone", "40x40", 3),
        ("iphone", "60x60", 2), ("iphone", "60x60", 3),
        ("ipad", "20x20", 1), ("ipad", "20x20", 2),
        ("ipad", "29x29", 1), ("ipad", "29x29", 2),
        ("ipad", "40x40", 1), ("ipad", "40x40", 2),
        ("ipad", "76x76", 1), ("ipad", "76x76", 2),
        ("ipad", "83.5x83.5", 2),
        ("ios-marketing", "1024x1024", 1),
    ]
    for idiom, size_str, scale in specs:
        points = float(size_str.split("x")[0])
        pixels = int(points * scale)
        filename = f"AppIcon-{idiom}-{size_str.replace('.', '_')}@{scale}x.png"
        if idiom == "ios-marketing":
            filename = "AppIcon-1024.png"
        resized = icon.resize((pixels, pixels), Image.Resampling.LANCZOS)
        resized.convert("RGB").save(ICON_SET / filename, quality=96)
        entries.append({
            "idiom": idiom,
            "size": size_str,
            "scale": f"{scale}x",
            "filename": filename,
        })
    (ICON_SET / "Contents.json").write_text(json.dumps({"images": entries, "info": {"author": "xcode", "version": 1}}, indent=2), encoding="utf-8")


def main():
    ensure_dirs()
    generated = []
    generate_icons()
    for screen in SCREENS:
        generated.append(make_phone_screenshot(*screen, size=(1320, 2868), folder="iPhone_6_9", suffix="iphone_69"))
        generated.append(make_phone_screenshot(*screen))
        generated.append(make_ipad_screenshot(*screen, size=(2064, 2752), folder="iPad_13", suffix="ipad_13"))
        generated.append(make_ipad_screenshot(*screen))
    generated.append(make_subscription_review_screenshot(
        "toolvault_ai_pro_monthly_review.png",
        "Pro Monthly",
        "\u00a312.99 / month",
        "Unlimited inventory intelligence",
        ["Unlimited tools", "AI scanner", "PDF exports", "Resale tracking", "Theft reports"],
    ))
    generated.append(make_subscription_review_screenshot(
        "toolvault_ai_pro_yearly_review.png",
        "Pro Yearly",
        "\u00a399.99 / year",
        "Annual Pro access",
        ["Unlimited tools", "AI scanner", "Maintenance reminders", "PDF exports", "Resale tracking"],
    ))
    generated.append(make_subscription_review_screenshot(
        "toolvault_ai_business_monthly_review.png",
        "Business Monthly",
        "\u00a349.99 / month",
        "Team-ready asset management",
        ["Team assignments", "Advanced reports", "Custom branding", "Multi-user placeholder", "Bulk import placeholder"],
    ))
    generated.append(make_subscription_square(
        "toolvault_ai_pro_monthly_promo.png",
        "Pro Monthly",
        "\u00a312.99 / month",
        "Upgrade every tool workflow",
        ["AI scanner", "Maintenance reminders", "PDF exports", "Resale tracking"],
        promo=True,
    ))
    generated.append(make_subscription_square(
        "toolvault_ai_business_monthly_promo.png",
        "Business Monthly",
        "\u00a349.99 / month",
        "Built for crews and contractors",
        ["Team assignments", "Advanced reports", "Custom branding", "Bulk import placeholder"],
        promo=True,
    ))
    print("Generated assets:")
    for path in generated:
        print(path.relative_to(ROOT))


if __name__ == "__main__":
    main()
