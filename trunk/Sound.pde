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
void SoundAverage(void)
{
  // compute a mean value of the sound level averaging some measurements 
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

 #ifdef SOUND_DB   
    SoundFollower((int *) &Snd); // a little demo to show the sound sensors capabilities
 #else
    SoundFollower((long *) &Snd); // 
 #endif
 
  for ( c = 0; c < 3; c++ )
  {
    I2C_Regs.SumValue[c]=0; // reset average value
  }
  SoundCount=0; // reset count
}

//-----------------------------------------------------------------------------  
  #ifdef SOUND_DB   
    void SoundFollower(int *Snd)
    {
  #else
    void SoundFollower(long *Snd)
    {
  #endif
    // rotate the robot toward the strongest sound 
    
  #define L 0
  #define C 1
  #define R 2
  #define MIN 10  // sound level threshold in dB
  
  if ((Snd[L] > MIN) || (Snd[R] > MIN))
  {
    if (Snd[L] > Snd[R])
    {
      if (Snd[L] > Snd[C])
      {
        SendRelTurn(-30);
      }
    }
    else
    {
      if (Snd[R] > Snd[C])
      {
        SendRelTurn(30);
      }
    }
  }
}
