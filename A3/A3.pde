import java.util.Arrays;
import processing.svg.*;

PFont f;
PFont g;
Table table; //list of links
PVector[] nodes; //list of nodes
PVector[] node_forces; //list of nodes
int [][] node_colours;
int num_nodes = 0;
int num_links = 0;
Float[] a, b;
float n = 20;
int weight = 3;

float leftBorder;
float rightBorder;
float topBorder;
float bottomBorder;
boolean mouseIsPressed = false;
float prePressX, prePressY, postPressX, postPressY, diffX, diffY;
float pressX, pressY, releaseX, releaseY;
float zoomLevel = 1;
float randomBuffer = 30;
float border = 30;
float displacment;

float minEdgesSlider;
float minKCoresSlider;

int maxEdges;
int maxKCores;
int edgesToShow;
int kCoresToShow;
int lastKCoresToShow = 0;

int[] globalEdgesKCore;

int[] edgesPerNode;
Table[] subTables;
int totalTables;

Table currentTable;
int currTable = 1;
int lastCurrTable = 1;

boolean[][] adjacencyMatrix, matrixHighlight;

ArrayList<boolean[]> kCores;
boolean[] kCore;

int options = 4;

String mode = "search";
String filtrationMode = "edges";

int holder = 50;

int[] tableMaxKCore = new int[7];

void setup()
{
  //beginRecord(SVG, "Assignment3_picture.svg");
  f=createFont("Arial", 10);
  g=loadFont("Dubai-Bold-28.vlw");
  textFont(f);
  textAlign(CENTER, CENTER);
  fullScreen();
  leftBorder = 20;
  rightBorder = width - 1000 + 20;
  topBorder = 20;
  bottomBorder = height - 20;

  table = loadTable("Data\\aves-wildbird-network\\birds.csv");
  //table = loadTable("Data\\aves-songbird-social\\birds.csv");
  num_links = table.getRowCount();
  for (TableRow row : table.rows())
  {
    int n1 = row.getInt(0);
    int n2 = row.getInt(1);
    num_nodes = max(num_nodes, n1);
    num_nodes = max(num_nodes, n2);
  }
  edgesPerNode = new int[num_nodes];
  for (TableRow row : table.rows())
  {
    int n1 = row.getInt(0)-1;
    int n2 = row.getInt(1)-1;
    edgesPerNode[n1]++;
    edgesPerNode[n2]++;
  }
  node_colours = new int[num_nodes][3];
  nodes = new PVector[num_nodes];
  node_forces = new PVector[num_nodes];
  for (int i=0; i<num_nodes; i++)
  {
    //randomize for now, so we can see
    for (int j = 0; j < 3; j++) node_colours[i][j] = int(random(100, 255));
    nodes[i]= new PVector(random(width - leftBorder - 40) - (width - leftBorder - 40)/2, random(height - topBorder - 40 - topBorder) - (height - topBorder - 40 - topBorder)/2);
    node_forces[i] = new PVector(random(width-10), random(height-10));
  }

  adjacencyMatrix = adjacencyMatrix(table);
  minEdgesSlider = rightBorder + 12 * border;
  minKCoresSlider = rightBorder + 12 * border;


  maxEdges = maxEdges(edgesPerNode);
  maxKCores = 100;

  totalTables = -1;
  try {
    for (TableRow row : table.rows())
    {
      int tab = row.getInt(3);
      totalTables = max(tab, totalTables);
    }
  }
  catch(ArrayIndexOutOfBoundsException exception)
  {
    println("Error: no subtables");
  }
  if (totalTables != -1)
  {
    subTables = new Table[totalTables];
    for (int i = 0; i < subTables.length; i++)
    {
      subTables[i] = new Table();
    }
    for (TableRow row : table.rows())
    {
      subTables[row.getInt(3) - 1].addRow(row);
    }
  }
  if (currTable == 0) kCore = findKCores(table, holder);
  else kCore = findKCores(subTables[currTable - 1], holder);
  
  for(int i = 0; i < tableMaxKCore.length; i++)
  {
    boolean finished = false;
    int j = 0;
    boolean[] holderArray;
    while(!finished)
    {
      finished = true;
      if(i == 0) holderArray = findKCores(table, j);
      else holderArray = findKCores(subTables[i-1], j);
      
      for(int k = 0; k < holderArray.length; k++)
      {
      if(holderArray[k] == true)
      {
        finished = false;
        j++;
        break;
      }

      }
    }
    tableMaxKCore[i] = j;
  }
}

