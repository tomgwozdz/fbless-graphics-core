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
 *
 * W 1C  [00000000 bbbbbbbb bbbbaaaa aaaaaaaa]
 *        a = bg_color_0
 *        b = bg_color_1
 *
 * W 20  [00000000 bbbbbbbb bbbbaaaa aaaaaaaa]
 *        a = bg_color_2
 *        b = bg_color_3
 */

module vga_core (
`ifdef USE_POWER_PINS
    inout vdda1,    // User area 1 3.3V supply
    inout vdda2,    // User area 2 3.3V supply
    inout vssa1,    // User area 1 analog ground
    inout vssa2,    // User area 2 analog ground
    inout vccd1,    // User area 1 1.8V supply
    inout vccd2,    // User area 2 1.8v supply
    inout vssd1,    // User area 1 digital ground
    inout vssd2,    // User area 2 digital ground
`endif
    
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
    output reg vga_vs,

    input [11:0] buttons
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

    reg [31:0] bg_pixels_0;
    reg [31:0] bg_pixels_1;

    reg [5:0] bg_size_0;
    reg [5:0] bg_size_1;

    wire [1:0] bg_color_index;
    wire [1:0] sprite_0_color_index;
    wire [1:0] sprite_1_color_index;
    wire [1:0] sprite_2_color_index;

    reg [9:0] cond_h_count;
    reg [9:0] cond_v_count;
    reg cond_h_active;
    reg cond_v_active;
    reg cond_check_v_active;
    reg cond_check_h_active;
    reg cond_check_v_count;
    reg cond_check_h_count;

    reg cond_met;

    reg [11:0] bg_color_0;
    reg [11:0] bg_color_1;
    reg [11:0] bg_color_2;
    reg [11:0] bg_color_3;

    reg [11:0] sprite_0_color_1;
    reg [11:0] sprite_0_color_2;
    reg [11:0] sprite_0_color_3;

    reg [11:0] sprite_1_color_1;
    reg [11:0] sprite_1_color_2;
    reg [11:0] sprite_1_color_3;

    reg [11:0] sprite_2_color_1;
    reg [11:0] sprite_2_color_2;
    reg [11:0] sprite_2_color_3;

    reg [9:0] sprite_0_start_time_0;
    reg [9:0] sprite_0_start_time_1;
    reg [9:0] sprite_0_start_time_2;

    reg [9:0] sprite_1_start_time_0;
    reg [9:0] sprite_1_start_time_1;
    reg [9:0] sprite_1_start_time_2;

    reg [9:0] sprite_2_start_time_0;
    reg [9:0] sprite_2_start_time_1;
    reg [9:0] sprite_2_start_time_2;

    reg [31:0] sprite_0_pixels;
    reg [5:0] sprite_0_size;

    reg [31:0] sprite_1_pixels;
    reg [5:0] sprite_1_size;

    reg [31:0] sprite_2_pixels;
    reg [5:0] sprite_2_size;

    reg clear_collision;
    reg [11:0] collision_bits;

    reg [11:0] buttons_buffer;
    reg [11:0] buttons_reg;


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

        .bg_pixels_0 (bg_pixels_0),
        .bg_pixels_1 (bg_pixels_1),

        .bg_size_0 (bg_size_0),
        .bg_size_1 (bg_size_1),

        .bg_color_index (bg_color_index)
    );


    vga_sprite vga_sprite_0 (
        .clk (clk),
        .reset (reset),

        .sprite_pixels (sprite_0_pixels),
        .sprite_pixel_size (sprite_0_size),

        .h_counter (h_counter),

        .start_time_0 (sprite_0_start_time_0),
        .start_time_1 (sprite_0_start_time_1),
        .start_time_2 (sprite_0_start_time_2),

        .sprite_color_index (sprite_0_color_index)
    );

    vga_sprite vga_sprite_1 (
        .clk (clk),
        .reset (reset),

        .sprite_pixels (sprite_1_pixels),
        .sprite_pixel_size (sprite_1_size),

        .h_counter (h_counter),

        .start_time_0 (sprite_1_start_time_0),
        .start_time_1 (sprite_1_start_time_1),
        .start_time_2 (sprite_1_start_time_2),

        .sprite_color_index (sprite_1_color_index)
    );

    vga_sprite vga_sprite_2 (
        .clk (clk),
        .reset (reset),

        .sprite_pixels (sprite_2_pixels),
        .sprite_pixel_size (sprite_2_size),

        .h_counter (h_counter),

        .start_time_0 (sprite_2_start_time_0),
        .start_time_1 (sprite_2_start_time_1),
        .start_time_2 (sprite_2_start_time_2),

        .sprite_color_index (sprite_2_color_index)
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

            cond_h_count <= 0;
            cond_v_count <= 0;
            cond_h_active <= 0;
            cond_v_active <= 0;
            cond_check_v_active <= 0;
            cond_check_h_active <= 0;
            cond_check_v_count <= 0;
            cond_check_h_count <= 0;

            bg_size_0 <= 0;
            bg_size_1 <= 0;

            bg_color_0 <= 0;
            bg_color_1 <= 0;
            bg_color_2 <= 0;
            bg_color_3 <= 0;

            sprite_0_color_1 <= 0;
            sprite_0_color_2 <= 0;
            sprite_0_color_3 <= 0;

            sprite_1_color_1 <= 0;
            sprite_1_color_2 <= 0;
            sprite_1_color_3 <= 0;

            sprite_2_color_1 <= 0;
            sprite_2_color_2 <= 0;
            sprite_2_color_3 <= 0;

            sprite_0_start_time_0 <= 0;
            sprite_0_start_time_1 <= 0;
            sprite_0_start_time_2 <= 0;

            sprite_1_start_time_0 <= 0;
            sprite_1_start_time_1 <= 0;
            sprite_1_start_time_2 <= 0;

            sprite_2_start_time_0 <= 0;
            sprite_2_start_time_1 <= 0;
            sprite_2_start_time_2 <= 0;

            sprite_0_pixels <= 0;
            sprite_0_size <= 0;

            sprite_1_pixels <= 0;
            sprite_1_size <= 0;

            sprite_2_pixels <= 0;
            sprite_2_size <= 0;

            clear_collision <= 0;
        end else if(wb_stb_i && wb_cyc_i && wb_we_i && wb_addr_i[31:24] == 8'h30) begin      // Writes
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
                    bg_pixels_0 = wb_data_i;
                    wb_ack_o <= 1;
                end
                8'h10: begin
                    bg_pixels_1 = wb_data_i;
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
                    end
                end
                8'h1c: begin
                    { bg_color_1, bg_color_0 } = wb_data_i;
                    wb_ack_o <= 1;
                end
                8'h20: begin
                    { bg_color_3, bg_color_2 } = wb_data_i;
                    wb_ack_o <= 1;
                end
                8'h24: begin
                    { sprite_0_start_time_2, sprite_0_start_time_1, sprite_0_start_time_0 } = wb_data_i;
                    wb_ack_o <= 1;
                end
                8'h28: begin
                    sprite_0_pixels <= wb_data_i;
                    wb_ack_o <= 1;
                end
                8'h2c: begin
                    { sprite_0_size, sprite_0_color_1 } = wb_data_i;
                    wb_ack_o <= 1;
                end
                8'h30: begin
                    { sprite_0_color_3, sprite_0_color_2 } = wb_data_i;
                    wb_ack_o <= 1;
                end
                8'h34: begin
                    { sprite_1_start_time_2, sprite_1_start_time_1, sprite_1_start_time_0 } = wb_data_i;
                    wb_ack_o <= 1;
                end
                8'h38: begin
                    sprite_1_pixels <= wb_data_i;
                    wb_ack_o <= 1;
                end
                8'h3c: begin
                    { sprite_1_size, sprite_1_color_1 } = wb_data_i;
                    wb_ack_o <= 1;
                end
                8'h40: begin
                    { sprite_1_color_3, sprite_1_color_2 } = wb_data_i;
                    wb_ack_o <= 1;
                end
                8'h44: begin
                    { sprite_2_start_time_2, sprite_2_start_time_1, sprite_2_start_time_0 } = wb_data_i;
                    wb_ack_o <= 1;
                end
                8'h48: begin
                    sprite_2_pixels <= wb_data_i;
                    wb_ack_o <= 1;
                end
                8'h4c: begin
                    { sprite_2_size, sprite_2_color_1 } = wb_data_i;
                    wb_ack_o <= 1;
                end
                8'h50: begin
                    { sprite_2_color_3, sprite_2_color_2 } = wb_data_i;
                    wb_ack_o <= 1;
                end
            endcase
        end else if(wb_stb_i && wb_cyc_i && !wb_we_i && wb_addr_i[31:24] == 8'h30) begin      // Reads
            case (wb_addr_i[7:0])
                8'h00: begin
                    wb_data_o <= collision_bits;
                    clear_collision <= 1;
                end
                8'h04:  wb_data_o <= buttons_reg;
            endcase

            wb_ack_o <= 1;
        end else begin
            wb_ack_o <= 0;

            cond_check_v_active <= 0;
            cond_check_h_active <= 0;
            cond_check_v_count <= 0;
            cond_check_h_count <= 0;

            clear_collision <= 0;
        end
    end

    always @(posedge clk) begin
        vga_hs <= vga_h_sync;
        vga_vs <= vga_v_sync;

        if (vga_h_active && vga_v_active) begin
            if (sprite_0_color_index == 1) begin
                { vga_r, vga_g, vga_b } = sprite_0_color_1;
            end else if (sprite_0_color_index == 2) begin
                { vga_r, vga_g, vga_b } = sprite_0_color_2;
            end else if (sprite_0_color_index == 3) begin
                { vga_r, vga_g, vga_b } = sprite_0_color_3;
            end else if (sprite_1_color_index == 1) begin
                { vga_r, vga_g, vga_b } = sprite_1_color_1;
            end else if (sprite_1_color_index == 2) begin
                { vga_r, vga_g, vga_b } = sprite_1_color_2;
            end else if (sprite_1_color_index == 3) begin
                { vga_r, vga_g, vga_b } = sprite_1_color_3;
            end else if (sprite_2_color_index == 1) begin
                { vga_r, vga_g, vga_b } = sprite_2_color_1;
            end else if (sprite_2_color_index == 2) begin
                { vga_r, vga_g, vga_b } = sprite_2_color_2;
            end else if (sprite_2_color_index == 3) begin
                { vga_r, vga_g, vga_b } = sprite_2_color_3;
            end else if (bg_color_index == 0) begin
                { vga_r, vga_g, vga_b } = bg_color_0;
            end else if (bg_color_index == 1) begin
                { vga_r, vga_g, vga_b } = bg_color_1;
            end else if (bg_color_index == 2) begin
                { vga_r, vga_g, vga_b } = bg_color_2;
            end else begin
                { vga_r, vga_g, vga_b } = bg_color_3;
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

    always @(posedge clk) begin
        if (reset) begin
            collision_bits <= 0;            
        end else if (clear_collision) begin
            collision_bits <= 0;
        end else if (vga_h_active && vga_v_active) begin
            collision_bits <= { collision_s0_s1, collision_s0_s2, collision_s1_s2,
                                collision_b1_s0, collision_b2_s0, collision_b3_s0,
                                collision_b1_s1, collision_b2_s1, collision_b3_s1,
                                collision_b1_s2, collision_b2_s2, collision_b3_s2 } | collision_bits;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            buttons_buffer <= 0;
            buttons_reg <= 0;
        end else begin
            buttons_reg <= buttons_buffer;
            buttons_buffer <= buttons;
        end
    end

    wire collision_s0_s1 = (sprite_0_color_index != 0 && sprite_1_color_index != 0);
    wire collision_s0_s2 = (sprite_0_color_index != 0 && sprite_2_color_index != 0);
    wire collision_s1_s2 = (sprite_1_color_index != 0 && sprite_2_color_index != 0);

    wire collision_b1_s0 = (bg_color_index == 1 && sprite_0_color_index != 0);
    wire collision_b2_s0 = (bg_color_index == 2 && sprite_0_color_index != 0);
    wire collision_b3_s0 = (bg_color_index == 3 && sprite_0_color_index != 0);

    wire collision_b1_s1 = (bg_color_index == 1 && sprite_1_color_index != 0);
    wire collision_b2_s1 = (bg_color_index == 2 && sprite_1_color_index != 0);
    wire collision_b3_s1 = (bg_color_index == 3 && sprite_1_color_index != 0);

    wire collision_b1_s2 = (bg_color_index == 1 && sprite_2_color_index != 0);
    wire collision_b2_s2 = (bg_color_index == 2 && sprite_2_color_index != 0);
    wire collision_b3_s2 = (bg_color_index == 3 && sprite_2_color_index != 0);

endmodule
