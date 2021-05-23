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
#define reg_uart_clkdiv (*(volatile uint32_t*)0x02000004)
#define reg_uart_data (*(volatile uint32_t*)0x02000008)
#define reg_leds (*(volatile uint32_t*)0x03000000)

#define vga_h_reg (*(volatile uint32_t*)0x04000000)
#define vga_v_reg (*(volatile uint32_t*)0x04000004)
#define vga_m_reg (*(volatile uint32_t*)0x04000008)
#define vga_bg0_reg (*(volatile uint32_t*)0x0400000c)
#define vga_bg1_reg (*(volatile uint32_t*)0x04000010)
#define vga_bgs_reg (*(volatile uint32_t*)0x04000014)
#define vga_wait_reg (*(volatile uint32_t*)0x04000018)
#define vga_bg_color_10_reg (*(volatile uint32_t*)0x0400001c)
#define vga_bg_color_32_reg (*(volatile uint32_t*)0x04000020)


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

void putchar(char c)
{
	if (c == '\n')
		putchar('\r');
	reg_uart_data = c;
}

void print(const char *p)
{
	while (*p)
		putchar(*(p++));
}

void print_hex(uint32_t v, int digits)
{
	for (int i = 7; i >= 0; i--) {
		char c = "0123456789abcdef"[(v >> (4*i)) & 15];
		if (c == '0' && i >= digits) continue;
		putchar(c);
		digits = i;
	}
}

void print_dec(uint32_t v)
{
	if (v >= 1000) {
		print(">=1000");
		return;
	}

	if      (v >= 900) { putchar('9'); v -= 900; }
	else if (v >= 800) { putchar('8'); v -= 800; }
	else if (v >= 700) { putchar('7'); v -= 700; }
	else if (v >= 600) { putchar('6'); v -= 600; }
	else if (v >= 500) { putchar('5'); v -= 500; }
	else if (v >= 400) { putchar('4'); v -= 400; }
	else if (v >= 300) { putchar('3'); v -= 300; }
	else if (v >= 200) { putchar('2'); v -= 200; }
	else if (v >= 100) { putchar('1'); v -= 100; }

	if      (v >= 90) { putchar('9'); v -= 90; }
	else if (v >= 80) { putchar('8'); v -= 80; }
	else if (v >= 70) { putchar('7'); v -= 70; }
	else if (v >= 60) { putchar('6'); v -= 60; }
	else if (v >= 50) { putchar('5'); v -= 50; }
	else if (v >= 40) { putchar('4'); v -= 40; }
	else if (v >= 30) { putchar('3'); v -= 30; }
	else if (v >= 20) { putchar('2'); v -= 20; }
	else if (v >= 10) { putchar('1'); v -= 10; }

	if      (v >= 9) { putchar('9'); v -= 9; }
	else if (v >= 8) { putchar('8'); v -= 8; }
	else if (v >= 7) { putchar('7'); v -= 7; }
	else if (v >= 6) { putchar('6'); v -= 6; }
	else if (v >= 5) { putchar('5'); v -= 5; }
	else if (v >= 4) { putchar('4'); v -= 4; }
	else if (v >= 3) { putchar('3'); v -= 3; }
	else if (v >= 2) { putchar('2'); v -= 2; }
	else if (v >= 1) { putchar('1'); v -= 1; }
	else putchar('0');
}

char getchar_prompt(char *prompt)
{
	int32_t c = -1;

	uint32_t cycles_begin, cycles_now, cycles;
	__asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));

	reg_leds = ~0;

	if (prompt)
		print(prompt);

	while (c == -1) {
		__asm__ volatile ("rdcycle %0" : "=r"(cycles_now));
		cycles = cycles_now - cycles_begin;
		if (cycles > 12000000) {
			if (prompt)
				print(prompt);
			cycles_begin = cycles_now;
			reg_leds = ~reg_leds;
		}
		c = reg_uart_data;
	}

	reg_leds = 0;
	return c;
}

char getchar()
{
	return getchar_prompt(0);
}

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

void main()
{
	reg_uart_clkdiv = 104;

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
    // # v_active_start = 28 (00 0001 1100)
    // # = 0x100c1c
    // await vga.wbs.send_cycle([WBOp(0x04000004, dat=0x100c1c)])

    // # reg 08:
    // # enabled = 1 (1)
    // # h_pol = 0 (0)
    // # v_pol = 0 (0)
    // # h_active_end = 276 (01 0001 0100)
    // # v_active_end = 508 (01 1111 1100)
    // # = 0x4451fc



	vga_h_reg = 0x120903f;
	vga_v_reg = 0x100c1c;
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

	vga_bg_color_10_reg = 0x00f00fff;
	vga_bg_color_32_reg = 0x0001000f;

	int line = 0;
	int count = 0;

	vga_wait_reg = 0x2000000;

	vga_bg0_reg = 0x1B1B1B1B;
	vga_bg1_reg = 0x1B1B1B1B;

	while (1) {
		uint32_t color32 = color3210[line++];
		uint32_t color10 = color3210[line++];

		vga_wait_reg = 0x2600001;
		vga_bg_color_32_reg = color32;
		vga_bg_color_10_reg = color10;

		// 19 lines
		vga_wait_reg = 0x2600001;
		vga_wait_reg = 0x2600001;	
		vga_wait_reg = 0x2600001;
		vga_wait_reg = 0x2600001;
		vga_wait_reg = 0x2600001;
		vga_wait_reg = 0x2600001;
		vga_wait_reg = 0x2600001;
		vga_wait_reg = 0x2600001;
		vga_wait_reg = 0x2600001;
		vga_wait_reg = 0x2600001;
		vga_wait_reg = 0x2600001;
		vga_wait_reg = 0x2600001;
		vga_wait_reg = 0x2600001;
		vga_wait_reg = 0x2600001;
		vga_wait_reg = 0x2600001;
		vga_wait_reg = 0x2600001;
		vga_wait_reg = 0x2600001;
		vga_wait_reg = 0x2600001;
		vga_wait_reg = 0x2600001;

		if (line >= sizeof(color3210) / 4) {
			line = 0;
			vga_wait_reg = 0x2000000;
		}		
	}

}
