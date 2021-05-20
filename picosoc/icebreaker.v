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
`default_nettype none

`ifdef PICOSOC_V
`error "icebreaker.v must be read before picosoc.v!"
`endif

`define PICOSOC_MEM ice40up5k_spram

module icebreaker (
	input clk,
	input reset_button,

	output ser_tx,
	input ser_rx,

	output led1,
	output led2,
	output led3,
	output led4,
	output led5,

	input button1,
	input button2,
	input button3,

	output ledr_n,
	output ledg_n,

	output flash_csb,
	output flash_clk,
	inout  flash_io0,
	inout  flash_io1,
	inout  flash_io2,
	inout  flash_io3
);
	parameter integer MEM_WORDS = 32768;


	// Reset logic
	reg [5:0] reset_cnt = 0;
	wire resetn = &reset_cnt;

	always @(posedge clk) begin
		reset_cnt <= reset_cnt + !resetn;
		if (!reset_button) begin
			reset_cnt <= 0;
		end
	end


	// Hook up LEDs and buttons
	wire [7:0] leds;

	assign led1 = leds[1];
	assign led2 = leds[2];
	assign led3 = leds[3];
	assign led4 = leds[4];
	assign led5 = leds[5];

	assign ledr_n = !leds[6];
	assign ledg_n = !leds[7];

	wire [2:0] buttons;

	assign buttons[0] = button1;
	assign buttons[1] = button2;
	assign buttons[2] = button3;


	// Hook up flash
	wire flash_io0_oe, flash_io0_do, flash_io0_di;
	wire flash_io1_oe, flash_io1_do, flash_io1_di;
	wire flash_io2_oe, flash_io2_do, flash_io2_di;
	wire flash_io3_oe, flash_io3_do, flash_io3_di;

	SB_IO #(
		.PIN_TYPE(6'b 1010_01),
		.PULLUP(1'b 0)
	) flash_io_buf [3:0] (
		.PACKAGE_PIN({flash_io3, flash_io2, flash_io1, flash_io0}),
		.OUTPUT_ENABLE({flash_io3_oe, flash_io2_oe, flash_io1_oe, flash_io0_oe}),
		.D_OUT_0({flash_io3_do, flash_io2_do, flash_io1_do, flash_io0_do}),
		.D_IN_0({flash_io3_di, flash_io2_di, flash_io1_di, flash_io0_di})
	);


	// SOC memory bus
	wire        iomem_valid;
	reg         iomem_ready;
	wire [3:0]  iomem_wstrb;
	wire [31:0] iomem_addr;
	wire [31:0] iomem_wdata;
	reg  [31:0] iomem_rdata;


	// Wishbone bus
	reg [31:0] wbm_adr_o;
	reg [31:0] wbm_dat_o;
	wire [31:0] wbm_dat_i;
	reg wbm_we_o;
	reg [3:0] wbm_sel_o;
	reg wbm_stb_o;
	wire wbm_ack_i;
	reg wbm_cyc_o;


	// Wishbone multiplex
    wire [31:0] leds_wbm_dat_i;
    wire leds_wbm_ack_i;
    assign wbm_ack_i = leds_wbm_ack_i;
    assign wbm_dat_i = leds_wbm_dat_i;


	// Wishbone master implementation
	localparam IDLE = 2'b00;
	localparam WBSTART = 2'b01;
	localparam WBEND = 2'b10;

	reg [1:0] state;

	wire we;
	assign we = (iomem_wstrb[0] | iomem_wstrb[1] | iomem_wstrb[2] | iomem_wstrb[3]);

	always @(posedge clk) begin
		if (~resetn) begin
			wbm_adr_o <= 0;
			wbm_dat_o <= 0;
			wbm_we_o <= 0;
			wbm_sel_o <= 0;
			wbm_stb_o <= 0;
			wbm_cyc_o <= 0;
			state <= IDLE;
		end else begin
			case (state)
				IDLE: begin
                    // wishbone is 0x0300_0000 and above
					if (iomem_valid & iomem_addr[31:24] >= 8'h03) begin
						wbm_adr_o <= iomem_addr;
						wbm_dat_o <= iomem_wdata;
						wbm_we_o <= we;
						wbm_sel_o <= iomem_wstrb;

						wbm_stb_o <= 1'b1;
						wbm_cyc_o <= 1'b1;
						state <= WBSTART;
					end else begin
						iomem_ready <= 1'b0;

						wbm_stb_o <= 1'b0;
						wbm_cyc_o <= 1'b0;
						wbm_we_o <= 1'b0;
					end
				end
				WBSTART:begin
					if (wbm_ack_i) begin
						iomem_rdata <= wbm_dat_i;
						iomem_ready <= 1'b1;

						state <= WBEND;

						wbm_stb_o <= 1'b0;
						wbm_cyc_o <= 1'b0;
						wbm_we_o <= 1'b0;
					end
				end
				WBEND: begin
					iomem_ready <= 1'b0;

					state <= IDLE;
				end
				default:
					state <= IDLE;
			endcase
		end
	end	


	// Instantiate the Wishbone LEDs/buttons
    wb_buttons_leds #(.BASE_ADDRESS(32'h03_00_00_00)) wb_buttons_leds_0 (
        .clk        (clk),
        .reset      (~resetn),
        .i_wb_cyc   (wbm_cyc_o),
        .i_wb_stb   (wbm_stb_o),
        .i_wb_we    (wbm_we_o),
        .i_wb_addr  (wbm_adr_o),
        .i_wb_data  (wbm_dat_o),
        .o_wb_ack   (leds_wbm_ack_i),
        .o_wb_data  (leds_wbm_dat_i),
        .buttons    (buttons),
        .leds       (leds)
    );


	// Instantiate the picosoc
	picosoc #(
		.BARREL_SHIFTER(0),
		.ENABLE_MULDIV(0),
		.MEM_WORDS(MEM_WORDS)
	) soc (
		.clk          (clk         ),
		.resetn       (resetn      ),

		.ser_tx       (ser_tx      ),
		.ser_rx       (ser_rx      ),

		.flash_csb    (flash_csb   ),
		.flash_clk    (flash_clk   ),

		.flash_io0_oe (flash_io0_oe),
		.flash_io1_oe (flash_io1_oe),
		.flash_io2_oe (flash_io2_oe),
		.flash_io3_oe (flash_io3_oe),

		.flash_io0_do (flash_io0_do),
		.flash_io1_do (flash_io1_do),
		.flash_io2_do (flash_io2_do),
		.flash_io3_do (flash_io3_do),

		.flash_io0_di (flash_io0_di),
		.flash_io1_di (flash_io1_di),
		.flash_io2_di (flash_io2_di),
		.flash_io3_di (flash_io3_di),

		.irq_5        (1'b0        ),
		.irq_6        (1'b0        ),
		.irq_7        (1'b0        ),

		.iomem_valid  (iomem_valid ),
		.iomem_ready  (iomem_ready ),
		.iomem_wstrb  (iomem_wstrb ),
		.iomem_addr   (iomem_addr  ),
		.iomem_wdata  (iomem_wdata ),
		.iomem_rdata  (iomem_rdata )
	);
endmodule
