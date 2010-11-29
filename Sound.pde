 void I2c_sound_read(byte *buffer)
 {
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
  }

