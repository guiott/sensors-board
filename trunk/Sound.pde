//-----------------------------------------------------------------------------  
 void I2c_sound_read(byte *buffer)
 {
    int c = 0;
    
    #ifdef SOUND_DB   
      Wire.beginTransmission(I2C_SOUND);
      Wire.send((int)(13));         // read register 13-14-15
      Wire.endTransmission();
      Wire.requestFrom(I2C_SOUND,3); // read 3 "byte" variables
      if (3 <= Wire.available()) 
      {
        for ( c = 0; c < 3; c++ ) 
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
      if (12 <= Wire.available()) 
      {
        for ( c = 11; c >= 0; c-- ) 
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

#ifdef SOUND_FOLLOWER// a little demo to show the sound sensors capabilities
 #ifdef SOUND_DB   
    SoundFollower((int *) &Snd);
 #else
    SoundFollower((long *) &Snd); 
 #endif
#endif
 
 /* Just for debugging purposes
  Serial.print("L:");
  Serial.print(Snd[L]);
  Serial.print(" ");
  Serial.print("-C:");
  Serial.print(Snd[C]);
  Serial.print(" ");
  Serial.print("-R:");
  Serial.print(Snd[R]);
  Serial.println("");
 */
  
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
    
  #define MIN 10  // sound level threshold in dB
  #define VEL 50

  if ((Dist[C] > 20) && (Dist[L] > 20) && (Dist[R] > 20)) // far from objects
  {
    if ((Snd[L] > MIN) || (Snd[R] > MIN))
    {
      if (Snd[L] > Snd[R])
      {
        if (Snd[L] > Snd[C])
        {
          SendRelTurn(-30);
        }
        else
        {
          Walk(VEL, Snd[C]);
        }
      }
      else
      {
        if (Snd[R] > Snd[C])
        {
          SendRelTurn(30);
        }
        else
        {
          Walk(VEL, Snd[C]);
        }
      }
    }
    else
    {
      Walk(VEL, Snd[C]);
    }
  }
  else
  {
    SendHalt();
  }
}

//-----------------------------------------------------------------------------  
void Walk(int Speed, int SndC)
{
  // walk forward to the sound
  if (SndC > MIN)
  {
    SendSpeed(Speed); // walk at Speed mm/s
  }
  else
  {
    SendHalt();
  }
}
