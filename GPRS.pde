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
 *  VERSION 0.3
 */

#include <NewSoftSerial.h>

#define DEBUG
#define BUFFSIZ 90 // plenty big
#define PC_SERIAL_SPEED 19200

/* SIM900 configuration
NewSoftSerial cell = NewSoftSerial(7, 8);
#define UNLOCK_PIN 2
#define CELL_SERIAL_SPEED 19200
*/

NewSoftSerial cell = NewSoftSerial(2, 3);
#define UNLOCK_PIN 7
#define CELL_SERIAL_SPEED 9600
#define BUFSIZE 512

char *mynum  =  "359886660270";
char *karpov =  "359885888444";
char line[BUFSIZE] = {'\0'};
char line_pos = 0;

int gprs_connected = 0;
int gprs_initialized = 0;

int unlock = 0;
char phone_num[16] = {'\0'};
char *phone = phone_num;

void read_resp() {
	char c;
	line_pos = 0;   // Reset array counter
	memset(line, '\0', BUFSIZE);

	while ( cell.available() > 0 && line_pos < BUFSIZE ) {
		c = cell.read();
#ifdef DEBUG
		Serial.print(c);
#endif
		line[line_pos] = c;
		line_pos++;
		if ( c == '\n' )
			return;
	}

	return;
}

void configure_gprs(void) {
	// Show remote caller ID
	cell.println("AT+CLIP=1");
	Serial.println("GSM set CLIP on. Now we will see incomming caller IDs.");
	delay(1000);

	// Set SMS MODE to TEXT
	cell.println("AT+CMGF=1");
	Serial.println("GSM set SMS MODE to TEXT.");
	delay(1000);

	// Display messages when received
	cell.println("AT+CNMI=3,3,0,0");
	Serial.println("GSM show SMS messages as they come in");
	delay(1000);
}

void parse_resp(void) {
	if (strstr(line, "+SIND: 11") != 0) {
		Serial.println("GPRS module registered to network");
		gprs_connected++;
		return;
	}
	if (strstr(line, "+SIND: 4") != 0) {
		Serial.println("GPRS module ready for AT commands");
		gprs_initialized++;
		configure_gprs();
		return;
	}
}

char * parse_phone(char *str) {
	int quote_count = 0;
	char phone_str[16] = {'\0'};
	char *phone_ptr = phone_str;
	memset(phone_str, '\0', 16);
	for (int i = 0; i < BUFSIZE; i++) {
		// End of the string
		if (*str == '\0')
			return phone_str;

		// Quote found, increase the counter and move the pointer forward
		if (*str == '"') {
			quote_count++;
			*str++;
			continue;
		}

		// Copy the phone number
		if (quote_count == 3) {
			*phone_ptr = *str;
			phone_ptr++;
		}

		// End of the phone number
		if (quote_count == 4) {
			return phone_str;
		}
		str++;
	}
}

void read_sms(void) {
	cell.println("AT+CMGL=\"ALL\"");
	delay(5000);
	while(cell.available() > 0) {
		read_resp();
		delay(1000);
		if (strstr(line, "unlock") != 0 && strstr(line, "1234") != 0) {
			Serial.println("Found command UNLOCK and matched security code.");
			unlock = 1;
			break;
		}
		if (strstr(line, "+CMGL") != 0) {
			Serial.print("\nPhone: ");
			Serial.print(parse_phone(line));
			Serial.print("\n");
		}
	}
}

void setup() {
	// Initialize the RELAY
	pinMode(UNLOCK_PIN, OUTPUT);

#ifdef DEBUG
	digitalWrite(UNLOCK_PIN, LOW);
	delay(500);
	digitalWrite(UNLOCK_PIN, HIGH);
	delay(500);
#endif
	digitalWrite(UNLOCK_PIN, LOW);

	// Initialize the serial communication to the GPRS and PC
	cell.begin(CELL_SERIAL_SPEED);	// the GPRS baud rate
	Serial.begin(PC_SERIAL_SPEED);	// the PC Serial interface boud rate
}

void loop() {
	while (gprs_connected == 0 || gprs_initialized == 0) {
		read_resp();
		delay(500);
		parse_resp();
	}
	if (unlock == 0)
		read_sms();
}


/* vim: setlocal ft=cpp: */
