/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

#include <stdint.h>
#include <stdbool.h>

// a pointer to this is a null pointer, but the compiler does not
// know that because "sram" is a linker symbol from sections.lds.
extern uint32_t sram;

#define reg_spictrl (*(volatile uint32_t*)0x02000000)
#define reg_leds (*(volatile uint32_t*)0x03000000)

#define vga_collision_reg (*(volatile uint32_t*)0x30000000)
#define vga_buttons_reg (*(volatile uint32_t*)0x30000004)
#define vga_h_reg (*(volatile uint32_t*)0x30000000)
#define vga_v_reg (*(volatile uint32_t*)0x30000004)
#define vga_m_reg (*(volatile uint32_t*)0x30000008)
#define vga_bg0_reg (*(volatile uint32_t*)0x3000000c)
#define vga_bg1_reg (*(volatile uint32_t*)0x30000010)
#define vga_bgs_reg (*(volatile uint32_t*)0x30000014)
#define vga_wait_reg (*(volatile uint32_t*)0x30000018)
#define vga_bg_color_10_reg (*(volatile uint32_t*)0x3000001c)
#define vga_bg_color_32_reg (*(volatile uint32_t*)0x30000020)
#define vga_sprite_0_start_reg (*(volatile uint32_t*)0x30000024)
#define vga_sprite_0_pixels_reg (*(volatile uint32_t*)0x30000028)
#define vga_sprite_0_size_color_1_reg (*(volatile uint32_t*)0x3000002c)
#define vga_sprite_0_color_32_reg (*(volatile uint32_t*)0x30000030)
#define vga_sprite_1_start_reg (*(volatile uint32_t*)0x30000034)
#define vga_sprite_1_pixels_reg (*(volatile uint32_t*)0x30000038)
#define vga_sprite_1_size_color_1_reg (*(volatile uint32_t*)0x3000003c)
#define vga_sprite_1_color_32_reg (*(volatile uint32_t*)0x30000040)
#define vga_sprite_2_start_reg (*(volatile uint32_t*)0x30000044)
#define vga_sprite_2_pixels_reg (*(volatile uint32_t*)0x30000048)
#define vga_sprite_2_size_color_1_reg (*(volatile uint32_t*)0x3000004c)
#define vga_sprite_2_color_32_reg (*(volatile uint32_t*)0x30000050)



// --------------------------------------------------------

extern uint32_t flashio_worker_begin;
extern uint32_t flashio_worker_end;

void flashio(uint8_t *data, int len, uint8_t wrencmd)
{
	uint32_t func[&flashio_worker_end - &flashio_worker_begin];

	uint32_t *src_ptr = &flashio_worker_begin;
	uint32_t *dst_ptr = func;

	while (src_ptr != &flashio_worker_end)
		*(dst_ptr++) = *(src_ptr++);

	((void(*)(uint8_t*, uint32_t, uint32_t))func)(data, len, wrencmd);
}

void set_flash_qspi_flag()
{
	uint8_t buffer[8];

	// Read Configuration Registers (RDCR1 35h)
	buffer[0] = 0x35;
	buffer[1] = 0x00; // rdata
	flashio(buffer, 2, 0);
	uint8_t sr2 = buffer[1];

	// Write Enable Volatile (50h) + Write Status Register 2 (31h)
	buffer[0] = 0x31;
	buffer[1] = sr2 | 2; // Enable QSPI
	flashio(buffer, 2, 0x50);
}

// --------------------------------------------------------


uint32_t bg[] = {	
	0xcccccccc,
	0x88888888,
	0x44444444,
	0x33333333,
	0x22222222,
	0x11111111,
	0xe4e4e4e4,
	0x39393939,
	0x4e4e4e4e,
	0x93939393,
	0x4e4e4e4e,
	0x39393939,
	0xe4e4e4e4,
	0x1b1b1b1b,
	0x6c6c6c6c,
	0xb1b1b1b1,
	0xc6c6c6c6,
	0x1b1b1b1b,
	0x6c6c6c6c,
	0xb1b1b1b1,
	0xc6c6c6c6,
	0x1b1b1b1b,
	0x6c6c6c6c,
	0xb1b1b1b1,
};

