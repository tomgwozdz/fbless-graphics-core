`default_nettype none

/*
 * Wishbone Registers
 *
 * +------ R/W
 * | +---- Offset from base
 * | | 
 * | |   31    24 23    16 15     8 7      0
 * | |  [........ ........ ........ ........]
 * | | 
 * W 0  [00aaaaaa aaaabbbb bbbbbbcc cccccccc]
 *       aaaaaaaaaa = h_sync_start
 *       bbbbbbbbbb = h_sync_end
 *       cccccccccc = h_active_start
 *
 * W 4  [00aaaaaa aaaabbbb bbbbbbcc cccccccc]
 *       aaaaaaaaaa = v_sync_start
 *       bbbbbbbbbb = v_sync_end
 *       cccccccccc = v_active_start
 *
 * W 8  [00000000 0abcdddd ddddddee eeeeeeee]
 *       a = enabled
 *       b = h_pol
 *       c = v_pol
 *       dddddddddd = h_active_end
 *       eeeeeeeeee = v_active_end
 */

module vga_core (
    input wire clk,
    input wire reset,

    // wishbone interface
    input wire [31:0] wb_addr_i,
    input wire [31:0] wb_data_i,
    output reg [31:0] wb_data_o,

    input wire [3:0] wb_sel_i,
    input wire wb_we_i,
    input wire wb_stb_i,
    input wire wb_cyc_i,

    output reg wb_ack_o,

    // vga interface
    output reg [3:0] vga_r,
    output reg [3:0] vga_g,
    output reg [3:0] vga_b,

    output vga_hs,
    output vga_vs    
);

    reg [9:0] h_sync_start;
    reg [9:0] h_sync_end;
    reg [9:0] h_active_start;
    reg [9:0] h_active_end;

    reg [9:0] v_sync_start;
    reg [9:0] v_sync_end;
    reg [9:0] v_active_start;
    reg [9:0] v_active_end;

    reg h_pol;
    reg v_pol;

    reg enabled;

    wire vga_h_active;
    wire vga_v_active;

    reg [11:0] colors;


    vga_timing vga_timing_0
    (
        .clk (clk),
        .reset (reset),
        .enabled (enabled),

        .h_sync_start (h_sync_start),
        .h_sync_end (h_sync_end),
        .h_active_start (h_active_start),
        .h_active_end (h_active_end),
        .h_pol (h_pol),

        .v_sync_start (v_sync_start),
        .v_sync_end (v_sync_end),
        .v_active_start (v_active_start),
        .v_active_end (v_active_end),
        .v_pol (v_pol),

        .h_sync (vga_hs),
        .v_sync (vga_vs),
        .h_active (vga_h_active),
        .v_active (vga_v_active)
    );


    always @(posedge clk) begin
        if (reset) begin
            h_sync_start <= 0;
            h_sync_end <= 0;
            h_active_start <= 0;
            h_active_end <= 0;

            v_sync_start <= 0;
            v_sync_end <= 0;
            v_active_start <= 0;
            v_active_end <= 0;

            h_pol <= 0;
            v_pol <= 0;
            enabled <= 0;

            wb_ack_o <= 0;
            wb_data_o <= 0;
        end else if(wb_stb_i && wb_cyc_i && wb_we_i && wb_addr_i[31:24] == 8'h04) begin      // Writes
            case (wb_addr_i[4:0])
                4'h0: { h_sync_start, h_sync_end, h_active_start } = wb_data_i;
                4'h4: { v_sync_start, v_sync_end, v_active_start } = wb_data_i;
                4'h8: { enabled, h_pol, v_pol, h_active_end, v_active_end } = wb_data_i;
                4'hc: { colors } = wb_data_i;
            endcase

            wb_ack_o <= 1;
        end else begin
            wb_ack_o <= 0;
        end
    end

    always @(*) begin
        if (vga_h_active && vga_v_active) begin
            vga_r <= colors[11:8];
            vga_g <= colors[7:4];
            vga_b <= colors[3:0];
        end else begin
            vga_r <= 0;
            vga_g <= 0;
            vga_b <= 0;
        end
    end
endmodule
