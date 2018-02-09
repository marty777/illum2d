
class droppedLight {
  PVector pos;
  color c;
  
  droppedLight(PVector pos, color c) {
    this.pos = pos;
    this.c = c; 
  }
}

class rayCaster {
    int h;
    int w;
    int griddivisionsX;
    int griddivisionsY;
    boolean[] obst;
    
    color mouseColor;
    ArrayList<droppedLight> lights;
    color[] bakedillum;
    
    rayCaster(int w, int h, int griddivisionsX, int griddivisionsY, float cutoff) {
      this.mouseColor = color(255, 255, 255);
      lights = new ArrayList<droppedLight>();
      this.h = h;
      this.w = w;
      this.griddivisionsX = griddivisionsX;
      this.griddivisionsY = griddivisionsY;
      this.obst = new boolean[this.h*this.w];
      for(int x = 0; x < this.w; x++) {
        for(int y = 0; y < this.h; y++) { 
          if(random(1.0) < cutoff) {
           obst[x + (y *this.w)] = true; 
          }
          else {
           obst[x + (y *this.w)] = false;
          }
        }
      }
      
     this.bakedillum = new color[this.h*this.w*griddivisionsX*griddivisionsY];
     this.bakeLights();
    }
    
    void reset(float cutoff) {
      
       while(lights.size() > 0) {
        lights.remove(0); 
      }
      
      for(int x = 0; x < this.w; x++) {
        for(int y = 0; y < this.h; y++) { 
          if(random(1) < cutoff) {
           obst[x + (y *this.w)] = true; 
          }
          else {
           obst[x + (y *this.w)] = false;
          }
        }
      }
      
      
      
    }
    
    float localCoordsX(float x) {
      return x * this.w/width; 
    }
    
    float localCoordsY(float y) {
      return y * this.h/height; 
    }
    
    float screenCoordsX(float x) {
      return x * width/this.w; 
    }
    
    float screenCoordsY(float y) {
      return y * height/this.h; 
    }
    
    float diffMag(PVector a, PVector b) {
     return sqrt(diffMagSq(a,b)); 
    }
    
    float diffMagSq(PVector a, PVector b) {
      return ((a.x - b.x)*(a.x - b.x)) + ((a.y - b.y)*(a.y - b.y));
    }
    
    float fastInverseSqrt(float x) {
      float xhalf = 0.5f * x;
      int i = Float.floatToIntBits(x);
      i = 0x5f3759df - (i >> 1);
      x = Float.intBitsToFloat(i);
      x *= (1.5f - xhalf * x * x);
      return x;
    }
    
    
    boolean lookup(int x, int y) {
      if(x < 0 || x >= this.w || y < 0 || y >= this.h) {
         return false;
      } 
      return this.obst[x + (this.w * y)];
    }
    
    boolean intersects(float x, float y) {
     return intersects(new PVector(x, y)); 
    }
    
    // if point is within or on border of wall
    boolean intersects(PVector point) {
      
      if(lookup((int)floor(point.x), (int)floor(point.y)) ) {
         return true; 
      }
      
      if(point.y == round(point.y)) {
        if(lookup((int) floor(point.x), (int)point.y - 1)) {
          return true; 
        }
      }
      
      if(point.x == round(point.x)) {
        if(lookup((int) point.x - 1, (int)floor(point.y))) {
          return true; 
        }
      }
      return false;
    }
    
    // DDA raycast
    // does the ray strike an obstacle or not
    boolean rayCast(PVector source, PVector dest) {
      return rayCast(source, dest, false, false);
    }
    
    boolean rayCast(PVector source, PVector dest, boolean debug) {
      return rayCast(source, dest, debug, false);
    }
    
