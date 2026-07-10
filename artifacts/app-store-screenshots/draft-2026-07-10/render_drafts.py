from pathlib import Path
from typing import Optional

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parent
CANVAS = (1320, 2868)
FONT_PATH = "/System/Library/Fonts/Hiragino Sans GB.ttc"


def font(size: int, index: int = 0) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_PATH, size=size, index=index)


def gradient(colors: tuple[tuple[int, int, int], tuple[int, int, int]]) -> Image.Image:
    top, bottom = colors
    result = Image.new("RGB", CANVAS)
    pixels = result.load()
    for y in range(CANVAS[1]):
        t = y / (CANVAS[1] - 1)
        row = tuple(round(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        for x in range(CANVAS[0]):
            pixels[x, y] = row
    return result


def centered_lines(
    draw: ImageDraw.ImageDraw,
    lines: list[str],
    y: int,
    text_font: ImageFont.FreeTypeFont,
    fill: str,
    spacing: int,
) -> int:
    current_y = y
    for line in lines:
        box = draw.textbbox((0, 0), line, font=text_font)
        width = box[2] - box[0]
        draw.text(((CANVAS[0] - width) / 2, current_y), line, font=text_font, fill=fill)
        current_y += spacing
    return current_y


def rounded_screenshot(base: Image.Image, screenshot_path: Path, box: tuple[int, int, int, int]) -> None:
    x, y, width, height = box
    source = Image.open(screenshot_path).convert("RGB")
    source = source.resize((width, height), Image.Resampling.LANCZOS)

    shadow_mask = Image.new("L", CANVAS, 0)
    shadow_draw = ImageDraw.Draw(shadow_mask)
    shadow_draw.rounded_rectangle(
        (x, y + 24, x + width, y + height + 24),
        radius=72,
        fill=120,
    )
    shadow = Image.new("RGBA", CANVAS, (72, 57, 105, 0))
    shadow.putalpha(shadow_mask.filter(ImageFilter.GaussianBlur(34)))
    base.paste(shadow, (0, 0), shadow)

    mask = Image.new("L", (width, height), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, width, height), radius=72, fill=255)
    base.paste(source, (x, y), mask)


def render_page(
    filename: str,
    screenshot: str,
    headline: list[str],
    subtitle: str,
    colors: tuple[tuple[int, int, int], tuple[int, int, int]],
    footnote: Optional[str] = None,
    draft_note: Optional[str] = None,
) -> None:
    image = gradient(colors)
    draw = ImageDraw.Draw(image)
    ink = "#363049"
    muted = "#7B7488"
    accent = "#8F82B7"

    draw.text((1100, 62), "DRAFT", font=font(28), fill=accent)
    headline_bottom = centered_lines(draw, headline, 115, font(72, index=0), ink, 102)

    subtitle_box = draw.textbbox((0, 0), subtitle, font=font(36))
    subtitle_width = subtitle_box[2] - subtitle_box[0]
    draw.text(((CANVAS[0] - subtitle_width) / 2, headline_bottom + 28), subtitle, font=font(36), fill=muted)

    screenshot_y = 680 if len(headline) <= 2 else 720
    if footnote:
        footnote_box = draw.textbbox((0, 0), footnote, font=font(28))
        footnote_width = footnote_box[2] - footnote_box[0]
        draw.text(((CANVAS[0] - footnote_width) / 2, headline_bottom + 84), footnote, font=font(28), fill=accent)
        screenshot_y = 740

    rounded_screenshot(image, ROOT / screenshot, (185, screenshot_y, 950, 2059))

    if draft_note:
        note_font = font(28)
        note_box = draw.textbbox((0, 0), draft_note, font=note_font)
        note_width = note_box[2] - note_box[0]
        pill_x = (CANVAS[0] - note_width) / 2 - 34
        pill_y = 2750
        draw.rounded_rectangle(
            (pill_x, pill_y, pill_x + note_width + 68, pill_y + 70),
            radius=35,
            fill="#FFFFFF",
        )
        draw.text((pill_x + 34, pill_y + 17), draft_note, font=note_font, fill=accent)

    image.save(ROOT / filename, format="PNG", optimize=True)


render_page(
    "01-home.png",
    "IMG_5376.png",
    ["グッズ交換相手にも、", "近くの趣味友にも", "めぐりあえる"],
    "交換と近くの交流を、ひとつのアプリで",
    ((246, 242, 255), (237, 249, 252)),
)

render_page(
    "02-match.png",
    "IMG_5377.png",
    ["交換相手探しを、", "もっとかんたんに"],
    "在庫とWishから、条件に合う候補を自動で見つける",
    ((239, 248, 253), (248, 239, 255)),
)

render_page(
    "03-cutout.png",
    "IMG_5379.png",
    ["指で切り抜いて、", "そのまま募集ポストへ"],
    "登録したグッズから、投稿画像と文面を自動作成",
    ((255, 242, 247), (243, 239, 255)),
    draft_note="完成した投稿画像を後から追加",
)

render_page(
    "04-meguri.png",
    "IMG_5380.png",
    ["近くの趣味友と、", "ふわっと交流"],
    "グルームやチャットルームで気軽につながる",
    ((235, 249, 252), (242, 239, 255)),
    footnote="※正確な現在地は表示されません",
)