void draw()
{
  holder = kCoresToShow;
  if (currTable == 0) currentTable = table;
  else currentTable = subTables[currTable-1];
  //adjacencyMatrix = adjacencyMatrix(currentTable);
  background(255);
  drawGraph(currentTable);
  boundryBoxes();
  if ( rightBorder < width - border - 30)
  {
    drawMatrix();
  }
  if (rightBorder < 1400)
  {
    radioButton();
  }
  if (currTable != lastCurrTable)
  {
    if (currTable == 0)
    {
      kCore = findKCores(table, holder);
      adjacencyMatrix = adjacencyMatrix(table);
    } else {
      kCore = findKCores(subTables[currTable - 1], holder);
      adjacencyMatrix = adjacencyMatrix(subTables[currTable - 1]);
    }
  }
  int lastCurrTable = currTable;
  if (currTable == 0)
  {
    adjacencyMatrix = adjacencyMatrix(table);
  }
  if (kCoresToShow != lastKCoresToShow)
  {
    if (currTable == 0)
    {
      kCore = findKCores(table, holder);
    } else {
      kCore = findKCores(subTables[currTable - 1], holder);
    }
    lastKCoresToShow = kCoresToShow;
  }
  //endRecord();
}

void drawGraph(Table currentTable)
{
  strokeWeight(1);
  for (TableRow row : currentTable.rows())
  {
    int n1 = row.getInt(0)-1;
    int n2 = row.getInt(1)-1;
    stroke(0, 100);
    stroke((node_colours[n1][0]+node_colours[n2][0])/2, (node_colours[n1][1]+node_colours[n2][1])/2, (node_colours[n1][2]+node_colours[n2][2])/2);
    if (filtrationMode == "edges")
    {
      if (edgesPerNode[n1] >= edgesToShow && edgesPerNode[n2] >= edgesToShow)
      {
        strokeWeight(row.getFloat(2) * 10);
        if (n1 == closest) line(mouseX, mouseY, allEffects((nodes[n2].x + leftBorder) * ((rightBorder)/width), postPressX, true) + (width/2 * ((rightBorder)/width)), allEffects(nodes[n2].y + topBorder, postPressY, false)+ (height/2 * ((bottomBorder)/height)));
        else if (n2 == closest) line(allEffects((nodes[n1].x + leftBorder) * ((rightBorder)/width), postPressX, true) + (width/2 * ((rightBorder)/width)), allEffects(nodes[n1].y + topBorder, postPressY, false) + (height/2 * ((bottomBorder)/height)), mouseX, mouseY);
        else line(allEffects((nodes[n1].x + leftBorder) * ((rightBorder)/width), postPressX, true) + (width/2 * ((rightBorder)/width)), allEffects(nodes[n1].y + topBorder, postPressY, false) + (height/2 * ((bottomBorder)/height)), allEffects((nodes[n2].x + leftBorder) * ((rightBorder)/width), postPressX, true) + (width/2 * ((rightBorder)/width)), allEffects(nodes[n2].y + topBorder, postPressY, false)+ (height/2 * ((bottomBorder)/height)));
      }
    } else if (filtrationMode == "kcores")
    {
      if (kCore[n1] && kCore[n2])
      {
        strokeWeight(row.getFloat(2) * 10);
        if (n1 == closest) line(mouseX, mouseY, allEffects((nodes[n2].x + leftBorder) * ((rightBorder)/width), postPressX, true) + (width/2 * ((rightBorder)/width)), allEffects(nodes[n2].y + topBorder, postPressY, false)+ (height/2 * ((bottomBorder)/height)));
        else if (n2 == closest) line(allEffects((nodes[n1].x + leftBorder) * ((rightBorder)/width), postPressX, true) + (width/2 * ((rightBorder)/width)), allEffects(nodes[n1].y + topBorder, postPressY, false) + (height/2 * ((bottomBorder)/height)), mouseX, mouseY);
        else line(allEffects((nodes[n1].x + leftBorder) * ((rightBorder)/width), postPressX, true) + (width/2 * ((rightBorder)/width)), allEffects(nodes[n1].y + topBorder, postPressY, false) + (height/2 * ((bottomBorder)/height)), allEffects((nodes[n2].x + leftBorder) * ((rightBorder)/width), postPressX, true) + (width/2 * ((rightBorder)/width)), allEffects(nodes[n2].y + topBorder, postPressY, false)+ (height/2 * ((bottomBorder)/height)));
      }
    }
  }
  strokeWeight(1);

  for (int i=0; i<num_nodes; i++)
  {
    if (filtrationMode == "edges")
    {
      if (edgesPerNode[i] >= edgesToShow)
      {
        fill(node_colours[i][0], node_colours[i][1], node_colours[i][2]);
        stroke(0);
        if (closest!=-1 && i == closest) ellipse(mouseX, mouseY, 40, 40);
        else ellipse(allEffects((nodes[i].x + leftBorder) * (rightBorder/width), postPressX, true) + (width/2 * ((rightBorder)/width)), allEffects(nodes[i].y + topBorder, postPressY, false)+ (height/2 * ((bottomBorder)/height)), 20, 20);
        noStroke();
        fill(0);
        if (closest!=-1 && i == closest) text(i+1, mouseX, mouseY);
        else text(i+1, allEffects((nodes[i].x + leftBorder) * (rightBorder/width), postPressX, true) + (width/2 * ((rightBorder)/width)), allEffects(nodes[i].y + topBorder, postPressY, false)+ (height/2 * ((bottomBorder)/height)));
      }
    } else
    {
      if (kCore[i])
      {
        fill(node_colours[i][0], node_colours[i][1], node_colours[i][2]);
        stroke(0);
        if (closest!=-1 && i == closest) ellipse(mouseX, mouseY, 40, 40);
        else ellipse(allEffects((nodes[i].x + leftBorder) * (rightBorder/width), postPressX, true) + (width/2 * ((rightBorder)/width)), allEffects(nodes[i].y + topBorder, postPressY, false)+ (height/2 * ((bottomBorder)/height)), 20, 20);
        noStroke();
        fill(0);
        if (closest!=-1 && i == closest) text(i+1, mouseX, mouseY);
        else text(i+1, allEffects((nodes[i].x + leftBorder) * (rightBorder/width), postPressX, true) + (width/2 * ((rightBorder)/width)), allEffects(nodes[i].y + topBorder, postPressY, false)+ (height/2 * ((bottomBorder)/height)));
      }
    }
  }
}

