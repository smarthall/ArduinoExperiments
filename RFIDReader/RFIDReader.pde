/*********************************************************
 * This sketch is designed to read RFID tags from the
 * SeedStudio 125kHz UART RFID Reader. You can buy them
 * from SeedStudio or LittleBirdElectronics here:
 * http://www.seeedstudio.com/depot/125khz-rfid-module-p-171.html
 * http://littlebirdelectronics.com/products/125khz-rfid-module-uart
 *
 * Author: Daniel Hall <daniel@danielhall.me>
 * Date: 16/03/2011
 * License: GPLv3
 *********************************************************/

#include <NewSoftSerial.h>

// Debugging?
//#define DEBUG

// PIN constants
#define RXRFID 4
#define TXRFID 5

#define BUZZERPIN 9

// Software Serial
NewSoftSerial RFID(RXRFID,TXRFID);

// Buzzer settings
#define BUZZER_TONE 3520
#define BUZZER_LEN  100

// Serial State
#define STATE_WAITING  0
#define STATE_SERIAL   1
#define STATE_CHECKSUM 2
#define STATE_END      3

#define START_CODE 0x02
#define END_CODE   0x03
#define SERIAL_LEN 10

char serial[SERIAL_LEN];
byte state = STATE_WAITING;
byte curByte, calcChecksum;


void setup() {
  // initialize serial communications at 9600 bps:
  Serial.begin(9600);
  RFID.begin(9600);
}

void loop() {
  byte readbyte;
  
  // Process Serial RFID Data
  if (RFID.available() > 0) {
    // Read the byte
    readbyte = RFID.read();
    
    // Debug info
    #ifdef DEBUG
      Serial.print("Data: ");
      Serial.print(readbyte, HEX);
      Serial.print(", State: ");
      Serial.println(state, DEC);
    #endif
    
    // Do something about it
    switch (state) {
      // If we were waiting for a start code
      case STATE_WAITING:
        if (readbyte == START_CODE) {
          state = STATE_SERIAL;
          curByte = 0;
          calcChecksum = 0x00;
          #ifdef DEBUG
            Serial.println("***Got Start Code***");
          #endif
        }
        break;
        
      // If we were waiting for the serial
      case STATE_SERIAL:
        serial[curByte] = readbyte;
        if (curByte % 2) {
          char *startChar, *endChar;
          startChar = serial + curByte;
          endChar = serial + curByte - 1;
          
          calcChecksum ^= strtol(startChar, &endChar, 16);
        }
        
        if (curByte++ == SERIAL_LEN) {
          state = STATE_CHECKSUM;
          #ifdef DEBUG
            Serial.println("***Got Serial Code***");
          #endif
        }
        break;
      
      // If we're waiting for a checksum
      case STATE_CHECKSUM:
        if (calcChecksum == readbyte) {
          state = STATE_END;
          #ifdef DEBUG
            Serial.println("***Checksum Pass***");
          #endif
        } else {
          state = STATE_WAITING;
          #ifdef DEBUG
            Serial.print("***Checksum fail - Got:");
            Serial.print(readbyte, HEX);
            Serial.print(", Wanted: ");
            Serial.print(calcChecksum, HEX);
            Serial.println(" ***");
          #endif
        }
        // TODO: Check the actual checksum
        /*state = STATE_END;
        #ifdef DEBUG
          Serial.println("***Checksum Stubbed Pass***");
        #endif*/
        break;
        
      // If we're waiting the end code
      case STATE_END:
        if (readbyte == END_CODE) {
          #ifdef DEBUG
            Serial.println("***Got End Code***");
          #endif
          gotSerial(serial);
        }
        
        state = STATE_WAITING;
        break;
    }
  }
}

// Replace this function with your own payload for when a tag is read.
void gotSerial(char *theSerial) {
  #ifdef DEBUG
    Serial.println("Beeping.. :D");
  #endif
  tone(BUZZERPIN, BUZZER_TONE, BUZZER_LEN);
  
  Serial.print("RFID Serial: ");
  for (int i = 0; i < SERIAL_LEN; i++) {
    Serial.print(serial[i], BYTE);
  }
  Serial.println("");
}
