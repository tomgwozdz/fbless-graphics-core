`default_nettype none

module fpga_top
(
    input  CLK,

    input RESET_N,

    output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
    output P1B1, P1B2, P1B3, P1B4, P1B7, P1B8, P1B9, P1B10
);

    wire vga_clk;

    wire [3:0] vga_r;
    wire [3:0] vga_g;
    wire [3:0] vga_b;

    wire vga_hs;
    wire vga_vs;

    wire vga_h_active;
    wire vga_v_active;
    wire vga_active;

    wire reset;
    assign reset = ~RESET_N;

    SB_PLL40_PAD #(
        .FEEDBACK_PATH("SIMPLE"),
        .PLLOUT_SELECT("GENCLK"),
        .DIVR(4'b0000),
        .DIVF(7'b1000010),
        .DIVQ(3'b101),
        .FILTER_RANGE(3'b001)
    ) vga_clk_pll (
        .PACKAGEPIN(CLK),
        .PLLOUTCORE(vga_clk),
        .RESETB(1'b1),
        .BYPASS(1'b0)
    );

    vga_timing vga_timing_0
    (
        .clk (vga_clk),
        .reset (reset),
        .h_sync (vga_hs),
        .v_sync (vga_vs),
        .h_active (vga_h_active),
        .v_active (vga_v_active),
        .active (vga_active)
    );

    assign vga_r = vga_active ? 4'b1111 : 4'b0000;
    assign vga_g = vga_active ? 4'b1111 : 4'b0000;
    assign vga_b = vga_active ? 4'b1111 : 4'b0000;

    assign {     P1A1,     P1A2,     P1A3,     P1A4,     P1A7,     P1A8,     P1A9,    P1A10 } =
           { vga_r[3], vga_r[2], vga_r[1], vga_r[0], vga_b[3], vga_b[2], vga_b[1], vga_b[0] };
    assign {     P1B1,     P1B2,     P1B3,     P1B4,     P1B7,     P1B8 } =
           { vga_g[3], vga_g[2], vga_g[1], vga_g[0],   vga_hs,   vga_vs };

endmodule