void boundryBoxes()
{
  fill(255);
  rect(0, 0, width, topBorder);
  rect(0, 0, leftBorder, height);
  rect(0, bottomBorder, width, height-bottomBorder);
  rect(rightBorder, 0, width-rightBorder, height);
  strokeWeight(0);
  if (mouseX > rightBorder - weight/2 && mouseY > topBorder - weight/2 && mouseX < rightBorder - weight/2 + border/2 + (2 * weight/2) && mouseY < topBorder - weight/2 + bottomBorder-topBorder + (2 * weight/2))
  {
    fill(180);
  } else
  {
    fill(230);
  }
  rect(rightBorder - weight/2, topBorder - weight/2, border/2 + (2 * weight/2), bottomBorder-topBorder + (2 * weight/2), 0, 20, 20, 0);
  fill(0);
  stroke(0);
  strokeWeight(weight);
  line(leftBorder, topBorder, rightBorder, topBorder);
  line(leftBorder, topBorder, leftBorder, bottomBorder);
  line(leftBorder, bottomBorder, rightBorder, bottomBorder);
  line(rightBorder, topBorder, rightBorder, bottomBorder);
}

void drawMatrix()
{
  fill(0);
  //rect(rightBorder + border, height - (width - rightBorder) - 20 + (2 * border), (width - rightBorder - (2 * border)), (width - rightBorder - (2 * border)));
  strokeWeight(1);
  for (int i = 0; i < adjacencyMatrix.length; i++)
  {
    for (int j = 0; j < adjacencyMatrix.length; j++)
    {
      if (adjacencyMatrix[i][j])
      {
        if ((width - rightBorder - (2 * border)) < height/2 - topBorder - (height - bottomBorder))
        {
          rect((rightBorder + border) + ((i * (width - rightBorder - (2 * border)))/adjacencyMatrix.length), height - (width - rightBorder) - 20 + (2 * border) + ((j * (width - rightBorder - (2 * border)))/adjacencyMatrix.length), (width - rightBorder - (2 * border))/adjacencyMatrix.length, (width - rightBorder - (2 * border))/adjacencyMatrix.length);
        } else
        {
          fill(0);
          rect((width - border - height/2) + (i * (height/2)/adjacencyMatrix.length), bottomBorder - height/2 + (j * (height/2)/adjacencyMatrix.length), (height/2)/adjacencyMatrix.length, (height/2)/adjacencyMatrix.length);
        }
      }
    }
  }
}

