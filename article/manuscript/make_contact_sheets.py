#!/usr/bin/env python3
"""Create temporary contact sheets for manual DOCX-render inspection."""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw


def page_number(path: Path) -> int:
    return int(path.stem.split("-")[-1])


def main(source: str, destination: str):
    pages = sorted(Path(source).glob("page-*.png"), key=page_number)
    out = Path(destination)
    out.mkdir(parents=True, exist_ok=True)
    for index in range(0, len(pages), 4):
        group = pages[index:index + 4]
        sheet = Image.new("RGB", (1240, 1620), "white")
        draw = ImageDraw.Draw(sheet)
        for number, page in enumerate(group):
            image = Image.open(page).convert("RGB")
            image.thumbnail((590, 750))
            x = 20 + (number % 2) * 620
            y = 20 + (number // 2) * 800
            draw.text((x, y), page.name, fill="black")
            sheet.paste(image, (x, y + 28))
        sheet.save(out / f"sheet_{index // 4 + 1}.png")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
