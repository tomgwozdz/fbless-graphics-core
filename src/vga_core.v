`default_nettype none

/*
 * Wishbone Registers
 *
 * +------ R/W
 * |  +---- Offset from base
 * |  | 
 * |  |   31    24 23    16 15     8 7      0
 * |  |  [........ ........ ........ ........]
 * |  | 
 * W 00  [00aaaaaa aaaabbbb bbbbbbcc cccccccc]
 *        aaaaaaaaaa = h_sync_start
 *        bbbbbbbbbb = h_sync_end
 *        cccccccccc = h_active_start
 *
 * W 04  [00aaaaaa aaaabbbb bbbbbbcc cccccccc]
 *        aaaaaaaaaa = v_sync_start
 *        bbbbbbbbbb = v_sync_end
 *        cccccccccc = v_active_start
 *
 * W 08  [00000000 0abcdddd ddddddee eeeeeeee]
 *        a = enabled
 *        b = h_pol
 *        c = v_pol
 *        dddddddddd = h_active_end
 *        eeeeeeeeee = v_active_end
 *
 * W 0C  [aaaaaaaa aaaaaaaa aaaaaaaa aaaaaaaa]
 *        a = background 0 pixels
 * 
 * W 10  [aaaaaaaa aaaaaaaa aaaaaaaa aaaaaaaa]
 *        a = background 1 pixels
 *
 * W 14  [00000000 00000000 0000aaaa aabbbbbb]
 *        a = background 0 pixel width
 *        b = background 1 pixel width
 *
 *       Wait for condition
 * W 18  [000000ee eedcbbbb bbbbbbaa aaaaaaaa]
 *        a = expected horizontal count
 *        b = expected veritcal count
 *        c = expected h active
 *        d = expected v active
 *        e = [check v active, check h active, check vertical count, check horizonal count]
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

    output reg vga_hs,
    output reg vga_vs    
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

    wire vga_h_sync;
    wire vga_v_sync;

    wire vga_h_active;
    wire vga_v_active;

    wire [9:0] h_counter;
    wire [9:0] v_counter;

    reg [31:0] bg_pixels;
    reg bg_pixels_load_0;
    reg bg_pixels_load_1;

    reg [5:0] bg_size_0;
    reg [5:0] bg_size_1;

    wire [1:0] bg_color_index;

    reg [9:0] cond_h_count;
    reg [9:0] cond_v_count;
    reg cond_h_active;
    reg cond_v_active;
    reg cond_check_v_active;
    reg cond_check_h_active;
    reg cond_check_v_count;
    reg cond_check_h_count;

    reg cond_met;


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

        .h_sync (vga_h_sync),
        .v_sync (vga_v_sync),
        .h_active (vga_h_active),
        .v_active (vga_v_active),

        .h_counter (h_counter),
        .v_counter (v_counter)
    );


    vga_background vga_background_0 (
        .clk (clk),
        .reset (reset),

        .h_active (vga_h_active),
        .v_active (vga_v_active),

        .bg_pixels (bg_pixels),
        .bg_pixels_load_0 (bg_pixels_load_0),
        .bg_pixels_load_1 (bg_pixels_load_1),

        .bg_size_0 (bg_size_0),
        .bg_size_1 (bg_size_1),

        .bg_color_index (bg_color_index)
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

            bg_pixels_load_0 <= 0;
            bg_pixels_load_1 <= 0;

            cond_h_count <= 0;
            cond_v_count <= 0;
            cond_h_active <= 0;
            cond_v_active <= 0;
            cond_check_v_active <= 0;
            cond_check_h_active <= 0;
            cond_check_v_count <= 0;
            cond_check_h_count <= 0;
        end else if(wb_stb_i && wb_cyc_i && wb_we_i && wb_addr_i[31:24] == 8'h04) begin      // Writes
            case (wb_addr_i[7:0])
                8'h00: begin
                    { h_sync_start, h_sync_end, h_active_start } = wb_data_i;
                    wb_ack_o <= 1;
                end
                8'h04: begin
                    { v_sync_start, v_sync_end, v_active_start } = wb_data_i;
                    wb_ack_o <= 1;
                end
                8'h08: begin
                    { enabled, h_pol, v_pol, h_active_end, v_active_end } = wb_data_i;
                    wb_ack_o <= 1;
                end
                8'h0c: begin
                    { bg_pixels } = wb_data_i;
                    bg_pixels_load_0 <= 1;
                    wb_ack_o <= 1;
                end
                8'h10: begin
                    { bg_pixels } = wb_data_i;
                    bg_pixels_load_1 <= 1;
                    wb_ack_o <= 1;
                end
                8'h14: begin
                    { bg_size_0, bg_size_1 } = wb_data_i;
                    wb_ack_o <= 1;
                end
                8'h18: begin
                    { cond_check_v_active, cond_check_h_active, cond_check_v_count, cond_check_h_count,
                      cond_v_active, cond_h_active, cond_v_count, cond_h_count } = wb_data_i;

                    if (cond_met) begin
                        wb_ack_o <= 1;
                        cond_check_v_active <= 0;
                        cond_check_h_active <= 0;
                        cond_check_v_count <= 0;
                        cond_check_h_count <= 0;
                    end
                end
            endcase
        end else begin
            wb_ack_o <= 0;            

            bg_pixels_load_0 <= 0;
            bg_pixels_load_1 <= 0;
        end
    end

    always @(posedge clk) begin
        vga_hs <= vga_h_sync;
        vga_vs <= vga_v_sync;

        if (vga_h_active && vga_v_active) begin
            if (bg_color_index == 0) begin
                vga_r <= 4'b0000;
                vga_g <= 4'b0000;
                vga_b <= 4'b0000;
            end else if (bg_color_index == 1) begin
                vga_r <= 4'b1111;
                vga_g <= 4'b0000;
                vga_b <= 4'b0000;                
            end else if (bg_color_index == 2) begin
                vga_r <= 4'b0000;
                vga_g <= 4'b1111;
                vga_b <= 4'b0000;                
            end else begin
                vga_r <= 4'b0000;
                vga_g <= 4'b0000;
                vga_b <= 4'b1111;
            end
        end else begin
            vga_r = 0;
            vga_g = 0;
            vga_b = 0;
        end
    end

    always @(*) begin
        cond_met = 0;
        if (cond_check_v_active || cond_check_h_active || cond_check_v_count || cond_check_h_count) begin
            cond_met = 1;

            if ((cond_check_v_active && (cond_v_active != vga_v_active)) ||
                (cond_check_h_active && (cond_h_active != vga_h_active)) ||
                (cond_check_v_count && (cond_v_count != v_counter)) ||
                (cond_check_h_count && (cond_h_count != h_counter))) begin
                cond_met = 0;
            end
        end        
    end

endmodule