void radioButton()
{
  fill(210);
  if ((width - rightBorder - (2 * border)) < height/2 - topBorder - (height - bottomBorder))
  {
    displacment = (bottomBorder - topBorder) - ((width - rightBorder) - 20);
  } else {
    displacment = (height/2) - 60;
  }
  rect(rightBorder + border, topBorder, (width - rightBorder) - (2 * border), displacment, 10);
  fill(240);
  textAlign(RIGHT, CENTER);
  textFont(g);
  String[] textOptions = new String[options];
  textOptions[0] = "Search:";
  textOptions[1] = "Click:";
  textOptions[2] = "Edges:";
  textOptions[3] = "K-Cores:";
  for (int i = 0; i < subTables.length + 1; i++)
  {
    //ellipse(rightBorder + (width - rightBorder) - (4 * border) + border, topBorder + ((i * (displacment - 6 * border))/howManyButtons) + 2 * border, 20, 20);
    fill(0);
    if ( i == 0) text("Full Table", rightBorder + ((width - rightBorder) - (4 * border))/2 + border - 20, topBorder + ((i * (displacment - 6 * border))/subTables.length) + 2 * border);
    else text("Table "+(i), rightBorder + ((width - rightBorder) - (4 * border))/2 + border - 20, topBorder + ((i * (displacment - 6 * border))/subTables.length) + 2 * border);
    fill(240);
    ellipse(rightBorder + ((width - rightBorder) - (4 * border))/2 + border, topBorder + ((i * (displacment - 6 * border))/subTables.length) + 2 * border, 20, 20);
  }
  int i = 0;
  for (int j = 0; j < options; j++)
  {
    if (j > 1) i = j;
    else i = j;
    fill(0);
    text(textOptions[j], rightBorder + ((width - rightBorder) - (4 * border)) + border - 20, topBorder + ((i * (displacment - 6 * border))/options) + 2 * border);
    fill(240);
    ellipse(rightBorder + (width - rightBorder) - (4 * border) + border, topBorder + ((i * (displacment - 6 * border))/options) + 2 * border, 20, 20);
  }
  fill(200, 0, 0);
  ellipse(rightBorder + ((width - rightBorder) - (4 * border))/2 + border, topBorder + ((currTable * (displacment - 6 * border))/subTables.length) + 2 * border, 20, 20);
  if (mode == "search") ellipse(rightBorder + ((width - rightBorder) - (4 * border)) + border, topBorder + ((0 * (displacment - 6 * border))/4) + 2 * border, 20, 20);
  else if (mode == "click") ellipse(rightBorder + ((width - rightBorder) - (4 * border)) + border, topBorder + (((displacment - 6 * border))/4) + 2 * border, 20, 20);
  if (filtrationMode == "edges") ellipse(rightBorder + ((width - rightBorder) - (4 * border)) + border, topBorder + ((2 * (displacment - 6 * border))/4) + 2 * border, 20, 20);
  else if (filtrationMode == "kcores") ellipse(rightBorder + ((width - rightBorder) - (4 * border)) + border, topBorder + ((3 * (displacment - 6 * border))/4) + 2 * border, 20, 20);

  fill(0);
  textFont(g);
  textAlign(LEFT);
  text("Minimum Edges:", rightBorder + 1.5 * border, topBorder + displacment - (1 * border) + 20);
  text("Minimum K-Cores:", rightBorder + 1.5 * border, topBorder + displacment - (2 * border) + 20);

  edgesToShow = int(((maxEdges * (((minEdgesSlider - (rightBorder + 10.4 * border) - 50)/(((rightBorder + 10.4 * border - 50) + ((width - rightBorder) - (14 * border)) - 50) - (rightBorder + 10.4 * border)))))));
  kCoresToShow = int(((tableMaxKCore[currTable] * (((minKCoresSlider - (rightBorder + 10.4 * border) - 50)/(((rightBorder + 10.4 * border - 50) + ((width - rightBorder) - (14 * border)) - 50) - (rightBorder + 10.4 * border)))))));

  if (edgesToShow < 0) edgesToShow = 0;
  if (kCoresToShow < 0) kCoresToShow = 0;

  text(edgesToShow, rightBorder + 10.4 * border, topBorder + displacment - (1 * border) + 20);
  text(kCoresToShow, rightBorder + 10.4 * border, topBorder + displacment - (2 * border) + 20);
  fill(240);
  rect(rightBorder + 12 * border, topBorder + displacment - (1 * border), (width - rightBorder) - (14 * border), 20, 10, 10, 10, 10);
  rect(rightBorder + 12 * border, topBorder + displacment - (2 * border), (width - rightBorder) - (14 * border), 20, 10, 10, 10, 10);
  fill(220);
  rect(minEdgesSlider, topBorder + displacment - (1 * border), 100, 20, 10, 10, 10, 10);
  rect(minKCoresSlider, topBorder + displacment - (2 * border), 100, 20, 10, 10, 10, 10);
  textFont(f);
  textAlign(CENTER, CENTER);
}

