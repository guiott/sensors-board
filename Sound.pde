 void I2c_sound_read(byte *buffer)
 {
    #ifdef SOUND_DB   
      Wire.beginTransmission(I2C_SOUND);
      Wire.send((int)(0));
      Wire.endTransmission();
      Wire.requestFrom(I2C_SOUND,12); // read 3 long variables = 12 bytes
      int c = 0;
      // data on PSoC registers are Big Endian, AVR works in Little Endian
      for ( c = 11; c >= 0; c-- ) 
      {
        if (Wire.available()) 
        {
          buffer[c] = Wire.receive();
        }
      }
    #else
      Wire.beginTransmission(I2C_SOUND);
      Wire.send((int)(13));         // read register 13-14-15
      Wire.endTransmission();
      Wire.requestFrom(I2C_SOUND,3); // read 3 byte variables
      int c = 0;
      for ( c = 0; c < 3; c++ ) 
      {
        if (Wire.available()) 
        {
          buffer[c] = Wire.receive();
        }
      }
    #endif   
  }

 void I2c_sound_WD(void)
 {
   // pat the PSoC watchdog to control I2C communication
   Wire.beginTransmission(I2C_SOUND);
   Wire.send((int)(12));       // write register 12: I2cCheck
   Wire.send(0xFF);            // with a non zero value
   Wire.endTransmission();
 }
