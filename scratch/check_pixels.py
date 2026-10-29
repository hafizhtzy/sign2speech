from PIL import Image

img = Image.open('scratch/after_swipe.png')
print('Size:', img.size)
for y in range(0, img.size[1], 50):
    row = [img.getpixel((x, y)) for x in range(0, img.size[0], 50)]
    non_white = [c for c in row if c[:3] != (255, 255, 255)]
    if non_white:
        print(f'Y={y}: {len(non_white)} non-white pixels, sample={non_white[0]}')

