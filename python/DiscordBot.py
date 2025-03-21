import discord
import os
import TestModule
from PIL import Image, ImageFile, ImageDraw, ImageFont
from io import BytesIO

TOKEN = ""

bot = discord.Bot(intents = discord.Intents.all())

TEMP_PNG_PATH = os.path.join(os.path.dirname(__file__), "temp.png")

async def testA(imageFile: ImageFile, message: discord.Message):
	descriptionLiness = []

	lines = message.content.splitlines()
	lineCount = len(lines)

	index = 0

	while(index < lineCount):
		if "#場所" in lines[index]:
			location = lines[index+1]
			index += 2

		if "#名前" in lines[index]:
			name = lines[index+1]
			index += 2

		if "#種族" in lines[index]:
			speciesName = lines[index+1]
			index += 2

		if "#説明" in lines[index]:
			index += 1
			descriptionLines = []

			while((index < lineCount) and (not("#" in lines[index]))):
				descriptionLines.append(lines[index])
				index += 1

			descriptionLiness.append(descriptionLines)

	mainImage: Image = TestModule.huwaTest(imageFile, location, name, speciesName, descriptionLiness)
	mainImage.save(TEMP_PNG_PATH)

	await message.channel.send(file = discord.File(TEMP_PNG_PATH, name + ".png"))

@bot.event
async def on_ready():
	print("Bot Start")

@bot.event
async def on_message(message: discord.Message):
	if message.author.bot:
		return

	if message.channel.name != "bot_room":
		return

	if message.attachments:
		attachment = message.attachments[0]
		
		if attachment.filename.lower().endswith(("png", "jpg", "jpeg")):
			try:
				imageData = await attachment.read()
				imageFile: ImageFile = Image.open(BytesIO(imageData))
				await testA(imageFile, message)
			except Exception as e:
				await message.reply(e)

bot.run(TOKEN)