    boolean rayCast(PVector source, PVector dest, boolean debug, boolean verbosedebug) {
      
      if(debug) {
        this.drawLine(source, dest);
         this.drawVect(source); 
         this.drawVect(dest);
      }
      if(verbosedebug){println("Raycasting from " + source + " to " + dest);}
      
      if(intersects(source) || intersects(dest)) {
        return true; 
      }
      
      PVector dir = new PVector(dest.x - source.x, dest.y - source.y);
      
      // horizontal test - only check intersections with x-axis (vertical) grid lines
      PVector intersect = new PVector(0,0);
      PVector dIntersect = new PVector(0.0,0.0);
      if(abs(floor(dest.x) - floor(source.x)) > 0) {
        if(dir.x < 0) {
          intersect.x = floor(source.x);
        }
        else {
          intersect.x = ceil(source.x);
        }
        intersect.y = source.y + (dir.y*(intersect.x - source.x)/dir.x);
        if(debug) {this.drawVect(intersect);}
        if(verbosedebug){println(intersect);}
        
        // test if intersection
        if(intersects(intersect)) {
          if(verbosedebug){println("Horizontal intersect first test matches: " + intersect);}
          if(debug){this.drawVect(intersect, color(255, 255,0));}
           return true; 
        }
        else {
          if(debug) {this.drawVect(intersect);}
        }
        
        dIntersect = new PVector(1.0, (dir.y)/dir.x);
        if(dir.x < 0) {
          dIntersect.x = -dIntersect.x; 
        }
        if((dir.y < 0 && dIntersect.y > 0) || (dir.y > 0 && dIntersect.y < 0)) {
          dIntersect.y = -dIntersect.y;
        }
        
        if(verbosedebug){println("Horzontal dir: " + dIntersect);}
        intersect.add(dIntersect);
        
        int i = 0;
        while(diffMagSq(source, intersect) < diffMagSq(source, dest)) {
          
          if(verbosedebug){println("Horizintal intersect " + i + ":"+ intersect);}
          if(intersects(intersect)) {
            if(verbosedebug){println("Intersects");}
            if(debug){this.drawVect(intersect, color(255, 255,0));}
            return true; 
          }
          else {
            if(debug) {this.drawVect(intersect);}
          }
          intersect.add(dIntersect);
          i++;
        }
      }
      
     // vertical check
      if(abs(floor(dest.y) - floor(source.y)) > 0) {
        if(dir.y < 0) {
          intersect.y = floor(source.y);
        }
        else {
          intersect.y = ceil(source.y);
        }
        intersect.x = source.x + (dir.x*(intersect.y - source.y)/dir.y);
        
        // test if intersection
        if(intersects(intersect)) {
          if(debug){this.drawVect(intersect, color(0, 255,255));}
          if(verbosedebug){println("Vertical intersect first test matches:" + intersect);}
           return true; 
        }
        else {
          if(debug) {this.drawVect(intersect);}
        }
        
        dIntersect = new PVector((dir.x)/dir.y, 1.0);
        if((dir.x < 0 && dIntersect.x > 0) || (dir.x > 0 && dIntersect.x < 0) ) {
           dIntersect.x = -dIntersect.x; 
        }
        if(dir.y < 0) {
           dIntersect.y = -dIntersect.y; 
        }
        if(verbosedebug){println("Vertical dir: " + dIntersect);}
        
        intersect.add(dIntersect);
        
       int i = 0;
        while(diffMagSq(source, intersect) < diffMagSq(source, dest)) {
          if(verbosedebug){println("Vertical intersect " + i + ":"+ intersect);}
          if(intersects(intersect)) {
            if(debug){this.drawVect(intersect, color(0,255,255));}
            if(verbosedebug){println("Intersects");}
            return true; 
          }
          else {
            if(debug) {this.drawVect(intersect);}
          
          }
          intersect.add(dIntersect);
          i++;
        }
     }
     return false;
    }
    
    int fastRed(color c) {
      return ((c >> 16) & 0xFF); 
    }
    
    int fastGreen(color c) {
      return ((c >> 8) & 0xFF);
    }
    
    int fastBlue(color c) {
      return (c & 0xFF);
    }
    
    // in local coordinates
    void drawVect(PVector a) {
      drawVect(a, color(255,0,0)); 
    }
    
    void drawVect(PVector a, color c) {
      fill(c);
      ellipseMode(RADIUS);
      ellipse(this.screenCoordsX(a.x), this.screenCoordsY(a.y), 5, 5);
    }
    
    void drawLine(PVector a, PVector b) {
      stroke(0,255,0);
      line(this.screenCoordsX(a.x), this.screenCoordsY(a.y), this.screenCoordsX(b.x), this.screenCoordsY(b.y));
    }
    
