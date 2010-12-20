//-----------------------------------------------------------------------------  
 void I2c_sound_read(byte *buffer)
 {
    int c = 0;
    
    #ifdef SOUND_DB   
      Wire.beginTransmission(I2C_SOUND);
      Wire.send((int)(13));         // read register 13-14-15
      Wire.endTransmission();
      Wire.requestFrom(I2C_SOUND,3); // read 3 "byte" variables
      for ( c = 0; c < 3; c++ ) 
      {
        if (Wire.available()) 
        {
          buffer[c] = Wire.receive();
        }
      }    
    #else
      Wire.beginTransmission(I2C_SOUND);
      Wire.send((int)(0));
      Wire.endTransmission();
      Wire.requestFrom(I2C_SOUND,12); // read 3 "long" variables = 12 bytes
      // data on PSoC registers are Big Endian, AVR works in Little Endian
      for ( c = 11; c >= 0; c-- ) 
      {
        if (Wire.available()) 
        {
          buffer[c] = Wire.receive();
        }
      }
    #endif   
    
    SoundCount++;   // average counter
    for ( c = 0; c < 3; c++ ) 
     {  // cumulate values to compute average value
        I2C_Regs.SumValue[c]+= I2C_Regs.I2C_SoundValue[c];   
     }
  }

//-----------------------------------------------------------------------------  
 void I2c_sound_WD(void)
 {
   // pat the PSoC watchdog to control I2C communication
   Wire.beginTransmission(I2C_SOUND);
   Wire.send((int)(12));       // write register 12: I2cCheck
   Wire.send(0xFF);            // with a non zero value
   Wire.endTransmission();
 }
 
//-----------------------------------------------------------------------------  
void SoundFollower(void)
{
  // rotate the robot toward the strongest sound 
  int c = 0;
  
  #ifdef SOUND_DB   
    int Snd[3];
  #else
    long Snd[3];
  #endif
  
  for ( c = 0; c < 3; c++ )
  {
    Snd[c]=I2C_Regs.SumValue[c] / SoundCount; // compute average value
  }
  SoundCount=0; // reset count

/* to do
determina se livello maggiore di soglia e da quale sensore proviene
chiama procedura SendRelTurn() con 10 gradi
*/

}