boolean[][] adjacencyMatrix(Table currentTable)
{
  adjacencyMatrix = new boolean[num_nodes][num_nodes];
  matrixHighlight = new boolean[num_nodes][num_nodes];
  for (TableRow row : currentTable.rows()) {
    int n1 = row.getInt(0)-1;
    int n2 = row.getInt(1)-1;
    adjacencyMatrix[n1][n2] = true;
    adjacencyMatrix[n2][n1] = true;
  }
  return adjacencyMatrix;
}

int closest=-1;
void mousePressed()
  //lock onto the nearest node to mousepointer
{
  if (mouseX < rightBorder && mouseX > leftBorder && mouseY < bottomBorder && mouseY > topBorder)
  {
    if (mode == "click")
    {
      float x, y;
      closest = 0;
      float d = width+height; //any big number will do
      float dtemp;
      for (int i=0; i<num_nodes; i++)
      {
        if (edgesPerNode[i] >= edgesToShow)
        {
          x = allEffects((nodes[i].x + leftBorder) * (rightBorder/width), postPressX, true) + (width/2 * ((rightBorder)/width)) - mouseX;
          y = allEffects(nodes[i].y + topBorder, postPressY, false)+ (height/2 * ((bottomBorder)/height)) - mouseY;
          dtemp = sqrt(x*x + y*y); //distance
          if (dtemp<d)
          {
            d = dtemp; //closest distance
            closest = i; //closest node
          }
        }
      }
    } else if (mode == "search")
    {
      if (!mouseIsPressed)
      {
        prePressX = mouseX;
        prePressY = mouseY;
      }
      mouseIsPressed = true;
    }
  }
  for (int i = 0; i < subTables.length + 1; i++)
  {
    if (mouseX > rightBorder + ((width - rightBorder) - (4 * border))/2 + border - 10 && mouseX < rightBorder + ((width - rightBorder) - (4 * border))/2 + border + 30 && mouseY > topBorder + ((i * (displacment - 6 * border))/subTables.length) + 2 * border - 10 && mouseY < topBorder + ((i * (displacment - 6 * border))/subTables.length) + 2 * border + 30)
    {
      currTable = i;
      fill(0);
    }
  }
  for (int i = 0; i < options; i++)
  {
    if (mouseX > rightBorder + ((width - rightBorder) - (4 * border)) + border - 10 && mouseX < rightBorder + ((width - rightBorder) - (4 * border)) + border + 30 && mouseY > topBorder + ((i * (displacment - 6 * border))/options) + 2 * border - 10 && mouseY < topBorder + ((i * (displacment - 6 * border))/options) + 2 * border + 30)
    {
      if (i == 0)
      {
        mode = "search";
      } else if (i == 1)
      {
        mode = "click";
      } else if (i == 2)
      {
        filtrationMode = "edges";
      } else if (i == 3)
      {
        filtrationMode = "kcores";
      }
    }
  }
}
void mouseDragged()
{
  if (mouseX  + 20 > rightBorder - weight/2 && mouseY > topBorder - weight/2 && mouseX - 20 < rightBorder - weight/2 + border/2 + (2 * weight/2) && mouseY < topBorder - weight/2 + bottomBorder-topBorder + (2 * weight/2))
  {
    if (mouseX > width - 400)
    {
      rightBorder = mouseX - 10;
    } else if (mouseX < leftBorder)
    {
      rightBorder = leftBorder;
    } else
    {
      rightBorder = mouseX - 10;
    }
    float sliderSize = (((rightBorder + 10.4 * border - 50) + ((width - rightBorder) - (14 * border)) - 50) - (rightBorder + 10.4 * border));
    minKCoresSlider = mouseX - 10 + 10.4 * border + 50 + (sliderSize / ((rightBorder + 10.4 * border - 50) + ((width - rightBorder) - (14 * border)) - 50));
    minEdgesSlider = mouseX - 10 + 10.4 * border + 50 + (sliderSize / ((rightBorder + 10.4 * border - 50) + ((width - rightBorder) - (14 * border)) - 50));
  }
  fill(255, 0, 0);
  if (mouseX > rightBorder + 12 * border && mouseX < rightBorder + 12 * border + (width - rightBorder) - (14 * border) && mouseY > topBorder + displacment - (2 * border) && mouseY < topBorder + displacment - (2 * border) + 20)
  {
    if (mouseX - 50 < rightBorder + 12 * border) minKCoresSlider = rightBorder + 12 * border;
    else if (mouseX + 50 > rightBorder + 12 * border + (width - rightBorder) - (14 * border)) minKCoresSlider = rightBorder + 12 * border + (width - rightBorder) - (14 * border) - 100;
    else minKCoresSlider = mouseX - 50;
  }

  //rect(rightBorder + 12 * border, topBorder + displacment - (1 * border), (width - rightBorder) - (14 * border), 20, 10, 10, 10, 10);
  if (mouseX > rightBorder + 12 * border && mouseX < rightBorder + 12 * border + (width - rightBorder) - (14 * border) && mouseY > topBorder + displacment - (1 * border) && mouseY < topBorder + displacment - (1 * border) + 20)
  {
    if (mouseX - 50 < rightBorder + 12 * border) minEdgesSlider = rightBorder + 12 * border;
    else if (mouseX + 50 > rightBorder + 12 * border + (width - rightBorder) - (14 * border)) minEdgesSlider = rightBorder + 12 * border + (width - rightBorder) - (14 * border) - 100;
    else minEdgesSlider = mouseX - 50;
  }
  if (closest!=-1)
  {
    nodes[closest].x = mouseX;
    nodes[closest].y = mouseY;
  }
}
void mouseReleased()
{
  if (mouseX < rightBorder && mouseX > leftBorder && mouseY < bottomBorder && mouseY > topBorder)
  {
    if (mode == "click")
    {
      nodes[closest].x = mouseX - 600;
      nodes[closest].y = mouseY - 600;
      closest = -1;
    } else if (mode == "search")
    {
      if (mouseIsPressed)
      {
        postPressX += pmouseX - prePressX;
        postPressY += pmouseY - prePressY;
      }
      mouseIsPressed = false;
    }
  }
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  zoomLevel = zoomLevel - (0.1 * e);
}

