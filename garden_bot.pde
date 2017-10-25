  /* 
    GardenBot related class, with methods for x y and z pod set & read positions 
  */

class GardenBot{
  color drawingColor = 255;
  int nbPillars; //set number of pillars composing the gardenbot
  int podSize; //set pod size for circle shape and projected square
  PVector[] pillars; // = new PVector[nbPillars]; //store each pillar's x y coordinates and height
  ReactShape footprint;
  PVector pod = new PVector(0,0,0); //store pod's x y z coordinates
  PVector current_pod = new PVector(0,0,0); //store current pod position
  Button grabber; //a button used to grab the pod on ground plane
  
  boolean podGrabbed = false; //true if pod projection on ground plane is grabbed by user
  
  GardenBot(PVector[] pillarsCoordinates, float pod_height){
    this.podSize = 40;//(int) (40 * maxWidth(pillarsCoordinates) / width);
    this.grabber = new Button(0,0,podSize);
    this.nbPillars = pillarsCoordinates.length;
    this.pillars = new PVector[this.nbPillars];
    this.pod.z = pod_height;
    arrayCopy(pillarsCoordinates,this.pillars);
    footprint = new ReactShape(pillars);
  }
  
  void drawBot(){
    
    //draw bot footprint
    noFill();
    stroke(this.drawingColor);
    shape(footprint.custom_shape,0,0);
    
    //draw Pillars and lines between pillars and pod
    for(int i=0;i<this.nbPillars;i++){
      strokeWeight(3);
      line(this.pillars[i].x,this.pillars[i].y,this.pillars[i].z,this.pillars[i].x,this.pillars[i].y,0); 
      strokeWeight(1);
      line(this.pillars[i].x,this.pillars[i].y,this.pillars[i].z,this.pod.x,this.pod.y,this.pod.z); 
    }
    
    //draw pod
    translate(0, 0, this.pod.z);
    ellipse(this.pod.x, this.pod.y, this.podSize, this.podSize);
    translate(0, 0, -this.pod.z);
    
    //draw current pod
    goToXYZ();
    translate(0, 0, this.current_pod.z);
    ellipse(this.current_pod.x, this.current_pod.y, this.podSize, this.podSize);
    translate(0, 0, -this.current_pod.z);
    
    //draw x and y cursor axis
    stroke(150);
    
    PVector[] podXYbound = footprint.getUpDownLeftRightbounds(this.pod);
    line(podXYbound[0].x,podXYbound[0].y,podXYbound[2].x,podXYbound[2].y);
    line(podXYbound[1].x,podXYbound[1].y,podXYbound[3].x,podXYbound[3].y);
      
    //draw grabber
    this.grabber.x = (int) this.pod.x;
    this.grabber.y = (int) this.pod.y;
    this.grabber.drawButton();
  }
  
  boolean isMouseOverGrabber(){
    return overRect(this.pod.x, this.pod.y, this.podSize, this.podSize);
  }
  
  void update_pod_location(PVector updatedLocation){
    float savedheight = this.pod.z;
    this.pod = this.footprint.getClosestPointInsideShape(updatedLocation);
    this.pod.z = savedheight;
  }
  
  float[] returnLinksMeasurements(PVector apod){
    float[] links = new float[nbPillars];
    for(int i = 0;i<nbPillars;i++){
      links[i]= this.pillars[i].copy().sub(apod).mag();
    }
    return links;
  }
  
  void goToXYZ(){
    PVector Egoal = this.pod.copy().sub(this.current_pod);
    float p = 10; // error proportional constant
    this.current_pod.add(Egoal.mult(1/p));
    //printArray(returnLinksMeasurements(this.current_pod));
  }
}

//class made of any custom shape to know if a point is inside the shape
class ReactShape {
  PShape custom_shape;
  PShape offscreen_custom_shape;
  PGraphics pg; //create offscreen buffer to test if a point is within shape
   
  ReactShape(PVector[] vertices){
    pg = createGraphics((int) (1 * maxWidth(vertices)),(int) (1 * maxHeight(vertices)));
    println("maxwidth "+maxWidth(vertices)+ " maxheight "+maxHeight(vertices));
    this.custom_shape = createShape();
    offscreen_custom_shape = createShape();
    this.custom_shape.beginShape();
    offscreen_custom_shape.beginShape();
    this.custom_shape.noFill();
    offscreen_custom_shape.fill(255);
    this.custom_shape.stroke(255);
    for(PVector vect : vertices){
      this.custom_shape.vertex(vect.x, vect.y);
      offscreen_custom_shape.vertex(vect.x, vect.y);  
    }
    this.custom_shape.endShape(CLOSE);
    offscreen_custom_shape.endShape(CLOSE);
    shape(this.custom_shape,0,0);
    this.pg.beginDraw();
    this.pg.background(0);
    this.pg.stroke(255);
    this.pg.shape(offscreen_custom_shape,pg.width/2,pg.height/2);
    this.pg.endDraw();
  }
  
  //return true if point over shape
  boolean isOverFootprint(PVector point){
    if(this.pg.get((int) point.x + pg.width/2,(int) point.y+pg.height/2) == color(255)){
      return true;
    }else{
      return false;
    }
  }
  
  //return the closest coordinates inside shape from point using dicotomy, origin must be inside shape
  PVector getClosestPointInsideShape(PVector point){
    PVector pt = point.copy();
    if(isOverFootprint(pt)) return pt;
    float dicotomy_mag = pt.mag()/2;
    while(dicotomy_mag > 1){  //while pixel diff between point and result > 1 pixel
      if(isOverFootprint(pt)){
        pt.setMag(pt.mag()+dicotomy_mag);
      }else{
        pt.setMag(pt.mag()-dicotomy_mag);
      }
      dicotomy_mag /= 2;
    }
    return pt;
  }
  
  PVector[] getUpDownLeftRightbounds(PVector point){
    PVector[] result=new PVector[4]; //4 vectors : 4 boundaries along +x +y -x -y
    PVector unitVector = new PVector(1,0);
    for(int i=0;i<4;i++){
      float dicotomy_mag = max(pg.width/2,pg.height/2);
      result[i] = point.copy();
      while(dicotomy_mag > 1){  //while pixel diff between point and result > 1 pixel
        if(isOverFootprint(result[i])){   
          result[i].add(unitVector.copy().mult(dicotomy_mag));
        }else{
          result[i].sub(unitVector.copy().mult(dicotomy_mag));
        }
        dicotomy_mag /= 2;
      }
      unitVector.rotate(HALF_PI);   
    }
    return result;
  }
   
}