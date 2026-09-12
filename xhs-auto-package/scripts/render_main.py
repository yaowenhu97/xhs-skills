#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""商品主图：关键词 + 卜诗上岸喵模板（无损擦除“考公考编”替换为关键词，保留“备考资料”及所有设计元素）"""
import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# 卜诗上岸喵原图（保留全部设计元素，仅擦除并替换首行“考公考编”）
TEMPLATE = Path(r"C:\Users\root\.qoder-cn\skills\xhs-product-creator\assets\main-template\卜诗上岸喵-original.jpg")
FONT = Path(r"C:\Windows\Fonts\simhei.ttf")
KW = os.environ.get("KW", "黑龙江定向选调生")
if os.environ.get("OUT_DIR"):
    OUT = Path(os.environ["OUT_DIR"]) / "1.jpg"
else:
    OUT = Path(r"C:\Users\root\Desktop") / f"{KW}_商品包" / "主图" / f"{KW}_主图.jpg"

# 标题区（只擦第一行红色“考公考编”，替换为关键词；保留下方“备考资料”及底部详情页条）
TITLE_RECT = (250, 300, 1800, 560)   # x0,y0,x1,y1  覆盖考公考编(324-538)并加边距彻底擦净
TITLE_CY = 430
MAX_W, MAX_H = 1800, 232   # 关键词自适应，字号更大、占满标题区（10字≈176px）
TEXT_COLOR = (240, 40, 10)     # 橙红外框同“备考资料”/期望效果
STROKE_W = 3                # 加粗（干净中粗，非重描边）
# 字号自适应（字数越少越大；fit 递减找最大适配）
S_BY_LEN = {1:300,2:290,3:280,4:270,5:258,6:242,7:228,8:214,9:198,10:186,11:172,12:160,13:150,14:140,15:132,16:125,17:118,18:112,19:106,20:100}

def clean_template():
    """米白卡色 (250,249,245) 固定填充 + 高斯模糊，无痕擦除原“考公考编”"""
    im = Image.open(TEMPLATE).convert("RGB")
    draw = ImageDraw.Draw(im)
    x0, y0, x1, y1 = TITLE_RECT
    draw.rectangle([x0, y0, x1, y1], fill=(250, 249, 245))
    im.paste(im.crop(TITLE_RECT).filter(ImageFilter.GaussianBlur(1.0)), (x0, y0))
    return im

def fit_font(draw, text, start):
    for size in range(start, 19, -1):
        f = ImageFont.truetype(str(FONT), size)
        b = draw.textbbox((0,0), text, font=f, stroke_width=STROKE_W)
        if b[2]-b[0] <= MAX_W and b[3]-b[1] <= MAX_H:
            return f, b, size
    f = ImageFont.truetype(str(FONT), 20)
    b = draw.textbbox((0,0), text, font=f, stroke_width=STROKE_W)
    return f, b, 20

im = clean_template()
draw = ImageDraw.Draw(im)
n = len(KW)
# 统一从大字号开始，fit 递减找到「填满但不超标题区」的最大字号（长词也能到 ~110px 融洽）
start = S_BY_LEN.get(n, 250) if n <= 20 else 250
font, box, size = fit_font(draw, KW, start)
w, h = box[2]-box[0], box[3]-box[1]
cx = (TITLE_RECT[0] + TITLE_RECT[2]) // 2
pos = (cx - w/2 - box[0], TITLE_CY - h/2 - box[1])
draw.text(pos, KW, font=font, fill=TEXT_COLOR, stroke_width=STROKE_W)
OUT.parent.mkdir(parents=True, exist_ok=True)
im.save(OUT, format="JPEG", quality=96, subsampling=0)
print(f"[主图] {OUT} ({size}px)")