float allEffects(float x, float y, boolean isX)
{
  if (mouseIsPressed)
  {
    if (isX)
    {
      return (x * zoomLevel) + y  + pmouseX - prePressX;
    } else
    {
      return (x * zoomLevel) + y  + pmouseY - prePressY;
    }
  } else
  {
    return (x * zoomLevel) + y;
  }
}

int maxEdges(int[] edgesPerNode)
{
  int maxEdges = -1;
  for (int i = 0; i < edgesPerNode.length; i++)
  {
    if (edgesPerNode[i] > maxEdges) maxEdges = edgesPerNode[i];
  }
  if (maxEdges < 0) println("Error: maxEdges less than 0");
  return maxEdges;
}

boolean[] findKCores(Table tbl, int kCores)
{
  boolean nothingChanged = false;
  int rows = tbl.getRowCount();
  boolean[] nodeInKCore = new boolean[rows];
  Arrays.fill(nodeInKCore, true);
  int[] edgesPerNodeInTbl = new int [rows];
  while (!nothingChanged)
  {
    nothingChanged = true;
    edgesPerNodeInTbl = new int [rows];
    for (TableRow row : tbl.rows())
    {
      int n1 = row.getInt(0)-1;
      int n2 = row.getInt(1)-1;
      if (nodeInKCore[n1] && nodeInKCore[n2])
      {
        edgesPerNodeInTbl[n1]++;
        edgesPerNodeInTbl[n2]++;
      }
    }
    for (int i = 0; i < edgesPerNodeInTbl.length; i++)
    {
      if (edgesPerNodeInTbl[i] < kCores && nodeInKCore[i])
      {
        nothingChanged = false;
        nodeInKCore[i] = false;
      }
    }
  }
  globalEdgesKCore = edgesPerNodeInTbl;
  return nodeInKCore;
}
