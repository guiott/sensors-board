//-----------------------------------------------------------------------------      

void LedTest ()
{ // blink all leds for some seconds
  int i;
  int Del = 100;

  for (i=0; i<3; i++)
  {
    digitalWrite(LedR,HIGH);
    delay(Del);
    digitalWrite(LedR,LOW);
    digitalWrite(LedY,HIGH);
    delay(Del);
    digitalWrite(LedY,LOW);
    digitalWrite(LedG,HIGH);
    delay(Del);
    digitalWrite(LedG,LOW);
    digitalWrite(Led2,HIGH);
    delay(Del);
    digitalWrite(Led2,LOW);
  }
}

//-----------------------------------------------------------------------------      

void SrfChangeAddress(byte oldAddress, byte newAddress)
{ // [1]
  Wire.beginTransmission(oldAddress);
  Wire.send(0x00);
  Wire.send(0xA0);
  Wire.endTransmission();

  Wire.beginTransmission(oldAddress);
  Wire.send(0x00);
  Wire.send(0xAA);
  Wire.endTransmission();

  Wire.beginTransmission(oldAddress);
  Wire.send(0x00);
  Wire.send(0xA5);
  Wire.endTransmission();

  Wire.beginTransmission(oldAddress);
  Wire.send(0x00);
  Wire.send(newAddress);
  Wire.endTransmission();
}

//-----------------------------------------------------------------------------      

void SrfSetup()
{// initial setup of SRF08 
  #define SRF_GAIN 5      // MAX gain [1b]
  #define SRF_RANGE 57   // Range [1c]
  
  Wire.beginTransmission(I2C_US_L);
  Wire.send(1);           // MAX gain register
  Wire.send(SRF_GAIN);  
  Wire.send(SRF_RANGE);    // next register
  Wire.endTransmission();
  
  Wire.beginTransmission(I2C_US_C);
  Wire.send(1);          // MAX gain register
  Wire.send(SRF_GAIN);  
  Wire.send(SRF_RANGE);  // next register
  Wire.endTransmission();
  
  Wire.beginTransmission(I2C_US_R);
  Wire.send(1);          // MAX gain register
  Wire.send(SRF_GAIN);  
  Wire.send(SRF_RANGE);  // next register
  Wire.endTransmission();
}

//-----------------------------------------------------------------------------      
void CmpInit()
{ // get the initial value of compass as 0 reference for robot orientation
    int CmpBearingTmp;
    // at least 2 equal readings before assigning reference
    do  
    {
      CmpBearingTmp = CmpBearing0;
      Wire.beginTransmission(I2C_CMP);
      Wire.send(2);	     // sets register pointer to 2 byte bearing (0x02)
      Wire.endTransmission();  // stop transmitting
      
      Wire.requestFrom(I2C_CMP, 2);
      if(2 <= Wire.available())   // if two bytes were received
      {
   // combine 2 registers in a word and use it as a delta from initial bearing
        CmpBearing0 = ((Wire.receive() << 8) + Wire.receive());
        if (CmpBearing0 < 0) CmpBearing0 += 360; // Keep angle value positive
      }
    }
    while (CmpBearing0 != CmpBearingTmp);
}
