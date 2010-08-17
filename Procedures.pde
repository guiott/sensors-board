//-----------------------------------------------------------------------------      
void Switch (void)
{ // Push button test
  if (digitalRead(Sw)==HIGH)
  {
    SwCount++;
    if (SwCount >= SW_COUNT_LONG_TMO)
    {// if pressed for more then 3s it starts the CMP calibration procedure
      SwCount=0;
      digitalWrite(Buzzer,HIGH);
      delay (3000);
      digitalWrite(Buzzer,LOW);
      delay (2000);
      CmpCal();
    }
  }
  else
  {
    if (SwCount >= SW_COUNT_TMO)
    {// if pressed for more then 300ms it starts scheduler procedure on dsNav
      digitalWrite(Buzzer,HIGH);
      SendStart(); // send start command to dsNavCon
      delay (1000);
      digitalWrite(Buzzer,LOW);
    }
    SwCount=0;
  }
}

//-----------------------------------------------------------------------------      
void HeartBeat (void)
{ // regular blink as heart beat signal
  if (LedStat == LOW)
  {
    LedStat = HIGH;
    BlinkCycle.interval(BLINK_ON);  // change to ON period
    digitalWrite(Buzzer,LOW);
  }
  else
  {
    LedStat = LOW;
    if (Vbatt < VBATT_THRESHOLD) 
    {// if battery low blink faster [5]
      BlinkCycle.interval(BLINK_ALRT);
      digitalWrite(Buzzer,HIGH);
    }
    else
    {
      BlinkCycle.interval(BLINK_OFF);  // change to OFF period
    }
  }
  
  digitalWrite(Led2,LedStat);
}

//-----------------------------------------------------------------------------      
void SensorRead()
{
  int i;  // generic index
  #define DAC_GAS 0x80             // DAC CH0 for gas
  #define DAC_EYE_R 0x90           // DAC CH1 for EYE_R IR range meter
  #define DAC_EYE_C 0xA0           // DAC CH2 for EYE_C IR range meter
  #define DAC_EYE_L 0xB0           // DAC CH3 for EYE_L IR range meter
  #define DAC_VBATT 0xC0           // DAC CH4 for Vbatt

  switch (SensorStatus)
  { // [2]
  case 0:
    // Left US set ----
    Wire.beginTransmission(I2C_US_L); // [1a]
    Wire.send(0x00);  
    Wire.send(0x51);             // command sensor to measure in "centimeters" 
    Wire.endTransmission();
    // ---- Left US

    // Gas set ----
    Wire.beginTransmission(I2C_DAC);
    Wire.send(DAC_GAS);              // set CH0
    Wire.endTransmission();
    // ---- Gas
    break;

  case 1:
    Gas[C] = I2cReqV(I2C_DAC); // Gas read  on DAC CH0
    
    // Left IR set ----
    Wire.beginTransmission(I2C_DAC);
    Wire.send(DAC_EYE_L);           // set CH3
    Wire.endTransmission();
    // ---- Left IR
    break;

  case 2:
    // Left US read ----
    Wire.beginTransmission(I2C_US_L); 
    Wire.send(0x01);             // sets register pointer to light register (0x01)
    Wire.endTransmission();      // stop transmitting
    I2cReqDist(I2C_US_L, L, US); // Read values on SRF08 Left
    // ---- Left US

    // Center US set ----
    Wire.beginTransmission(I2C_US_C); // [1a]
    Wire.send(0x00);  
    Wire.send(0x51);             // command sensor to measure in "centimeters" 
    Wire.endTransmission();
    // ---- Center US
    break;

  case 3:
    I2cReqDist(I2C_DAC, L, IR); // Left IR read  on DAC CH3

    // Center IR set ----
    Wire.beginTransmission(I2C_DAC);
    Wire.send(DAC_EYE_C);           // set CH2
    Wire.endTransmission();
    // ---- center IR
    break;

  case 4:
    I2cReqDist(I2C_DAC, C, IR); // Center IR read  on DAC CH2

    // Center US read ----
    Wire.beginTransmission(I2C_US_C); 
    Wire.send(0x01);             // sets register pointer to light register (0x01)
    Wire.endTransmission();      // stop transmitting
    I2cReqDist(I2C_US_C, C, US); // Read values on SRF08 Center
    // ---- Center US
    break;

  case 5:
    // Right US set ----
    Wire.beginTransmission(I2C_US_R); // [1a]
    Wire.send(0x00);  
    Wire.send(0x51);             // command sensor to measure in "centimeters" 
    Wire.endTransmission();
    // ---- Right US

    // Right IR set ----
    Wire.beginTransmission(I2C_DAC);
    Wire.send(DAC_EYE_R);           // set CH1
    Wire.endTransmission();
    // ---- Right IR
    break;

  case 6:
    I2cReqDist(I2C_DAC, R, IR); // Right IR read  on DAC CH1
    
    // Vbatt set ----
    Wire.beginTransmission(I2C_DAC);
    Wire.send(DAC_VBATT);            // set CH4
    Wire.endTransmission();
    // ---- Vbatt
    break;
    
  case 7:
    Vbatt = I2cReqV(I2C_DAC);  // Vbatt read  on DAC CH4
 
    // Right US read ----
    Wire.beginTransmission(I2C_US_R); 
    Wire.send(0x01);             // sets register pointer to light register (0x01)
    Wire.endTransmission();      // stop transmitting
    I2cReqDist(I2C_US_R, R, US); // Read values on SRF08 Right
    // ---- Right US
    
    // Compass reading ----
    CmpBearing = I2cReqCmp(I2C_CMP);
    // ---- Compass
    
    DataPrint();
    break;
    
  default:
    break;
  }
 
  for (i = L; i <= R; i++)  // [4]
  {
    if (digitalRead(Bump[i]))
    {
      Dist[i] = 0;
    }
    
    if (Dist[i] < MIN_DIST)
    {// if too close to obstacle, immediately alert Navigation Board
      Obstacle();
    }
    else
    {
      NoObstacle();
    }
  }
 
  SensorStatus ++;      // cycle among 8 states
  if (SensorStatus > 7)
  {
    SensorStatus = 0;
  }
}

