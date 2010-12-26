// send commands to dsNav board with the right protocol:
// http://www.guiott.com/Rino/CommandDescr/Protocol.htm

//-----------------------------------------------------------------------------  
void SendStart(void)
{// send Start scheduler sequence command
  Serial.print("@");  // Header
  Serial.print(0, BYTE);    // broadcast
  Serial.print("#");  // command = "#'
  Serial.print(1, BYTE);    // command length
  Serial.print(100, BYTE);  // checksum
}

//-----------------------------------------------------------------------------  
void SendTurn(int Angle)
{// send turn to an absolute angle command
  byte (TxDataByte);
  byte ChkSum = 146; // "@" + 0 + "O" + 3
  Serial.print("@");  // Header
  Serial.print(0, BYTE);    // broadcast
  Serial.print("O");  // command = 'O' turn absolute degrees
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
void SendRelTurn(int Angle)
{// send command to turn for a relative angle starting from the current position 
  byte (TxDataByte);
  byte ChkSum = 178; // "@" + 0 + 'o' + 3
  Serial.print("@");  // Header
  Serial.print(0, BYTE);    // broadcast
  Serial.print("o");  // command = "o' turn relative degrees
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
void SendHalt(void)
{// send Halt command
  Serial.print("@");  // Header
  Serial.print(0, BYTE);    // broadcast
  Serial.print("H");  // command = "#'
  Serial.print(1, BYTE);    // command length
  Serial.print(137, BYTE);  // checksum
}

//-----------------------------------------------------------------------------  
void SendSpeed(int Speed)
{// send a command to travel at the desired speed
  byte (TxDataByte);
  byte ChkSum = 150; // "@" + 0 + "S" + 3
  Serial.print("@");  // Header
  Serial.print(0, BYTE);    // broadcast
  Serial.print("S");  // command = 'O' turn absolute degrees
  Serial.print(3, BYTE);    // command length
  TxDataByte = (byte) (Speed >> 8);
  Serial.print(TxDataByte, BYTE);    // byte high
  ChkSum = ChkSum + TxDataByte;
  TxDataByte = (byte) Speed;
  Serial.print(TxDataByte, BYTE);    // byte low
  ChkSum = ChkSum + TxDataByte;
  Serial.print(ChkSum, BYTE);  // checksum
}

