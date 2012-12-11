This is a project aimed at producing an electical LOCK which can be locked and unlocked using a simple call to a GSM number.

The code is not refined at all. It was written simply to prove that it can be done.

The Arduino used in this project is Arduino Uno Rel.3

Both the GPS and Relay shields are from: http://www.seeedstudio.com/


If you want to make it stand-alone, you need to supply power to all three boards. 

  - If you don't supply power to the Rele shield, it will not work.
  - If you leave the GPRS shield powerd by the Arduino it is possible that it will not get enough current to work.

In my code I use digital pin 2 to control one of the Releys from the schield. Unfortunatelly it is not possible to directly stack the Rele shield on top of the GPRS shield because it prevents the GPRS shield from working.

What we have done is to use two jumper cables to connect the GND and DigitalPin 2 to the relay shield.

