//-----------------------------------------------------------------------------                                                      
void CmpCal (void) ////////// tutta da controllare ????????????????????????
{// Compass calibration turning the robot at 90°step
  // set NORTH
  I2cSetReg(I2C_CMP, I2cCmpCalReg, I2cCmpCalValue);
  // NORTH done
  
  SendTurn(90); // set EAST
  delay (10000);
  I2cSetReg(I2C_CMP, I2cCmpCalReg, I2cCmpCalValue);
  // EAST done
  
  SendTurn(180); // set SOUTH
  delay (10000);
  I2cSetReg(I2C_CMP, I2cCmpCalReg, I2cCmpCalValue);
  // SOUTH done
  
  SendTurn(270); // set WEST
  delay (10000);
  I2cSetReg(I2C_CMP, I2cCmpCalReg, I2cCmpCalValue);
  // WEST done
  
  SendTurn(0); // reset to NORTH
}

//-----------------------------------------------------------------------------                                                      
void I2cSetReg(int address, int thisRegister, int thisValue) 
{ // write "thisValue" into "thisRegister" to "address" I2C device 
  // start I2C transmission:
  Wire.beginTransmission(address);
  // send address to write to:
  Wire.send(thisRegister);
  // send value to write to:
  Wire.send(thisValue);
  // end I2C transmission:
  Wire.endTransmission();
}

//-----------------------------------------------------------------------------                                                      
int I2cReqCmp (int addr)
{ // read a word (2 bytes) from compass sensor
  int Val = 0;
  Wire.beginTransmission(addr);
  Wire.send(2);	    // sets register pointer to 2 byte bearing (0x02)
  Wire.endTransmission(); // stop transmitting
  Wire.requestFrom(addr, 2);
  if(2 <= Wire.available())   // if two bytes were received
  {
    // combine 2 registers in a word and use it as a delta from initial bearing
    Val = ((Wire.receive() << 8) + Wire.receive()) - CmpBearing0;
    if (Val < 0) Val += 3600; // Keep angle value positive
  }
  return Val;
}