uint32_t color3210[] = {
	0x000f000f,
	0x00f00fff,
	0x000e000e,
	0x00e00eee,
	0x000d000d,
	0x00d00ddd,
	0x000c000c,
	0x00c00ccc,
	0x000b000b,
	0x00b00bbb,
	0x000a000a,
	0x00a00aaa,
	0x00090009,
	0x00900999,
	0x00080008,
	0x00800888,
	0x00070007,
	0x00700777,
	0x00060006,
	0x00600666,
	0x00050005,
	0x00500555,
	0x00040004,
	0x00400444,
	0x00030003,
	0x00300333,
	0x00020002,
	0x00200222,
	0x00010001,
	0x00100111,
	0x00000000,
	0x00000000,

	0x00ff0f0f,
	0x000ff777,
	0x0021f3f1,
	0x00ae576e,
	0x0050b181,
	0x00b94b88,
	0x0008bc46,
	0x00b07543,
	0x00913d7e,
	0x006f16b5,
	0x00b3de11,
	0x001feda7,
	0x0092bc61,
	0x00873f91,
};

uint32_t sprite[] = {
	0x00555500,
	0x05bbbb50,
	0x06eeeed0,
	0x7bbbbbb9,
	0x6eeeeeed,
	0x7bbbbbb9,
	0x6eeeeeed,
	0x7bbbbbb9,
	0x6eeeeeed,
	0x7bbbbbb9,
	0x6eeeeeed,
	0x7bbbbbb9,
	0x6eeeeeed,
	0x7bbbbbb9,
	0x6eeeeeed,
	0x7bbbbbb9,
	0x6eeeeeed,
	0x7bbbbbb9,
	0x6eeeeeed,
	0x7bbbbbb9,
	0x6eeeeeed,
	0x7bbbbbb9,
	0x6eeeeeed,
	0x7bbbbbb9,
	0x6eeeeeed,
	0x7bbbbbb9,
	0x06eeeed0,
	0x05bbbb50,
	0x00555500,
	0x00000000
};

__attribute__((section(".data"))) void main_loop()
{
	int line = 0;

	int startX0 = 200;
	int startY0 = 50;
	int startX1 = 200;
	int startY1 = 20;
	int startX2 = 200;
	int startY2 = 100;

	int incrementX0 = 1;
	int incrementY0 = 1;
	int incrementX1 = 1;
	int incrementY1 = -2;
	int incrementX2 = 1;
	int incrementY2 = -3;

	uint32_t next_sprite_pixels_0 = 0;
	uint32_t next_sprite_pixels_1 = 0;
	uint32_t next_sprite_pixels_2 = 0;

	bool collision_0 = 0;
	bool collision_1 = 1;
	bool collision_2 = 2;

	while (1) {
		int index0 = line - startY0;
		int index1 = line - startY1;
		int index2 = line - startY2;

		next_sprite_pixels_0 = 0;
		next_sprite_pixels_1 = 0;
		next_sprite_pixels_2 = 0;
		if (index0 >= 0 && index0 < sizeof(sprite) / 4) {
			next_sprite_pixels_0 = sprite[index0];
			if (collision_0) {
				next_sprite_pixels_0 = ~next_sprite_pixels_0;
			}
		}
		if (index1 >= 0 && index1 < sizeof(sprite) / 4) {
			next_sprite_pixels_1 = sprite[index1];
			if (collision_1) {
				next_sprite_pixels_1 = ~next_sprite_pixels_1;
			}
		}
		if (index2 >= 0 && index2 < sizeof(sprite) / 4) {
			next_sprite_pixels_2 = sprite[index2];
			if (collision_2) {
				next_sprite_pixels_2 = ~next_sprite_pixels_2;
			}
		}

		vga_wait_reg = 0x2600001;
		vga_sprite_0_pixels_reg = next_sprite_pixels_0;
		vga_sprite_0_start_reg = startX0;
		vga_sprite_1_pixels_reg = next_sprite_pixels_1;
		vga_sprite_1_start_reg = startX1;
		vga_sprite_2_pixels_reg = next_sprite_pixels_2;
		vga_sprite_2_start_reg = startX2;
		vga_bg0_reg = line;

		line++;
		if (line > 479) {
			line = 0;

			startX0 += incrementX0;
			startY0 += incrementY0;
			startX1 += incrementX1;
			startY1 += incrementY1;
			// startX2 += incrementX2;
			// startY2 += incrementY2;

			uint32_t buttons = vga_buttons_reg;
			if ((buttons & 0x05) == 0x05) {
				startY2 -= 3;
			} else {
				if ((buttons & 0x04) == 0x04) {
					startX2 += 1;
				}
				if ((buttons & 0x01) == 0x01) {
					startX2 -= 1;
				}
			}
			if ((buttons & 0x02) == 0x02) {
				startY2 += 3;
			}

			if (startX0 > 250 || startX0 < 80) {
				incrementX0 = -incrementX0;
			}
			if (startY0 > 400 || startY0 < 10) {
				incrementY0 = -incrementY0;
			}

			if (startX1 > 250 || startX1 < 80) {
				incrementX1 = -incrementX1;
			}
			if (startY1 > 400 || startY1 < 10) {
				incrementY1 = -incrementY1;
			}

			// if (startX2 > 250 || startX2 < 80) {
			// 	incrementX2 = -incrementX2;
			// }
			// if (startY2 > 400 || startY2 < 10) {
			// 	incrementY2 = -incrementY2;
			// }

			vga_wait_reg = 0x2000000;

			collision_0 = 0;
			collision_1 = 0;
			collision_2 = 0;

			uint32_t collisions = vga_collision_reg;
			// vga_bg1_reg = collisions;
			if (collisions & 0x800) {
				collision_0 = collision_1 = 1;
			}
			if (collisions & 0x400) {
				collision_0 = collision_2 = 1;
			}
			if (collisions & 0x200) {
				collision_1 = collision_2 = 1;
			}
		}				
	}
}

