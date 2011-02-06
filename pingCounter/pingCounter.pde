#include "etherShield.h"
#include <SoftwareSerial.h>

// please modify the following two lines. mac and ip have to be unique
// in your local area network. You can not have the same numbers in
// two devices:
static uint8_t mymac[6] = {0x54,0x55,0x58,0x10,0x00,0x24};
static uint8_t myip[4]  = {192,168,1,15};
// how did I get the mac addr? Translate the first 3 numbers into ascii is: TUX

#define BUFFER_SIZE 250
unsigned char buf[BUFFER_SIZE+1];

#define rxPin 2
#define txPin 3

SoftwareSerial lcd = SoftwareSerial(rxPin, txPin);

long unsigned int pingCount = 0;

uint16_t plen;

EtherShield es = EtherShield();

void clearLCD() {
  lcd.print(0xFE, BYTE);
  lcd.print(0x01, BYTE);
}

void initLCD() {
  clearLCD();
  lcd.print(0x7C, BYTE);
  lcd.print(0x9D, BYTE);
}

void printNum(long unsigned int num) {
  lcd.print(0xFE, BYTE);
  lcd.print(0x87, BYTE);
  lcd.print(num);
}

void setup(){
  pinMode(txPin, OUTPUT);
  digitalWrite(txPin, HIGH);
  pinMode(rxPin, INPUT);
  lcd.begin(9600);
  
  clearLCD();
  
  /*initialize enc28j60*/
  es.ES_enc28j60Init (mymac);
  es.ES_enc28j60clkout (2); // change clkout from 6.25MHz to 12.5MHz
  
  /* Turn off Ethernet LEDS */
  // 0x990 is PHLCON LEDB=off, LEDA=off
  // enc28j60PhyWrite(PHLCON,0b0000 1001 1001 00 00);
  es.ES_enc28j60PhyWrite (PHLCON, 0x990);
  
  // Put a message on the screen
  lcd.print("    Ping Me!    ");
  lcd.print((int)myip[0]);
  lcd.print(".");
  lcd.print((int)myip[1]);
  lcd.print(".");
  lcd.print((int)myip[2]);
  lcd.print(".");
  lcd.print((int)myip[3]);

  // Leave message for a while
  delay (5000);

  // Setup LED 
  es.ES_enc28j60PhyWrite (PHLCON, 0x476);
  delay (10);

  //init the ethernet/ip layer:
  es.ES_init_ip_arp_udp_tcp (mymac, myip, 80);

  // Switch LCD to normal mode
  clearLCD();
  lcd.print("Pings: 0");
}

void loop(){
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
        printNum(pingCount++);
      }
    }
  }
}