    color luminance(PVector source, PVector dest, color c) {
       if(rayCast(source, dest)) {
        return color(0,0,0);
      }
      else {
        // good old fast inverse square root plus a scaling factor
        float inverseDistance = 0.5*fastInverseSqrt(diffMag(source,dest));
        return color(fastRed(c) * inverseDistance, fastGreen(c)* inverseDistance, fastBlue(c)* inverseDistance); 
      }
    }
    
    float luminance(PVector source, PVector dest, float intensity) {
      if(rayCast(source, dest)) {
        return 0.0;
      }
      else {
        return intensity/diffMagSq(source,dest); 
      }
    }
    
    void bakeLights() {
      float gridincx = 1.0/this.griddivisionsX;
      float gridincy = 1.0/this.griddivisionsY;
      
      if(this.lights.size() == 0) {
        for(int i = 0; i < this.h*this.w*griddivisionsX*griddivisionsY; i++) {
         this.bakedillum[i] = 0;
        } 
        return;
      }
      
      for(int i = 0; i < this.w; i++) {
       for(int j = 0; j < this.h; j++)  {
          if(lookup(i, j)) {
            continue; 
          }
          
          int x1 = 0;
          int y1 = 0;
          for(float x = i; x < i+1; x+=gridincx) {
            
            for(float y = j; y < j+1; y+= gridincy) {
              
              int red = 0;
              int blue = 0;
              int green = 0;
              
              for(int l = 0; l < lights.size(); l++) {
                droppedLight light = lights.get(l);
                color tl = luminance(light.pos, new PVector(x, y), light.c);
                color tr = luminance(light.pos, new PVector(x + gridincx, y), light.c);
                color bl = luminance(light.pos, new PVector(x, y + gridincy), light.c);
                color br = luminance(light.pos, new PVector(x + gridincx, y + gridincy), light.c);
                red += (fastRed(tl) + fastRed(tr) +fastRed(bl) + fastRed(br))/4;
                green += (fastGreen(tl) + fastGreen(tr) +fastGreen(bl) + fastGreen(br))/4;
                blue += (fastBlue(tl) + fastBlue(tr) +fastBlue(bl) + fastBlue(br))/4;
              }
              this.bakedillum[(i*this.griddivisionsX + x1) + (j*this.griddivisionsY + y1)*(this.w*this.griddivisionsX)] = color(red, green, blue);
              y1++;
            }
            y1 = 0;
            x1++;
          }
       }
      }
      
    }
    
    void drawLights() {
     noStroke();
     rectMode(CORNER);
     
     int noiseLevel = 10;
     int ambientLevel = 10;
     
     float gridincx = 1.0/this.griddivisionsX;
     float gridincy = 1.0/this.griddivisionsY;
     
     PVector mouse = new PVector(localCoordsX(mouseX), localCoordsY(mouseY));
     randomSeed(0);
     
     for(int i = 0; i < this.w; i++) {
      for(int j = 0; j < this.h; j++)  {
        if(lookup(i, j)) {
          continue; 
        }
        int x1 = 0;
        int y1 = 0;
        for(float x = i; x < i+1; x+=gridincx) {
          for(float y = j; y < j+1; y+= gridincy) {
            
            // noise for flavor, as well as slight amount of ambient light
            float noise = random(1);
            int red = (int)ceil(noise * noiseLevel) + ambientLevel;
            int blue = (int)ceil(noise * noiseLevel) + ambientLevel;
            int green = (int)ceil(noise * noiseLevel) + ambientLevel;
            // average illumination at each corner
            color tl = luminance(mouse, new PVector(x, y), this.mouseColor);
            color tr = luminance(mouse, new PVector(x + gridincx, y), this.mouseColor);
            color bl = luminance(mouse, new PVector(x, y + gridincy), this.mouseColor);
            color br = luminance(mouse, new PVector(x + gridincx, y + gridincy), this.mouseColor);
            red += (fastRed(tl) + fastRed(tr) +fastRed(bl) + fastRed(br))/4;
            green += (fastGreen(tl) + fastGreen(tr) +fastGreen(bl) + fastGreen(br))/4;
            blue += (fastBlue(tl) + fastBlue(tr) +fastBlue(bl) + fastBlue(br))/4;
            
            // retrieve pre-baked lights  
            color c = this.bakedillum[(i*this.griddivisionsX + x1) + (j*this.griddivisionsY + y1)*(this.w*this.griddivisionsX)];
            
            red += fastRed(c);
            green += fastGreen(c);
            blue += fastBlue(c);
            
            fill(color(red, green, blue));
            rect(this.screenCoordsX(x), this.screenCoordsY(y), this.screenCoordsX(gridincx), this.screenCoordsY(gridincy));
            y1++;
          }
          y1 = 0;
          x1++;
        }
      } 
     }
    }
    
}

