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
 *  VERSION 1.0
 */

#include <NewSoftSerial.h>

#define DEBUG
#define PC_SERIAL_SPEED 19200
#define BUFSIZE 512
#define PHONE_SIZE 16
#define PHONE_NUMBERS 2
#define NUMBER_MM 		"359886660270"
#define NUMBER_KARPOV	"359885888444"


// SIM900 configuration (SeeedStudio)
/*
NewSoftSerial cell = NewSoftSerial(7, 8);
#define UNLOCK_PIN 2
#define CELL_SERIAL_SPEED 19200
*/

// SM5100B configuration (SparkFun)
NewSoftSerial cell = NewSoftSerial(2, 3);
#define UNLOCK_PIN 7
#define CELL_SERIAL_SPEED 9600


char allowed[PHONE_NUMBERS][PHONE_SIZE];
char line[BUFSIZE] = {'\0'};
char line_pos = 0;
char phone_str[PHONE_SIZE] = {'\0'};
char *phone_ptr = phone_str;
int gprs_connected = 0;
int gprs_initialized = 0;
int unlock = 0;
int list_sms = 0;



void read_resp(int stop_on_new_line) {
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
		if ( stop_on_new_line && c == '\n' ) {
			line[line_pos] = '\0';
			return;
		}
	}

	line[line_pos] = '\0';
	return;
}

void configure_gprs(void) {
	// Show remote caller ID
	cell.println("AT+CLIP=1");
	Serial.println("GSM set CLIP on. Now we will see incomming caller IDs.");
	delay(1000);

	// Display messages when received
	cell.println("AT+CNMI=3,3,0,0");
	Serial.println("GSM show SMS messages as they come in");
	delay(1000);

	// Set SMS MODE to TEXT
	cell.println("AT+CMGF=1");
	Serial.println("GSM set SMS MODE to TEXT.");
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

void parse_phone(char *str) {
	int quote_count = 0;
	memset(phone_str, '\0', 16);

	for (int i = 0; i < BUFSIZE; i++) {
		// End of the string
		if (*str == '\0')
			return;

		// Quote found, increase the counter and move the pointer forward
		if (*str == '"') {
			quote_count++;
			*str++;
			continue;
		}

		// End of the phone number
		if (quote_count == 4)
			return;

		// Copy the phone number
		if (quote_count == 3) {
			*phone_ptr = *str;
			phone_ptr++;
		}

		str++;
	}
}

void check_sms() {
	if (strstr(line, "unlock") != 0 && strstr(line, "1234") != 0) {
		Serial.println("Found command UNLOCK and matched security code.");
		unlock = 1;
	}
	if (strstr(line, "+CMGL") != 0) {
		parse_phone(line);
		Serial.print("\nPhone: ");
		Serial.print(phone_str);
		Serial.print("\n");
		check_number(phone_str);
	}
}

void read_sms(void) {
	if (list_sms == 0) {
		cell.println("AT+CMGL=\"ALL\"");
		list_sms++;
	}

	read_resp(1);
	check_sms();
}

int check_number(char *phone) {
	Serial.print("\nPhone number (");
	Serial.print(phone);
	for (int i=0; i < PHONE_NUMBERS; i++) {
		if (strncmp(phone, allowed[i], 12) == 0) {
			Serial.print(") MATCHED\n");
			return 1;
		}
	}
	Serial.print(") NOT matched\n");
	return 0;
}

void add_numbers(void) {
	Serial.println("Allowed phone numbers:");

	memset(allowed[0], '\0', PHONE_SIZE);
	strcat(allowed[0], NUMBER_MM);
	Serial.println(allowed[0]);

	memset(allowed[1], '\0', PHONE_SIZE);
	strcat(allowed[1], NUMBER_KARPOV);
	Serial.println(allowed[1]);
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

	add_numbers();
}

void loop() {
	while (gprs_connected == 0 || gprs_initialized == 0) {
		read_resp(1);
		delay(500);
		parse_resp();
	}
	if (unlock == 0)
		read_sms();

// This is used for debuging and manual testing
//	DirectToSerial();

}

void DirectToSerial(void) {
	char c;
	if (cell.available() > 0) {
		c = cell.read();
		Serial.print(c);
	}
	if (Serial.available() > 0) {
		c = Serial.read();
		Serial.print(c);
		cell.print(c);
	}
}

/* vim: setlocal ft=cpp: */
