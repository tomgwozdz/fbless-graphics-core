`default_nettype none

module vga_top (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);

vga_core vga_core_0 (
    `ifdef USE_POWER_PINS
	.vdda1(vdda1),	// User area 1 3.3V power
	.vdda2(vdda2),	// User area 2 3.3V power
	.vssa1(vssa1),	// User area 1 analog ground
	.vssa2(vssa2),	// User area 2 analog ground
	.vccd1(vccd1),	// User area 1 1.8V power
	.vccd2(vccd2),	// User area 2 1.8V power
	.vssd1(vssd1),	// User area 1 digital ground
	.vssd2(vssd2),	// User area 2 digital ground
    `endif

    .clk(wb_clk_i),
    .reset(wb_rst_i),

    // MGMT SoC Wishbone Slave

    .wb_cyc_i(wbs_cyc_i),
    .wb_stb_i(wbs_stb_i),
    .wb_we_i(wbs_we_i),
    .wb_sel_i(wbs_sel_i),
    .wb_addr_i(wbs_adr_i),
    .wb_data_i(wbs_dat_i),
    .wb_ack_o(wbs_ack_o),
    .wb_data_o(wbs_dat_o),

    .vga_r(vga_r),
    .vga_g(vga_g),
    .vga_b(vga_b),

    .vga_hs(vga_hs),
    .vga_vs(vga_vs),

    .buttons(buttons)
);

    assign la_data_out = 0;
    assign user_irq = 0;

    // vga core interface
    wire [3:0] vga_r;
    wire [3:0] vga_g;
    wire [3:0] vga_b;

    wire vga_hs;
    wire vga_vs;

    wire [11:0] buttons;

    // IO Pads
    assign io_out[37:26] = 0;
    assign io_out[25:12] = { vga_hs, vga_vs, vga_r, vga_g, vga_b };
    assign io_out[11:0] = 0;

    assign io_oeb[37:26] = {(12){1'b1}};
    assign io_oeb[25:12] = {(14){wb_rst_i}};
    assign io_oeb[11:0] = {(12){1'b1}};

    assign buttons = io_in[37:26];

endmodule	// user_project_wrapper

`default_nettype wire