rayCaster walls;
int colorState;
boolean displayPointer;
boolean displayGrid;

int gridX = 16;
int gridY = 16;
int gridDivX = 8;
int gridDivY = 8;
float gridWallThreshold = 0.1;

void setup() {
  
  size(640, 640);
  printDirections();
  
  walls = new rayCaster(gridX, gridY, gridDivX, gridDivY, gridWallThreshold);
  
  colorState = 4;
  displayPointer = false;
  displayGrid = false;
}

void draw() {
 background(0);

 walls.drawLights();
 // draw grid
 if(displayGrid) {
   for(int i = 0; i < walls.w; i++) {
     stroke(255);
     line( walls.screenCoordsX(i), 0, walls.screenCoordsX(i), height);
   }
   
   for(int i = 0; i < walls.h; i++) {
     stroke(255);
     line( 0, walls.screenCoordsY(i), width, walls.screenCoordsY(i));
   }
   
   for(int i = 0; i < walls.w; i++) {
    for(int j = 0; j < walls.h; j++)  {
      fill(255);
     if(walls.lookup(i,j)) {
       rectMode(CORNER);
       rect(walls.screenCoordsX(i), walls.screenCoordsY(j), (float)width/walls.w, (float)height/walls.h);
     }
    } 
   }
 }
 
 if(displayPointer) {
   ellipseMode(RADIUS);
   fill(255,0,0);
   ellipse(mouseX, mouseY, 5, 5);
 }
 
}

void keyPressed() {
  if(key == 'q' || key == 'Q') {
       exit();
   }
   
   if(key == 'm' || key == 'M') {
     displayPointer = !displayPointer;
   }
   
   if(key == 'g' || key == 'G') {
     displayGrid = !displayGrid;
   }
   
   if(key == 'r' || key == 'R') {
     walls.reset(gridWallThreshold);
     walls.bakeLights();
   }
   
   if(key == 'c' || key == 'C') {
     colorState = (colorState + 1) % 6;
     switch(colorState) {
        case 0:
          walls.mouseColor = color(255, 0, 0);
          break;
         case 1:
          walls.mouseColor = color(0, 255, 0);
          break;
         case 2:
          walls.mouseColor = color(0, 0, 255);
          break;
         case 3:
          walls.mouseColor = color(255, 255, 0);
          break;
         case 4:
          walls.mouseColor = color(255, 255, 255);
          break; 
         case 5:
          walls.mouseColor = color(0, 0, 0);
          break; 
         default:
           break;
     }
   }
}

void mousePressed() {
  if(mouseButton == LEFT && (walls.fastRed(walls.mouseColor) + walls.fastGreen(walls.mouseColor) + walls.fastBlue(walls.mouseColor) > 0)) {
     walls.lights.add(new droppedLight(new PVector(walls.localCoordsX(mouseX), walls.localCoordsY(mouseY)), walls.mouseColor));
     walls.bakeLights();
  }
  else if(mouseButton == RIGHT) {
    if(walls.lights.size() > 0) {
      walls.lights.remove(walls.lights.size() - 1);
      walls.bakeLights();
    }
  }
}

void printDirections() {
   println("Commands:");
   println("\tc\tcycle light source color");
   println("\tm\tenable and disable mouse position display");
   println("\tg\tenable and disable grid and obstacle overlay");
   println("\tr\treset to new random layout");
   println("\tq\tquit"); 
   println("Left-click the mouse to place a light source. Right-click to remove the last placed light-source.");
}
