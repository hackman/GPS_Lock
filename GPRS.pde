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
char c = '\0';
char line[BUFSIZE] = {'\0'};
char line_pos = 0;

void read_resp() {
	char c;
	int ready_chars = 0;
	line_pos = 0;   // Reset array counter
	memset(line, '\0', BUFSIZE);
	ready_chars = cell.available();

	if (ready_chars <= 0)   // No characters for reading.
		return;
	for (int i = 1; i <= ready_chars; i++) {
		if ( line_pos == BUFSIZE - 2)
			return;
		c = cell.read();
		Serial.print(c);
		line[line_pos] = c;
		line_pos++;
	}
	Serial.print("Parsed line: |");
	Serial.print(line);
	Serial.print("|\n");
	return;
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

}


/* vim: setlocal ft=cpp: */
