# 1024    = 8+500+8+500+8
# 256 * 3 = 8+330+8+330+8+76+8
# 330     = 6+250+6+62+6
# 500     = 6+250+6+232+6

import os
from PIL import Image, ImageFile, ImageDraw, ImageFont

fontFileName = 
fontPath = os.path.join(os.path.dirname(__file__), fontFileName)

F_KEMOCAST_NAME = ImageFont.truetype(fontPath, 60)  # ケモキャスト名
F_KEMOCAST_SPECIES = ImageFont.truetype(fontPath, 24)  # ケモキャスト種族名
F_KEMOCATS_DESC = ImageFont.truetype(fontPath, 18)  # ケモキャスト説明

SPACING_BEFORE = 16  # 種族名の上の余白
SPACING_AFTER = 16  # 種族名の下の余白
DESC_LINE_SPACING = 2  # 行間の余白
DESC_PARAGRAPH_SPACING = 8  # バレット項目間の追加余白

STRIKE_THROUGH_THICKNESS = 2  # 取り消し線の幅
KEMOCAST_NAME_THICK = 4 # ケモキャスト名の縁取りの太さ

C_KEMOCAST_DESC_RECT = (255, 226, 207) # ケモキャスト説明の背景色
C_KEMOCAST_NAME_RECT = (243, 116, 116) # ケモキャスト名前の背景色
C_KEMOCAST_NAME_STROKE = (120, 25, 56) # ケモキャスト名の縁の色

C_KEMOCAST_NAME = "white" # ケモキャスト名の文字色
C_KEMOCAST_SPECIES = "black" # ケモキャスト種族名の文字色
C_KEMOCAST_DESC = "black" # ケモキャスト説明の文字色
C_STRIKE_THROUGH = "black" # 取り消し線の色



def draw_strikethrough(draw: ImageDraw, fontSize: int, startX: int, endX: int, y: int):
	strike_through_color = (0, 0, 0)
	lineY = y + fontSize / 2
	offset = STRIKE_THROUGH_THICKNESS

	draw.line([(startX, lineY - offset), (endX, lineY - offset)], fill=C_STRIKE_THROUGH, width=STRIKE_THROUGH_THICKNESS)
	draw.line([(startX, lineY + offset), (endX, lineY + offset)], fill=C_STRIKE_THROUGH, width=STRIKE_THROUGH_THICKNESS)

def huwaTest(imageFile: ImageFile, location: str, name: str, speciesName: str, descriptionLiness: list[list[str]]):
	# 準備
	mainImage: Image = Image.new("RGB", (500, 330), (0xFF, 0xFF, 0xFF))
	draw: ImageDraw = ImageDraw.Draw(mainImage)

	speciesFontSize: int = F_KEMOCAST_SPECIES.size
	descriptionFontSize: int = F_KEMOCATS_DESC.size
	bulletSize: int = draw.textbbox((0, 0), "・", font = F_KEMOCATS_DESC)[2]

	if "猛獣" in location:
		C_KEMOCAST_DESC_RECT = (255, 226, 207) # ケモキャスト説明の背景色
		C_KEMOCAST_NAME_RECT = (243, 116, 116) # ケモキャスト名前の背景色
		C_KEMOCAST_NAME_STROKE = (120, 25, 56) # ケモキャスト名の縁の色

	if "もふもふ" in location:
		C_KEMOCAST_DESC_RECT = (202, 235, 189) # ケモキャスト説明の背景色
		C_KEMOCAST_NAME_RECT = (79, 191, 34) # ケモキャスト名前の背景色
		C_KEMOCAST_NAME_STROKE = (50, 109, 27) # ケモキャスト名の縁の色

	if "みずべ" in location:
		C_KEMOCAST_DESC_RECT = (218, 236, 255) # ケモキャスト説明の背景色
		C_KEMOCAST_NAME_RECT = (148, 201, 255) # ケモキャスト名前の背景色
		C_KEMOCAST_NAME_STROKE = (27, 31, 109) # ケモキャスト名の縁の色



	# 説明文と名前の背景にある長方形を描画
	draw.rectangle([6+250+6, 6, 500-6-1, 6+250-1], fill = C_KEMOCAST_DESC_RECT)
	draw.rectangle([6, 6+250+6, 500-6-1, 330-6-1], fill = C_KEMOCAST_NAME_RECT)

	# 種族名を描画
	offsetY: int = 6+SPACING_BEFORE
	draw.text((6+250+6+232/2, offsetY), "【" + speciesName + "】", font = F_KEMOCAST_SPECIES, fill = C_KEMOCAST_SPECIES, anchor = "ma")
	offsetY += speciesFontSize + SPACING_AFTER

	# 説明文を描画
	strikethrough: bool = False
	strikethroughX: int = 0

	for descriptionLines in descriptionLiness:
		draw.text((6+250+6+6, offsetY), "・", font = F_KEMOCATS_DESC, fill = C_KEMOCAST_DESC)

		for descriptionLine in descriptionLines:
			offsetX = 6+250+6+6 + bulletSize

			for char in descriptionLine:
				if char == "~":
					strikethrough = not strikethrough

					if strikethrough:
						strikethroughX = offsetX
					else:
						draw_strikethrough(draw, descriptionFontSize, strikethroughX, offsetX, offsetY)

					continue
				
				# 自動改行
				charWidth: int = draw.textbbox((0, 0), char, font = F_KEMOCATS_DESC)[2]
				
				if (offsetX + charWidth) > (6+250+6+232-6):
					if strikethrough:
						draw_strikethrough(draw, descriptionFontSize, strikethroughX, offsetX, offsetY)
						strikethroughX = 6+250+6+6 + bulletSize

					offsetX = 6+250+6+6 + bulletSize
					offsetY += descriptionFontSize + DESC_LINE_SPACING
				
				# 1文字描画
				color = (0x80, 0x80, 0x80) if strikethrough else C_KEMOCAST_DESC
				draw.text((offsetX, offsetY), char, font = F_KEMOCATS_DESC, fill = color)
				offsetX += charWidth
			
			offsetY += descriptionFontSize + DESC_LINE_SPACING
		
		offsetY += DESC_PARAGRAPH_SPACING

	# 名前を描画
	draw.text((500/2, 6+250+6+62/2), name, font = F_KEMOCAST_NAME, fill = C_KEMOCAST_NAME, anchor="mm", stroke_width = KEMOCAST_NAME_THICK, stroke_fill = C_KEMOCAST_NAME_STROKE)

	# 画像を描画
	mainImage.paste(imageFile.resize((250, 250)), (6, 6))

	return mainImage