//-----------------------------------------------------------------------------      
#ifdef DEBUG_MODE
void DataPrint(void)
{// send read data on serial port as debug
  Serial.print("US L:");
  Serial.print(SensDist[L][US]);
  Serial.print(" ");
  Serial.print("-C:");
  Serial.print(SensDist[C][US]);
  Serial.print(" ");
  Serial.print("-R:");
  Serial.print(SensDist[R][US]);
  Serial.println("");
  
  Serial.print("IR L:");
  Serial.print(SensDist[L][IR]);
  Serial.print(" ");
  Serial.print("-C:");
  Serial.print(SensDist[C][IR]);
  Serial.print(" ");
  Serial.print("-R:");
  Serial.print(SensDist[R][IR]);
  Serial.println("");
  
  Serial.print("Light L:");
  Serial.print(Light[L], DEC);
  Serial.print(" ");
  Serial.print("-C:");
  Serial.print(Light[C], DEC);
  Serial.print(" ");
  Serial.print("-R:");
  Serial.print(Light[R], DEC);
  Serial.print(" ");
  Serial.print("-Gas:");
  Serial.print((int)Gas[C]);
  Serial.print("-Batt:");
  Serial.print((int)Vbatt);
  Serial.print("-Cmp:");
  Serial.println((int)CmpBearing);
  Serial.print("time: ");
  Serial.println((millis() - TimeElapsed));
  TimeElapsed = millis();
  Serial.println(" ");
  
}
#else
void DataPrint(void)
{// send read data on serial port to Navigation Control Board
  int i;            // generic index
  byte TxBuff[16];
  byte ChkSum=0;
  
  TxBuff[0] = 64;  // Header = "@"
  TxBuff[1] = 0;   // broadcast
  TxBuff[2] = 100; // command = "d"
  TxBuff[3] = 9;   // command length
  TxBuff[4] = Dist[L];
  TxBuff[5] = Dist[C];
  TxBuff[6] = Dist[R];
  TxBuff[7] = Target(L);
  TxBuff[8] = Target(C);
  TxBuff[9] = Target(R);
  TxBuff[10]= (byte)(CmpBearing >> 8);
  TxBuff[11]= (byte)(CmpBearing);
  
  for (i=0; i<=11; i++)
  {
    ChkSum += TxBuff[i];
    Serial.print(TxBuff[i], BYTE);
  }
  
  Serial.print(ChkSum);
}
#endif

