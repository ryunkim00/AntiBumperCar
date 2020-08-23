/*   
HC05 - Bluetooth AT-Command mode  
modified on 10 Feb 2019 
by Saeed Hosseini 
https://electropeak.com/learn/ 
*/ 
#include <SoftwareSerial.h> 

SoftwareSerial hc05Serial(10, 11); // RX | TX 

int flag = 0; 
int LED = 8; 
int REAR_LEFT = 4;
int REAR_RIGHT = 7;
int RIGHT = 5;
int LEFT = 6;
const int carStop = 0;
const int goForward = 1;
const int turnRight = 2;
const int turnLeft = 3;
int serialInput = 0;
int prevInput = 0;
char state = 0;

void setup() 
{   
 Serial.begin(9600); 
  while (!Serial);
  
 hc05Serial.begin(9600); 
 pinMode(LED, OUTPUT); 
 pinMode(REAR_LEFT, OUTPUT);
 pinMode(REAR_RIGHT, OUTPUT);
 pinMode(LEFT, OUTPUT);
 pinMode(RIGHT, OUTPUT);
 Serial.println("Ready to connect\nDefualt password is 1234 or 000"); 
} 

void loop() 
{ 
  if(hc05Serial.available())
  {
    state = hc05Serial.read();
    Serial.println(state);
    
    switch(state)
    {
      case '0':
        stopCar();
        break;
        
      case '1':
        forward();
        break;
        
      case '2':
        right();
        break;
        
      case '3':
        left();
        break;
        
      default:
        Serial.print("received unexpected state value ");
        Serial.println(state);
        break;
    }
  }
}  

void stopCar()
{
  Serial.println("STOP STATE");
  digitalWrite(REAR_LEFT, LOW);
  digitalWrite(REAR_RIGHT, LOW);
  digitalWrite(RIGHT, LOW);
  digitalWrite(LEFT, LOW);
}
void forward() 
{
  Serial.println("FORWARD STATE");
  digitalWrite(REAR_LEFT, HIGH);
  digitalWrite(REAR_RIGHT, HIGH);
  digitalWrite(RIGHT, HIGH);
  digitalWrite(LEFT, HIGH);
}

void right()
{
  Serial.println("TURN RIGHT STATE");
  digitalWrite(REAR_LEFT, HIGH);
  digitalWrite(REAR_RIGHT, HIGH);
  digitalWrite(RIGHT, HIGH);
  for (int time = 0; time > 10; time++)
  {
    digitalWrite(LEFT, LOW);
    delayMicroseconds(100);
  }
}

void left()
{
  Serial.println("TURN LEFT STATE");
  digitalWrite(REAR_LEFT, HIGH);
  digitalWrite(REAR_RIGHT, HIGH);
  digitalWrite(LEFT, HIGH);
  for (int time = 0; time > 10; time++)
  {
    digitalWrite(RIGHT, LOW);
    delayMicroseconds(100);
  }
}

void executeInst()
{
 switch (serialInput)
 {
  case carStop:
    stopCar();
    break;
  case goForward:
    forward();
    break;
   case turnRight:
    right();
    break;
   case turnLeft:
    left();
    break;
 }
}
