/*
 * OTOswitch
 * ATMEL ATtiny13a firmware
 *
 * *** Fuse settings ***
 * CKDIV8 ON
 * SUT_CKSEL Int. RC Osc. 4.8MHz; Start-up time: 14 CK + 0ms
 *
 * **** Pin assignments: ****
 *
 * AVR     	Descriptions
 * /RST		Reset
 * PB4		Modulated signal output
 * Others	open
 * 
 * ****
 *
 * Copyright (c) 2012, AKIHIRO Uehara (u-akihiro@wa-fu-u.com)
 * All rights reserved. WA-FU-U, LLC. 
 *
 * Revision history:
 * Rev 1.0 2012/May/09 Akihiro Uehara
 *    initial release
 */
#include <avr/io.h>
#include <avr/eeprom.h>
#include <avr/interrupt.h>
#include <util/crc16.h>

// Every byte contains 4-bit information.
// Bit arrangement of the data D<3:0> is as the folloing:
//
// D<0> /D<0> D<1> /D<1> ...

uint8_t EEMEM devide_id[1] = {
 0x01, // ID
  };

void delay(uint8_t time)
{
	volatile uint8_t cnt = time;
	while(cnt > 0) {cnt--;}
}

// convert 2-bit data into encoded 4-bit data
uint8_t cnv2b4b(uint8_t data) 
{
    switch( data & 0x03) {
		case 0x00: return 0x05;
		case 0x01: return 0x09;
		case 0x02: return 0x06;
		case 0x03: return 0x0a;
	}
}

uint8_t cnv4b8b(uint8_t data)
{
	return cnv2b4b(data) << 4 | cnv2b4b(data >> 2);
}

int main()
{
//	cli();

	// Set power reduction register. disable timer and adc.
	// Set Pin In/Out directions
	DDRB  = 0x10; // PB<4> output, PB5, PB<3:0> input
	PORTB = 0x2f; // pull-up enable
	 
	// load prom data
	uint8_t ram_data[8];
	for(int i=0; i < 8; i++) {
		ram_data[i] = 0xff;
	}
	ram_data[1] = 0x7e; // SYNC char
	uint8_t id = eeprom_read_byte((unsigned char *)0);
	ram_data[2] = cnv4b8b(id);
	ram_data[3] = cnv4b8b(id >> 4);
	
	uint8_t delta_t = 0;
	uint8_t j = 0;
	uint8_t pattern = 0;

	for(;;) {
	uint8_t portb_data = PINB & 0x0f;
	ram_data[4] = cnv4b8b(portb_data);

	for(uint8_t i = 0; i < 8; i++) {
		pattern = ram_data[i];
		for(j =0; j < 8; j++) {
			// read a bit
			delta_t = (pattern & 0x01) ? (23 -1): 46; //
				
			// output a pulse
			PORTB = 0x2f;
			delay(delta_t);
			pattern >>= 1;
				
			PORTB = 0x3f;
			delay(delta_t);
		}	
	}
	}
}
