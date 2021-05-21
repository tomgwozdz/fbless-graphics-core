`default_nettype none

module fpga_top
(
    input  CLK,

    input RESET_N,

    output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
    output P1B1, P1B2, P1B3, P1B4, P1B7, P1B8, P1B9, P1B10
);

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

    vga_timing vga_timing_0
    (
        .clk (CLK),
        .reset (reset),
        .enabled (1'b1),

        .h_sync_start (18),     // 56 / 3 = 18.6
        .h_sync_end (36),       // (56 + 56) / 3 = 37.3
        .h_active_start (63),   // (56 + 56 + 80) / 3 = 64
        .h_active_end (276),    // (56 + 56 + 80 + 640) / 3 = 277.3
        .h_pol (1),

        .v_sync_start (1),      // 1
        .v_sync_end (3),        // 1 + 3 = 4
        .v_active_start (28),   // 1 + 3 + 25 = 29
        .v_active_end (508),    // 1 + 3 + 25 + 480 = 509
        .v_pol (1),

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
