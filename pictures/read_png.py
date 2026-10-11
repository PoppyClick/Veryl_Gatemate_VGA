from PIL import Image
import binascii

input = 'dvd.png'
output = 'dvd.mem' 

img = Image.open(input).convert('L')
data = list(img.get_flattened_data(0))  

print(f"Size of img: {img.size}")
print(f"Size of data: {len(data)}")

i = 0

with open(output, "w") as file:
    for pixel in data:
        file.write(f"{int(pixel/16):04b} ")
        i+=1
    while i < 4095:
        file.write(f"{0:04b} ")
        i+=1


print(f"Number of data written: {i}")