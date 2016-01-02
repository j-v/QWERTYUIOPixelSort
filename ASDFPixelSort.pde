int mode = 1;

//MODE:
//0 -> black
//1 -> bright
//2 -> white
//b(16777216)

PImage srcImg;
PImage img;
String imgFileName = "chris-interlaken";
String fileType = "jpg";

int maxDimension = 700; // Max width or height, to resize source image
boolean rotateSource = true;

boolean loopable = true; // make a loopable video. doubles number of frames
int minThreshold = 40;
int maxThreshold = 200;
int numFrames = 25;
boolean decrementThreshold = true; //starts from maxThreshold descending to minThreshold instead of vice versa

boolean columnsFirst = true;

int threshold = 0;
int blackValue = -10000000;
int brightnessValue = 60;
int whiteValue = -6000000;

int row = 0;
int column = 0;

boolean saved = false;

void setup() {
  srcImg = loadImage(imgFileName+"."+fileType); 
  if (rotateSource)
  {
    srcImg = getRotatedImage(srcImg, true);
  }
  
  // Resize if necessary
  boolean widthGreatest = srcImg.width > srcImg.height;
  int maxDim = max(srcImg.width, srcImg.height);
  if (maxDim > maxDimension)
  {
    // Need to resize
    float ratio = (float)maxDimension / (float)maxDim;
    srcImg.resize((int)(ratio * srcImg.width), (int)(ratio * srcImg.height));
  }
  
  size(srcImg.width, srcImg.height);
  image(srcImg, 0, 0); // TODO necessary?
  img = createImage(srcImg.width, srcImg.height, RGB);
}

PImage getRotatedImage(PImage image, boolean counterClockwise)
{
  PImage rotated = createImage(image.height, image.width, RGB);
  rotated.loadPixels();
  image.loadPixels();
  for (int x = 0; x < image.width; x++)
  {
    for (int y = 0; y < image.height; y++)
    {
      if (counterClockwise)
      {
        rotated.pixels[y + x * rotated.width] = image.pixels[x + (image.height - 1 - y) * image.width];
      }
      else
      {
        rotated.pixels[y + x * rotated.width] = image.pixels[image.width - 1 - x + y * image.width];
      }
    }
  }
  rotated.updatePixels();
  return rotated;
}

void draw() {
  
  int actualFrame = frameCount;
  // Render loop
  if (!loopable) {
    if (frameCount > numFrames) { System.exit(0); }
  }
  else
  {
    if (frameCount > numFrames)
    {
      actualFrame = numFrames - (frameCount - numFrames);
      if (actualFrame < 1) { System.exit(0); }      
    }
  }
  // TODO allow exponential curve
  // TODO factor out into delta and increment/decrement
  if (decrementThreshold)
  {
    brightnessValue = (int)((float)minThreshold + ((float)(maxThreshold - minThreshold + 1) / (float)(numFrames)) * (float)(numFrames - (actualFrame-1))); // TODO only works for brightness mode
  }
  else
  {
    brightnessValue = (int)((float)minThreshold + ((float)(maxThreshold - minThreshold + 1) / (float)(numFrames)) * (float)(actualFrame-1)); // TODO only works for brightness mode
  } 
  println(brightnessValue);
  
  img.copy(srcImg, 0, 0, srcImg.width, srcImg.height, 0, 0, srcImg.width, srcImg.height);
  
  // TODO make these vars not global
  row = 0;
  column = 0;
  
  if (columnsFirst)
  {
    drawColumns();
    drawRows();
  }
  else
  {
    drawRows();
    drawColumns();
  }
  String outFile = getOutputFileName();
  
  image(img,0,0);
  saveFrame(outFile); // TODO could use img.save() instead https://processing.org/reference/PImage_save_.html
  println("Saved " + outFile);
  
//  if(!saved && frameCount >= loops) {
//    saveFrame(outFile);
//    saved = true;
//    println("DONE"+frameCount);
//    println("Saved " + outFile);
//    System.exit(0); 
//  }
}

String getOutputFileName() {
  switch(mode) {
      case 0:
        threshold = blackValue;
        break;
      case 1:
        threshold = brightnessValue;
        break;
      case 2:
        threshold = whiteValue;
        break;
      default:
        break;
    }
  String outputDir = "output";
  String outputFileExt = "png";
  return String.format("%s/%s/%03d_%s_m%d_t%d.%s",
   outputDir, 
   imgFileName, 
   frameCount,
   imgFileName, 
   mode, 
   threshold, 
   outputFileExt);
}

void drawColumns() {
  while(column < width-1) {
    img.loadPixels(); 
    sortColumn();
    column++;
    img.updatePixels();
  }
}

void drawRows() {
  while(row < height-1) {
    img.loadPixels(); 
    sortRow();
    row++;
    img.updatePixels();
  }
}

