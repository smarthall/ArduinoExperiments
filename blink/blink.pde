/*
  Blink
  Turns on an LED on for one second, then off for one second, repeatedly.
 
  This example code is in the public domain.
 */

void setup() {                
  // initialize the digital pin as an output.
  // Pin 13 has an LED connected on most Arduino boards:
  pinMode(13, OUTPUT);    
  pinMode(12, OUTPUT);   
}

void loop() {
  digitalWrite(13, HIGH);   // set the LED on
  digitalWrite(12, LOW);   // set the LED on
  delay(50);              // wait for a second
  digitalWrite(13, LOW);    // set the LED off
  digitalWrite(12, HIGH);   // set the LED on
  delay(50);              // wait for a second
}

