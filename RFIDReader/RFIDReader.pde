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
#define BUZZER_TONE_YES 3520
#define BUZZER_TONE_NO  700
#define BUZZER_LEN  100

// Serial State
#define STATE_WAITING  0
#define STATE_SERIAL   1
#define STATE_CHECKSUM 2
#define STATE_END      3

#define START_CODE     0x02
#define END_CODE       0x03
#define SERIAL_LEN     10
#define CHECKSUM_SIZE  2

char serial[SERIAL_LEN + 1];
char checksum[CHECKSUM_SIZE + 1];
byte state = STATE_WAITING;
byte curByte, calcChecksum;


void setup() {
  // initialize serial communications at 9600 bps:
  Serial.begin(9600);
  RFID.begin(9600);
  
  tone(BUZZERPIN, BUZZER_TONE_YES, BUZZER_LEN);
  delay(BUZZER_LEN);
  
  #ifdef DEBUG
    Serial.println("Booted...");
    Serial.println(0x62 ^ 0xE3 ^ 0x08 ^ 0x6C ^ 0xED, HEX);
    Serial.println(0x01 ^ 0x00 ^ 0x03 ^ 0x8C ^ 0xEE, HEX);
    Serial.println(0x00 ^ 0xD8, HEX);
    Serial.println((byte) (0x01 + 0x00 + 0x03 + 0x8C + 0xEE), HEX);
  #endif
}

void loop() {
  byte readbyte;
  
  // Process Serial RFID Data
  if (RFID.available() > 0) {
    // Read the byte
    readbyte = RFID.read();
    
    // Debug info
    #ifdef DEBUG
      Serial.print("DATA:\tCHAR=");
      Serial.print(readbyte, BYTE);
      Serial.print("\tHEX=");
      Serial.print(readbyte, HEX);
      Serial.print("\tBIN=");
      Serial.print(readbyte, BIN);
      Serial.print("\tDEC=");
      Serial.println(state, DEC);
    #endif
    
    // Do something about it
    switch (state) {
      // If we were waiting for a start code
      case STATE_WAITING:
        if (readbyte == START_CODE) {
          state = STATE_SERIAL;
          curByte = 0;
          memset(serial, '\0', sizeof(char) * (SERIAL_LEN + 1));
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
          char *startChar;
          startChar = serial + (curByte - 1);
          
          calcChecksum ^= strtol(startChar, NULL, 16);
          #ifdef DEBUG
            Serial.print("CHECK:\tCHAR=");
            Serial.print(startChar[0], BYTE);
            Serial.print(startChar[1], BYTE);
            Serial.print("\tDEC=");
            Serial.print(strtol(startChar, NULL, 16));
            Serial.print("\tBIN=");
            Serial.println(strtol(startChar, NULL, 16), BIN);
            Serial.println("");
          #endif
        }
        
        if (++curByte == SERIAL_LEN) {
          curByte = 0;
          memset(checksum, '\0', sizeof(char) * (CHECKSUM_SIZE + 1));
          state = STATE_CHECKSUM;
          #ifdef DEBUG
            Serial.println("***Got Serial Code***");
          #endif
        }
        break;
      
      // If we're waiting for a checksum
      case STATE_CHECKSUM:
        checksum[curByte] = readbyte;
        
        if (++curByte == CHECKSUM_SIZE) {
          byte readChecksum = strtol(checksum, NULL, 16);
          if (calcChecksum == readChecksum) {
            state = STATE_END;
            #ifdef DEBUG
              Serial.println("***Checksum Pass***");
            #endif
          } else {
            state = STATE_WAITING;
            tone(BUZZERPIN, BUZZER_TONE_NO, BUZZER_LEN);
            #ifdef DEBUG
              Serial.print("***Checksum fail - Got:");
              Serial.print(readChecksum, HEX);
              Serial.print(", Wanted: ");
              Serial.print(calcChecksum, HEX);
              Serial.println(" ***");
            #endif
          }
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
          tone(BUZZERPIN, BUZZER_TONE_YES, BUZZER_LEN);
          gotSerial(serial);
        } else {
          tone(BUZZERPIN, BUZZER_TONE_NO, BUZZER_LEN);
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
  
  Serial.print("RFID Serial: ");
  for (int i = 0; i < SERIAL_LEN; i++) {
    Serial.print(serial[i], BYTE);
  }
  Serial.println("");
}
