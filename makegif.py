from os import listdir, path, system
import sys
from random import shuffle
import argparse

parser = argparse.ArgumentParser(description='Make a gif from a folder of images using ImageMagick')
parser.add_argument('folderName', type=str, help='Name of the folder under the output folder')
parser.add_argument('-d', '--delay', dest='delay', type=int, help='Delay between each frame of output GIF', default=10)
parser.add_argument('-r', '--reverse', action='store_true', help='Reverse the frames at the end, creating a smooth loop')
parser.add_argument('-s', '--shuffle', action='store_true', help='Shuffle frames in random order')
args = parser.parse_args()

reverseIt = args.reverse
shuffleIt = args.shuffle
delay = args.delay
imageName = args.folderName

imagePath = path.join('output', imageName)
imageFiles = [path.join(imagePath, f) for f in listdir(imagePath) if f.endswith('.png')]
if reverseIt and len(imageFiles) > 1 :
    imageFiles += reversed(imageFiles[1:-1])
if shuffleIt:
    shuffle(imageFiles)

outputFile = path.join('gifs', imageName + '.gif')
command = 'convert -delay ' + str(delay) + ' ' + ' '.join(imageFiles) + ' ' + outputFile
print(command)
system(command)
