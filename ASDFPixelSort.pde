import controlP5.*;
ControlP5 cp5;

// UI variables
int controlPaneWidth = 500;

int mode = 0;

//MODE:
//0 -> brighter
//1 -> darker

PImage srcImg;
PImage img;
String imgFileName = "beautiful-lake";
String fileType = "jpg";

int maxDimension = 1600; // Max width or height, to resize source image
boolean rotateSource = false;

float startThreshold = 255;
float endThreshold = 0;
int numFrames = 1;

boolean columnsFirst = true;

float brightnessThreshold = 0;

int row = 0;
int column = 0;

boolean saved = false;

void setup() {
  size(400, 400);
  initControls();
  
  loadSourceImage(imgFileName+"."+fileType);
  renderImage();
}

void loadSourceImage(String filePath)
{
  //srcImg = loadImage(imgFileName+"."+fileType); 
  srcImg = loadImage(filePath);
  imgFileName = filePath.substring(0, filePath.lastIndexOf("."));
  if (rotateSource)
  {
    srcImg = getRotatedImage(srcImg, true);
  }
  
  // Resize if necessary
  int maxDim = max(srcImg.width, srcImg.height);
  if (maxDim > maxDimension)
  {
    // Need to resize
    float ratio = (float)maxDimension / (float)maxDim;
    srcImg.resize((int)(ratio * srcImg.width), (int)(ratio * srcImg.height));
  }
  
  surface.setResizable(true);
  surface.setSize(srcImg.width + controlPaneWidth, srcImg.height);
  
  img = createImage(srcImg.width, srcImg.height, RGB);
}

void initControls()
{
  cp5 = new ControlP5(this);
    
  cp5.addButton("openFile")
    .setPosition(0, 0);
  cp5.addSlider("thresholdChanged")
    .setPosition(0, 40)
    .setRange(0, 255)
    .setTriggerEvent(Slider.RELEASE)
    .setCaptionLabel("Threshold")
    .setSize(400,20)
    .setValue(brightnessThreshold);  
  cp5.addToggle("modeChanged")
    .setPosition(0, 70)
    .setSize(50, 20)
    .setCaptionLabel("Mode")
    .setValue(mode == 1);    
  cp5.addToggle("sortOrderChanged")
    .setPosition(70, 70)
    .setSize(50,20)
    .setCaptionLabel("Sort Order")
    .setValue(columnsFirst);
    
  cp5.addTextlabel("sequenceLabel")
    .setText("Sequence controls")
    .setPosition(0, 120);
  cp5.addSlider("startThreshold")
    .setPosition(0, 140)
    .setRange(0, 255)
    .setSize(400,20)
    .setValue(startThreshold);  
  cp5.addSlider("endThreshold")
    .setPosition(0, 170)
    .setRange(0, 255)
    .setSize(400,20)
    .setValue(endThreshold);  
  cp5.addTextfield("numFramesText")
    .setPosition(0, 200)
    .setSize(200, 40)
    .setInputFilter(ControlP5.INTEGER)
    .setCaptionLabel("number of frames")
    .setText(Integer.toString(numFrames))
    .setAutoClear(false);
  cp5.addBang("saveSequencePressed")
    .setPosition(0, 260)
    .setSize(40,40)
    .setCaptionLabel("Save Sequence");
}

void thresholdChanged(float theValue)
{
  brightnessThreshold = theValue;
  renderImage();
}

void modeChanged(boolean theValue)
{
  mode = theValue ? 1 : 0; 
  renderImage();
}

void sortOrderChanged(boolean theValue)
{
  columnsFirst = theValue;
  renderImage();
}

void openFile(int theValue)
{
  selectInput("Select an image", "fileSelected");
}

void fileSelected(File file)
{
  loadSourceImage(file.getPath());
  renderImage();
}

void saveSequencePressed()
{
  numFrames = Integer.parseInt(cp5.get(Textfield.class,"numFramesText").getText());
  saveSequence(startThreshold, endThreshold, numFrames);
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
  background(0);
  image(img, controlPaneWidth, 0);
}

