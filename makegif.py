from os import listdir, path, system
import sys

def printUsage():
    print('TODO')

if len(sys.argv) < 2:
    printUsage()
    exit(0)


    
imageName = sys.argv[1]
imagePath = path.join('output', imageName)
imageFiles = [path.join(imagePath, f) for f in listdir(imagePath) if f.endswith('.png')]
imageFiles += reversed(imageFiles)

outputFile = path.join('gifs', imageName + '.gif')
command = 'convert ' + ' '.join(imageFiles) + ' ' + outputFile
print(command)
system(command)