void main()
{
	set_flash_qspi_flag();

	reg_leds = 127;

	vga_bgs_reg = 0x186;

    // # reg 00:
    // # h_sync_start = 18 (00 0001 0010)
    // # h_sync_end = 36 (00 0010 0100)
    // # h_active_start = 63 (00 0011 1111)
    // # = 0x120903f
    // await vga.wbs.send_cycle([WBOp(0x04000000, dat=0x120903f)])

    // # reg 04:
    // # v_sync_start = 1 (00 0000 0001)
    // # v_sync_end = 3 (00 0000 0011)
    // # v_active_start = 29 (00 0001 1101)
    // # = 0x100c1d
    // await vga.wbs.send_cycle([WBOp(0x04000004, dat=0x100c1c)])

    // # reg 08:
    // # enabled = 1 (1)
    // # h_pol = 0 (0)
    // # v_pol = 0 (0)
    // # h_active_end = 276 (01 0001 0100)
    // # v_active_end = 508 (01 1111 1100)
    // # = 0x4451fc



	vga_h_reg = 0x120903f;
	vga_v_reg = 0x100c1d;
	vga_m_reg = 0x4451fc;


	/* A checkry pattern */

	// vga_bg_color_10_reg = 0x00f00fff;
	// vga_bg_color_32_reg = 0x000f000f;

	// int line = 0;
	// int count = 0;

	// vga_wait_reg = 0x2000000;

	// while (1) {
	// 	uint32_t next_line_pixels = bg[line];

	// 	line++;
	// 	if (line == 24) {
	// 		line = 0;
	// 		vga_wait_reg = 0x2000000;
	// 	}

	// 	vga_wait_reg = 0x2600001;
	// 	vga_bg0_reg = next_line_pixels;
	// 	vga_bg1_reg = ~next_line_pixels;

	// 	// 19 lines
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;	
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// }


	/* A color test */

	// vga_bg_color_10_reg = 0x00f00fff;
	// vga_bg_color_32_reg = 0x0001000f;

	// int line = 0;
	// int count = 0;

	// vga_wait_reg = 0x2000000;

	// vga_bg0_reg = 0x1B1B1B1B;
	// vga_bg1_reg = 0x1B1B1B1B;

	// while (1) {
	// 	uint32_t color32 = color3210[line++];
	// 	uint32_t color10 = color3210[line++];

	// 	vga_wait_reg = 0x2600001;
	// 	vga_bg_color_32_reg = color32;
	// 	vga_bg_color_10_reg = color10;

	// 	// 19 lines
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;	
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;
	// 	vga_wait_reg = 0x2600001;

	// 	if (line >= sizeof(color3210) / 4) {
	// 		line = 0;
	// 		vga_wait_reg = 0x2000000;
	// 	}		
	// }


	/* A sprite test */

	vga_bg0_reg = 0x1B1B1B1B;
	vga_bg1_reg = 0x1B1B1B1B;

	vga_bg_color_10_reg = 0x00f00fff;
	vga_bg_color_32_reg = 0x000f000f;

	vga_sprite_0_size_color_1_reg = 0x00000000;
	vga_sprite_0_color_32_reg = 0x00f0fff0;

	vga_sprite_1_size_color_1_reg = 0x00000fff;
	vga_sprite_1_color_32_reg = 0x000007f7;

	vga_sprite_2_size_color_1_reg = 0x00000777;
	vga_sprite_2_color_32_reg = 0x00077707;

	main_loop();
}