void renderImage()
{ 
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
}

void saveSequence(float thresholdStart, float thresholdEnd, int numFrames)
{
  float delta = (thresholdEnd - thresholdStart) / (float)(numFrames - 1);
  for (int i = 0; i < numFrames; i++)
  {
    brightnessThreshold = thresholdStart + delta * (float)i;
    renderImage();
    String outFile = getOutputFileName(i);
    img.save(outFile);
    println("Saved " + outFile);
  }
}

String getOutputFileName(int frameNum) {
  String outputDir = "output";
  String outputFileExt = "png";
  return String.format("%s/%s/%03d_%s_m%d_t%.2f.%s",
   outputDir, 
   imgFileName, 
   frameNum,
   imgFileName, 
   mode,
   brightnessThreshold, 
   outputFileExt);
}

void drawColumns() {
  while(column < img.width-1) {
    img.loadPixels(); 
    sortColumn();
    column++;
    img.updatePixels();
  }
}

void drawRows() {
  while(row < img.height-1) {
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
  
  while(xend < img.width-1) {
    switch(mode) {
      case 0:
        x = getFirstBrightX(x, y);
        xend = getNextDarkX(x, y);
        break;
      case 1:
        x = getFirstDarkX(x, y);
        xend = getNextBrightX(x, y);
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
  
  while(yend < img.height-1) {
    switch(mode) {
      case 0:
        y = getFirstBrightY(x, y);
        yend = getNextDarkY(x, y);
        break;
      case 1:
        y = getFirstDarkY(x, y);
        yend = getNextBrightY(x, y);
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

//BRIGHTNESS Mode 0
int getFirstBrightX(int _x, int _y) {
  int x = _x;
  int y = _y;
  while(brightness(img.pixels[x + y * img.width]) < brightnessThreshold) {
    x++;
    if(x >= img.width) return -1;
  }
  return x;
}

int getNextDarkX(int _x, int _y) {
  int x = _x+1;
  int y = _y;
  while(brightness(img.pixels[x + y * img.width]) > brightnessThreshold) {
    x++;
    if(x >= img.width) return img.width-1;
  }
  return x-1;
}

int getFirstBrightY(int _x, int _y) {
  int x = _x;
  int y = _y;
  if(y < img.height) {
    while(brightness(img.pixels[x + y * img.width]) < brightnessThreshold) {
      y++;
      if(y >= img.height) return -1;
    }
  }
  return y;
}

int getNextDarkY(int _x, int _y) {
  int x = _x;
  int y = _y+1;
  if(y < img.height) {
    while(brightness(img.pixels[x + y * img.width]) > brightnessThreshold) {
      y++;
      if(y >= img.height) return img.height-1;
    }
  }
  return y-1;
}

//BRIGHTNESS Mode 1
int getFirstDarkX(int _x, int _y) {
  int x = _x;
  int y = _y;
  while(brightness(img.pixels[x + y * img.width]) > brightnessThreshold) {
    x++;
    if(x >= width) return -1;
  }
  return x;
}

int getNextBrightX(int _x, int _y) {
  int x = _x+1;
  int y = _y;
  while(brightness(img.pixels[x + y * img.width]) < brightnessThreshold) {
    x++;
    if(x >= width) return width-1;
  }
  return x-1;
}

int getFirstDarkY(int _x, int _y) {
  int x = _x;
  int y = _y;
  if(y < img.height) {
    while(brightness(img.pixels[x + y * img.width]) > brightnessThreshold) {
      y++;
      if(y >= height) return -1;
    }
  }
  return y;
}

int getNextBrightY(int _x, int _y) {
  int x = _x;
  int y = _y+1;
  if(y < img.height) {
    while(brightness(img.pixels[x + y * img.width]) < brightnessThreshold) {
      y++;
      if(y >= height) return height-1;
    }
  }
  return y-1;
}