void sortRow() {
  int x = 0;
  int y = row;
  int xend = 0;
  
  while(xend < width-1) {
    switch(mode) {
      case 0:
        x = getFirstNotBlackX(x, y);
        xend = getNextBlackX(x, y);
        break;
      case 1:
        x = getFirstBrightX(x, y);
        xend = getNextDarkX(x, y);
        break;
      case 2:
        x = getFirstNotWhiteX(x, y);
        xend = getNextWhiteX(x, y);
        break;
      default:
        break;
    }
    
    if(x < 0) break;
    
    int sortLength = xend-x;
    
    color[] unsorted = new color[sortLength];
    color[] sorted = new color[sortLength];
    
    for(int i=0; i<sortLength; i++) {
      unsorted[i] = img.pixels[x + i + y * img.width];
    }
    
    sorted = sort(unsorted);
    
    for(int i=0; i<sortLength; i++) {
      img.pixels[x + i + y * img.width] = sorted[i];      
    }
    
    x = xend+1;
  }
}


void sortColumn() {
  int x = column;
  int y = 0;
  int yend = 0;
  
  while(yend < height-1) {
    switch(mode) {
      case 0:
        y = getFirstNotBlackY(x, y);
        yend = getNextBlackY(x, y);
        break;
      case 1:
        y = getFirstBrightY(x, y);
        yend = getNextDarkY(x, y);
        break;
      case 2:
        y = getFirstNotWhiteY(x, y);
        yend = getNextWhiteY(x, y);
        break;
      default:
        break;
    }
    
    if(y < 0) break;
    
    int sortLength = yend-y;
    
    color[] unsorted = new color[sortLength];
    color[] sorted = new color[sortLength];
    
    for(int i=0; i<sortLength; i++) {
      unsorted[i] = img.pixels[x + (y+i) * img.width];
    }
    
    sorted = sort(unsorted);
    
    for(int i=0; i<sortLength; i++) {
      img.pixels[x + (y+i) * img.width] = sorted[i];
    }
    
    y = yend+1;
  }
}

//BLACK
// TODO a lot of duplicattion in all the getFirst* and getNext* functions
int getFirstNotBlackX(int _x, int _y) {
  int x = _x;
  int y = _y;
  color c;
  while((c = img.pixels[x + y * img.width]) < blackValue) {
    x++;
    if(x >= width) return -1;
  }
  return x;
}

int getNextBlackX(int _x, int _y) {
  int x = _x+1;
  int y = _y;
  color c;
  while((c = img.pixels[x + y * img.width]) > blackValue) {
    x++;
    if(x >= width) return width-1;
  }
  return x-1;
}

//BRIGHTNESS
int getFirstBrightX(int _x, int _y) {
  int x = _x;
  int y = _y;
  color c;
  while(brightness(c = img.pixels[x + y * img.width]) < brightnessValue) {
    x++;
    if(x >= width) return -1;
  }
  return x;
}

int getNextDarkX(int _x, int _y) {
  int x = _x+1;
  int y = _y;
  color c;
  while(brightness(c = img.pixels[x + y * img.width]) > brightnessValue) {
    x++;
    if(x >= width) return width-1;
  }
  return x-1;
}

//WHITE
int getFirstNotWhiteX(int _x, int _y) {
  int x = _x;
  int y = _y;
  color c;
  while((c = img.pixels[x + y * img.width]) > whiteValue) {
    x++;
    if(x >= width) return -1;
  }
  return x;
}

int getNextWhiteX(int _x, int _y) {
  int x = _x+1;
  int y = _y;
  color c;
  while((c = img.pixels[x + y * img.width]) < whiteValue) {
    x++;
    if(x >= width) return width-1;
  }
  return x-1;
}


//BLACK
int getFirstNotBlackY(int _x, int _y) {
  int x = _x;
  int y = _y;
  color c;
  if(y < height) {
    while((c = img.pixels[x + y * img.width]) < blackValue) {
      y++;
      if(y >= height) return -1;
    }
  }
  return y;
}

int getNextBlackY(int _x, int _y) {
  int x = _x;
  int y = _y+1;
  color c;
  if(y < height) {
    while((c = img.pixels[x + y * img.width]) > blackValue) {
      y++;
      if(y >= height) return height-1;
    }
  }
  return y-1;
}

//BRIGHTNESS
int getFirstBrightY(int _x, int _y) {
  int x = _x;
  int y = _y;
  color c;
  if(y < height) {
    while(brightness(c = img.pixels[x + y * img.width]) < brightnessValue) {
      y++;
      if(y >= height) return -1;
    }
  }
  return y;
}

int getNextDarkY(int _x, int _y) {
  int x = _x;
  int y = _y+1;
  color c;
  if(y < height) {
    while(brightness(c = img.pixels[x + y * img.width]) > brightnessValue) {
      y++;
      if(y >= height) return height-1;
    }
  }
  return y-1;
}

//WHITE
int getFirstNotWhiteY(int _x, int _y) {
  int x = _x;
  int y = _y;
  color c;
  if(y < height) {
    while((c = img.pixels[x + y * img.width]) > whiteValue) {
      y++;
      if(y >= height) return -1;
    }
  }
  return y;
}

int getNextWhiteY(int _x, int _y) {
  int x = _x;
  int y = _y+1;
  color c;
  if(y < height) {
    while((c = img.pixels[x + y * img.width]) < whiteValue) {
      y++;
      if(y >= height) return height-1;
    }
  }
  return y-1;
}