//-----------------------------------------------------------------------------  
void SendStart(void)
{// send start command
  Serial.print("@");  // Header
  Serial.print(0, BYTE);    // broadcast
  Serial.print("#");  // command = "#'
  Serial.print(1, BYTE);    // command length
  Serial.print(100, BYTE);  // checksum
}

//-----------------------------------------------------------------------------  
void SendTurn(int Angle)
{// send turn command
  byte (TxDataByte);
  byte ChkSum = 146; // "@" + 0 + "O" + 3
  Serial.print("@");  // Header
  Serial.print(0, BYTE);    // broadcast
  Serial.print("O");  // command = "O' turn absolute degrees
  Serial.print(3, BYTE);    // command length
  TxDataByte = (byte) (Angle >> 8);
  Serial.print(TxDataByte, BYTE);    // byte high
  ChkSum = ChkSum + TxDataByte;
  TxDataByte = (byte) Angle;
  Serial.print(TxDataByte, BYTE);    // byte low
  ChkSum = ChkSum + TxDataByte;
  Serial.print(ChkSum, BYTE);  // checksum
}

//-----------------------------------------------------------------------------  
void I2cReqDist(int addr, int SensNum, byte Tip)
{// read 2 or 3 bytes from I2C device and compose equivalent dist as an int
  byte TempH;
  byte TempL;
  int TempD;
  
  if (Tip == 0)
  { 
    Wire.requestFrom(addr, 3);
    if(1 <= Wire.available())   // if three bytes were received
    {
      Light[SensNum] = Wire.receive(); // first one is the light measure
      TempH = Wire.receive();// receive high byte
      TempL = Wire.receive();// receive low byte as lower 8 bits
      // shift high byte to be high 8 bits
      SensDist[SensNum][Tip] = TempH << 8 | TempL; // distance in cm
      if (SensDist[SensNum][Tip]==0 || SensDist[SensNum][Tip] >255-BOT_RADIUS)
      {
        // To avoid false measure in open space, if no echo it returns 0
        SensDist[SensNum][Tip] = 255 - BOT_RADIUS; 
      }
    }
  }
  else
  {
    Wire.requestFrom(addr, 2);
    if(2 <= Wire.available())   // if two bytes were received
    {
      TempH = Wire.receive();// receive high byte
      TempL = Wire.receive();// receive low byte as lower 8 bits
      // shift high byte to be high 8 bits
      TempD = TempH << 8 | TempL;
      // to adapt MAX127 bit format
      TempD = (TempD >> 4) & 0x0FFF; 
      SensDist[SensNum][Tip] = 9840/(TempD-32); // [3]
    }
  }
  // Measures is from the center of the robot
  SensDist[SensNum][Tip]=SensDist[SensNum][Tip]+BOT_RADIUS;
  
  // [4a]
  if (SensDist[SensNum][US] < 45)
  {
    Dist[SensNum]=(byte)(min(SensDist[SensNum][US], SensDist[SensNum][IR])); 
  }
  else
  {
     Dist[SensNum]=(byte)(SensDist[SensNum][US]);
  }
}

//-----------------------------------------------------------------------------                                                      
byte I2cReqV (int addr)
{ // read a word (2 bytes) from other kind of sensors
  byte TempH;
  byte TempL;
  int ValTmp = 0;
  byte Val = 0;

  Wire.requestFrom(addr, 2);
  if(2 <= Wire.available())   // if two bytes were received
  {
    TempH = Wire.receive();// receive high byte
    TempL = Wire.receive();// receive low byte as lower 8 bits
    // shift high byte to be high 8 bits
    ValTmp = TempH << 8 | TempL;
    // to adapt MAX127 bit format
    Val = (ValTmp >>8) & 0x00FF; // cut lower bits to fit in a byte
  }
  return Val;
}

//-----------------------------------------------------------------------------                                                      
void Obstacle(void)
{
  digitalWrite(LedR,HIGH);
  digitalWrite(LedY,HIGH);
  digitalWrite(LedG,HIGH);
  DataPrint();
}

//-----------------------------------------------------------------------------                                                      
void NoObstacle(void)
{
  digitalWrite(LedR,LOW);
  digitalWrite(LedY,LOW);
  digitalWrite(LedG,LOW);
}

//-----------------------------------------------------------------------------                                                      
byte Target(byte Num)
{  
  byte Value = 0;
  Value = max((Light[Num] * KL), (Sound[Num] * KS));
  Value = max(Value, (Gas[Num] * KG));
  return Value;
}
