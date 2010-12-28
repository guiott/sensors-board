/* ////////////////////////////////////////////////////////////////////////////
** File:      SensorBoard.pde
*/                                  
 unsigned char  Ver[] = "SensorBoard 1.3.5 Guiott 12-10"; // 30+1 char
/* Author:    Guido Ottaviani-->guido@guiott.com<--
** Description: This SW drives the Arduino board on reading some sensors in 
**		order to know the external environment and to instruct dsNavCon 
**		board, via serial communication, how to avoid obstacles and to 
**		find targets.   
**
** Detailed descriptions are on file "comments.txt" 
** numbers between brackets, eg.: [1] , are the references to the specific 
** decription into the file
**
-------------------------------------------------------------------------------
Copyright 2010 Guido Ottaviani
guido@guiott.com

    SensorBoard.pde is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SensorBoard.pde is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with SensorBoard.pde.  If not, see <http://www.gnu.org/licenses/>.
-------------------------------------------------------------------------------      
/////////////////////////////////////////////////////////////////////////////*/
// Compiler options
// #define DEBUG_MODE // If defined the serial output is in ASCII for debug
#define SOUND_DB   // if defined the values from Sound Board are in dB
// #define SOUND_FOLLOWER // if defined a demo program to follow sound starts

#include <Wire.h>
#include <Metro.h>

byte Buzzer = 13;                // Buzzer on Pin 13
byte Led2 = 11;                  // Alarm Led on Pin 11
byte LedG = 10;                  // Green Led on Pin 10
byte LedY = 9;                   // Yellow Led on Pin 9
byte LedR = 8;                   // Red Led on Pin 8
byte Sw = 7;                     // Switch
byte Bump[3];                    // Bumpers

#define BLINK_ON 200             // HeartBeat Blink On time
#define BLINK_OFF 800            // HeartBeat Blink Off time
#define BLINK_ALRT 100           // HeartBeat Blink Alert time

int LedStat = LOW;
int SwCount = 0;                 // push button counter
#define SW_COUNT_TMO 3           // push button debounce = 300ms
#define SW_COUNT_LONG_TMO 30     // special function if pressed > 3s

#define I2C_US_L 0x70            // SRF Ultra Sound left I2C address
#define I2C_US_C 0x71            // SRF Ultra Sound center I2C address
#define I2C_US_R 0x72            // SRF Ultra Sound right I2C address
#define I2C_DAC 0x28             // MAX127 AD expander I2C address
#define I2C_CMP 0x60             // CMPS03 compass sensor I2C address
#define I2C_SOUND 0x50           // PSoC Sound board I2C address

#define I2cCmpCalReg 15
#define I2cCmpCalValue 0xFF

byte SensorStatus = 0;           // SensorRead function status

#define L 0                      // Left position
#define C 1                      // Center position
#define R 2                      // Right position
#define US 0                     // Ultra sound sensor
#define IR 1                     // Infra red sensor
#define KL 0.8     // each sensor has his own weight in computation
#define KS 0.9
#define KG 0.7
byte Light[] = {0, 0, 0};        // Light values array
byte Gas[] = {0, 0, 0};          // Gas values array
byte Sound[] = {0, 0, 0};        // To be implemented
int SensDist[3][2] = {200,200,200,200,200,200};// Distance matrix: position x type of sensor
byte Dist[3] = {250, 250, 250};  // Current distance from object
byte Vbatt;
#define VBATT_THRESHOLD 102      // Battery alert when Vbatt < 11V
int CmpBearing;	                 // Compass reading
int CmpBearing0; 		 // orientetion at startup, got as a reference		
#define BOT_RADIUS  10 // cm to add to sensors measures to obtain distance from center of the bot
#define MIN_DIST BOT_RADIUS + 5  // alert distance from obstacle

Metro BlinkCycle = Metro(BLINK_OFF,1);  // LED blink cycle
Metro SensorCycle = Metro(14,1);        // Sensor reading cycle [2]
Metro SwitchCycle = Metro(100,1);       // Push button cycle
Metro SoundAverageCycle = Metro(1000,1);  // cycle for the sound follower test program

byte SendFlag= LOW;            // to enable data sending
int TimeElapsed = millis();

#ifdef SOUND_DB
  struct I2C_Sound_Struct {   // I2C interface structure  
      byte I2C_SoundValue[3]; // single measure
      int SumValue  [3];  // cumulate values to compute average
  } I2C_Regs;
#else
   struct I2C_Sound_Struct {   // I2C interface structure  
      long I2C_SoundValue[3];  // single measure
      long SumValue  [3];  // cumulate values to compute average
  } I2C_Regs; 
#endif

byte SoundCount=0; // to compute the average sound value

//-----------------------------------------------------------------------------      

void setup()
{
  pinMode(Buzzer, OUTPUT);      // sets the digital pin as output
  pinMode(Led2, OUTPUT);
  pinMode(LedG, OUTPUT);
  pinMode(LedY, OUTPUT);
  pinMode(LedR, OUTPUT);
  
  pinMode(Sw, INPUT);          // sets the digital pin as input
  pinMode(Bump[L], INPUT);
  pinMode(Bump[C], INPUT);
  pinMode(Bump[R], INPUT);
  
  Serial.begin(115200); 
  Wire.begin();                // join i2c bus (address optional for master)
  
  Bump[L] = 6;                 // Left Bumper
  Bump[C] = 5;                 // Central Bumper
  Bump[R] = 4;                 // Right Bumper

  CmpInit();                   // set reference orientation
  SrfSetup();                  // SRF08 initializing
  LedTest();
}

//-----------------------------------------------------------------------------      

void loop()
{  
  if (BlinkCycle.check() == 1) {HeartBeat();}  // Led blink
  if (SensorCycle.check() == 1) {SensorRead();}   // Sensor reading
  if (SwitchCycle.check() == 1) {Switch();}   // Push button
  if (SoundAverageCycle.check() == 1) {SoundAverage();}   // demo procedure for sound sensors
}

