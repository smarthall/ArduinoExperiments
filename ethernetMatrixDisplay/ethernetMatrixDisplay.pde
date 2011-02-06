#include <Wire.h>
#include <SoftwareSerial.h>
#include "WProgram.h"
#include "etherShield.h"

#define START_OF_DATA 0x10
#define END_OF_DATA 0x20

#define PIN_RX 2
#define PIN_TX 3

static uint8_t mymac[6] = {0x54,0x55,0x58,0x10,0x00,0x24};
static uint8_t myip[4]  = {192,168,1,15};

#define BUFFER_SIZE 250
unsigned char buf[BUFFER_SIZE+1];
uint16_t plen, data_p;

SoftwareSerial lcd = SoftwareSerial(PIN_RX, PIN_TX);
EtherShield es = EtherShield();

void setup() {
  // Setup LCD
  initLCD();
  
  // Setup Serial
  Serial.begin(9600);

  // Setup i2c bus
  Wire.begin(1);
  
  // Setup Ethernet
  setupEthernet();
}

void loop() {
  plen = es.ES_enc28j60PacketReceive (BUFFER_SIZE, buf);

  /*plen will be unequal to zero if there is a valid packet (without crc error) */
  if (plen != 0){
    if (es.ES_eth_type_is_arp_and_my_ip (buf,plen)) {
      es.ES_make_arp_answer_from_request (buf);
    }
    // check if ip packets (icmp or udp) are for us:
    if (es.ES_eth_type_is_ip_and_my_ip (buf,plen)!=0) {
      if (buf[IP_PROTO_P] == IP_PROTO_ICMP_V && buf[ICMP_TYPE_P] == ICMP_TYPE_ECHOREQUEST_V) {
        // a ping packet, let's send pong
        es.ES_make_echo_reply_from_request (buf, plen);
      }
      
      Serial.println((int) buf[UDP_LEN_L_P]);
      
      if (buf[IP_PROTO_P] == IP_PROTO_UDP_V && buf[UDP_DST_PORT_H_P] == 4 && buf[UDP_DST_PORT_L_P] == 1
       && buf[UDP_LEN_L_P] == 104 && buf[UDP_LEN_H_P] == 0) {
        lcd.print("P");
        Wire.beginTransmission(0x02);
        Wire.send(START_OF_DATA);
        Wire.send(buf + UDP_DATA_P, 96);
        Wire.send(END_OF_DATA);
        Wire.endTransmission();
      }
    }
  }
}

/* ================================================ */
/* Ethernet Functions */
void setupEthernet() {
  /*initialize enc28j60*/
  es.ES_enc28j60Init (mymac);
  es.ES_enc28j60clkout (2); // change clkout from 6.25MHz to 12.5MHz
  es.ES_enc28j60PhyWrite (PHLCON, 0x476);
  delay (10);
  es.ES_init_ip_arp_udp_tcp (mymac, myip, 80);
}

/* ================================================ */
/* LCD Functions */

void clearLCD() {
  lcd.print(0xFE, BYTE);
  lcd.print(0x01, BYTE);
}

void initLCD() {
  // Start displaying to the user right on boot
  pinMode(PIN_TX, OUTPUT);
  digitalWrite(PIN_TX, HIGH);
  pinMode(PIN_RX, INPUT);
  lcd.begin(9600);
  
  clearLCD();
  lcd.print(0x7C, BYTE);
  lcd.print(0x9D, BYTE);
}
