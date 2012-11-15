/*
 * Copyright (C) 2012 Marian Marinov <mm@yuhu.biz>
 *
 * This code was developed by Marian Marinov with the help of Ivan Karpov.
 *
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 *
 *
 *  VERSION 0.2
 */

#include <NewSoftSerial.h>

#define BUFFSIZ 90 // plenty big
#define PC_SERIAL_SPEED 19200

/* SIM900 configuration
NewSoftSerial mySerial = NewSoftSerial(7, 8);
#define RELE 2
#define CELL_SERIAL_SPEED 19200
*/

NewSoftSerial mySerial = NewSoftSerial(2, 3);
#define RELE 7
#define CELL_SERIAL_SPEED 9600

char *mynum  =  "359886660270";
char *karpov =  "359885888444";
char c;

void setup() {
	// Initialize the RELAY
	pinMode(RELE, OUTPUT);
	digitalWrite(RELE, LOW);
	delay(500);
	digitalWrite(RELE, HIGH);
	delay(500);
	digitalWrite(RELE, LOW);

	// Initialize the serial communication to the GPRS and PC
	mySerial.begin(CELL_SERIAL_SPEED);	// the GPRS baud rate
	Serial.begin(PC_SERIAL_SPEED);		// the PC Serial interface boud rate

	delay(500);
	while(1) {
		if (mySerial.available()) {
			c = mySerial.read();
			Serial.print(c);
// SIM900 ending
//			if ( c == 'K' ) {
// SM5100B ending
			if ( c == '3' ) {
				Serial.print("\n");
				break;
			}
		}
	}
}
 
void loop() {
	char buffer[BUFFSIZ] = { '\0' };
	char *fuf = buffer;
	char *buf = buffer;

	int buffidx = 0;
	int myread = 0;
/*
	if ( Serial.available() ) {
		c = Serial.read();
		if ( c = 't' ) 
			SubmitHttpRequest();
	}
	if (mySerial.available())
		Serial.write(mySerial.read());
*/
	if ( mySerial.available() ) {
		char b;
		int j = 0;
		buffidx = 0;
		while (1) {
			c = mySerial.read();

			if ( c == -1 )
				continue;

			if ( c == '+' ) {
				myread = 1;
				j = 0;
				continue;
			}

			if ( myread ) {
				if ( j == 0 && ! isdigit(c) )
					continue;
				if ( j == 1 ) {
					b = c;
					if ( ! isdigit(b) ) {
						myread = 0;
						continue;
					}
				}
				j++;

				if ( c == ',' ) {
					myread = 0;
					buffidx = 0;
					break;
				}

				if ( buffidx <= BUFFSIZ-1 ) {
					if ( c == '"' )
						continue;
					*fuf = c;
					fuf++;
				}
			}
			buffidx++;
		}
	}
	Serial.print("My num: ");
	Serial.println(buf);

	if (match_num(buf, mynum) == 1 || match_num(buf, karpov) == 1) {
		Serial.println("Number matched!\n");
		digitalWrite(RELE, HIGH);
		delay(500);
		digitalWrite(RELE, LOW);
	} else {
		Serial.println("Number NOT matched!");
	}

}


void ShowSerialData() {
	while(mySerial.available()!=0)
		Serial.write(mySerial.read());
}

void SubmitHttpRequest() {
  mySerial.println("AT+CSQ");
  delay(100);
 
 ShowSerialData();// this code is to show the data from gprs shield, in order to easily see the process of how the gprs shield submit a http request, and the following is for this purpose too.

  mySerial.println("AT+CGATT?");
  delay(100);
 
  ShowSerialData();
 
  mySerial.println("AT+SAPBR=3,1,\"CONTYPE\",\"GPRS\"");//setting the SAPBR, the connection type is using gprs
  delay(1000);
 
  ShowSerialData();
 
  mySerial.println("AT+SAPBR=3,1,\"APN\",\"MTEL\"");//setting the APN, the second need you fill in your local apn server
  delay(4000);
 
  ShowSerialData();
 
  mySerial.println("AT+SAPBR=1,1");//setting the SAPBR, for detail you can refer to the AT command mamual
  delay(2000);
 
  ShowSerialData();
 
  mySerial.println("AT+HTTPINIT"); //init the HTTP request
 
  delay(2000); 
  ShowSerialData();
 
  mySerial.println("AT+HTTPPARA=\"URL\",\"hydra.azilian.net/m.tst\"");// setting the httppara, the second parameter is the website you want to access
  delay(1000);
 
  ShowSerialData();
 
  mySerial.println("AT+HTTPACTION=0");//submit the request 
  delay(10000);//the delay is very important, the delay time is base on the return from the website, if the return datas are very large, the time required longer.
  //while(!mySerial.available());
 
  ShowSerialData();
 
  mySerial.println("AT+HTTPREAD");// read the data from the website you access
  delay(300);
 
  ShowSerialData();
 
  mySerial.println("");
  delay(100);
}
 
int match_num(char *in, char *my) {
	int i = 0;
	for ( ; i <= 12; i++ ) {
		if ( *in != *my ) 
			return 0;
		in++;
		my++;
	}
	return 1;
} 

/* vim: setlocal ft=cpp: */
