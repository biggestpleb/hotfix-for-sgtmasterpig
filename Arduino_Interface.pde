//=========================================================================
//=======      L E D    D R I V E R    T H R E A D (for sgtmasterpig)      
//=========================================================================

//LED driver runs continuously and sends RGB values to the arduino
void ledDriver(){  
  
  while(true){
    delay(7); //this controls the transmit interval
    if(hue<0){
      hue += 360; 
    }
    hue = abs(hue)%360;
    
    //check for beats if beat detection enabled
    if(beatFlag && beatDetect){
      beatFlag = false;
      if(millis() - randomTime > 300){
        if(random(1) < switchRate){
          // ==== Generate random hue =====
          do{
            hue = (hue + random(60,240)) % 360; 
          } while ( abs((hue%120)-60) > 55 );
          
          if(random(-1,1)>0){
            hOffset = hOffsetMaxTemp; 
          } else {
            hOffset = -hOffsetMaxTemp; 
          }
        } else {
          // Case: beat detected but rng dictated no random colour
          if(random(-1,1)>0){
            hOffset = hOffsetMaxTemp; 
          } else {
            hOffset = -hOffsetMaxTemp; 
          }
        }
        //hue += 15;
        iSpikeVal = iOffsetMaxTemp;
        sSpikeVal = sOffsetMaxTemp;
        //if( random(-1,1)>1 ){
         // increment = 0.3; 
        //} else {
       //   increment = -0.3; 
       // }
        randomTime = millis();
      } else {
        //iSpikeVal = 1.5;
        //sSpikeVal = 1.5;
        //hSpikeVal = 20;
        
      }
    } else {
      beatFlag = false; 
    }
    
    //========== Handle any spikes ============
    if( hSpikeVal != 0 ){     
      if(millis()-hSpikeTime>300){
        hOffset = hSpikeVal; 
        hSpikeTime = millis();
      }
      hSpikeVal = 0;
    }
    if( sSpikeVal != 0 ){     
      if(millis()-sSpikeTime>300){
        sOffset = sSpikeVal; 
        sSpikeTime = millis();
      }
      sSpikeVal = 0;
    }
    if( iSpikeVal != 0 ){     
      if(millis()-iSpikeTime>300){
        iOffset = iSpikeVal; 
        iSpikeTime = millis();
      }
      iSpikeVal = 0;
    }
    //defualt hDecay = 0.99, s.92, i.9
   
    //======= Fade Offsets ==============
    hOffset = constrain(hOffset*hDecay,-180,180);
    sOffset = constrain(sOffset*sDecay, 0, 2);
    iOffset = constrain((iOffset)*iDecay, 0, 2);
    
    //memoryBlock = false;  //remove memory block
    //======== Drift Hue =========
    hue += hueDrift/(1000/7);
    
    sActual = constrain( saturation + sOffset, 0, sMax);
    iActual = constrain( intensity + iOffset, 0, iMax);

    //======= Generate data string for Arduino ======
    if( portConnected ){
      byte[] rgb = hsi2rgb(hue, sActual, iActual);
      setRGB(rgb[0], rgb[1], rgb[2], 0);
    }
  } 
}

void setRGB (byte red , byte green, byte blue, int led) {
 println(red + " " + green + " " + blue);
 arduino.write('S'); 
 arduino.write(red); 
 arduino.write(green); 
 arduino.write(blue); 
 arduino.write(led); 
 
}

//returns [r][g][b]
byte[] hsi2rgb(float H, float S, float I) {
  //you can scale the brighness of different led colors using this
  //generally you'll find that red looks less bright than blue and green for the same PWM duty cycle
  //if you scale the max value to above 255, it will still be constrained to <=255
  final float rMax = 255; //360;
  final float gMax = 255; //270;
  final float bMax = 255; //240;
  
  float r, g, b;
  H = fixHue(H); // cycle H around to 0-360 degrees
  
  H = 3.14159*H/180f; // Convert to radians.
  S = S>0?(S<1?S:1):0; // clamp S and I to interval [0,1]
  I = I>0?(I<1?I:1):0;
    
  // Math! Thanks in part to Kyle Miller.
  if(H < 2.09439) {
    r = rMax*I/3f*(1f+S*cos(H)/cos(1.047196667-H));
    g = gMax*I/3f*(1+S*(1-cos(H)/cos(1.047196667-H)));
    b = bMax*I/3f*(1-S);
  } else if(H < 4.188787) {
    H = H - 2.09439;
    g = gMax*I/3f*(1+S*cos(H)/cos(1.047196667-H));
    b = bMax*I/3f*(1+S*(1-cos(H)/cos(1.047196667-H)));
    r = rMax*I/3f*(1-S);
  } else {
    H = H - 4.188787;
    b = bMax*I/3*(1+S*cos(H)/cos(1.047196667-H));
    r = rMax*I/3*(1+S*(1-cos(H)/cos(1.047196667-H)));
    g = gMax*I/3*(1-S);
  }
  
  //convert to byte and return 
  byte[] rgb = new byte[3];
  rgb[0] = (byte)constrain(r, 0, 255);
  rgb[1] = (byte)constrain(g, 0, 255);
  rgb[2] = (byte)constrain(b, 0, 255);
  return rgb;
}

//constrain hue to interal 0->360
float fixHue( float input ){
  input %= 360;
  if(input<0) input += 360;
  return input;
}