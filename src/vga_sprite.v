`default_nettype none
`timescale 1ns/1ns


module vga_sprite (
    input clk,
    input reset,

    input [31:0] sprite_pixels,
    input [5:0] sprite_pixel_size,

    input [9:0] h_counter,

    input [9:0] start_time_0,
    input [9:0] start_time_1,
    input [9:0] start_time_2,

    output [1:0] sprite_color_index
);

	reg [5:0] pixel_size_count;
	reg [3:0] pixel_count;
	wire [1:0] selected_color_index;

	reg active;

	wire last_pixel_of_size = pixel_size_count == sprite_pixel_size;
	wire last_pixel_of_sprite = pixel_count == 15 && last_pixel_of_size;

	wire start_showing_sprite = (h_counter == start_time_0) || (h_counter == start_time_1) || (h_counter == start_time_2);

	assign sprite_color_index = active ? selected_color_index : 0;

	vga_pixel_selector vga_pixel_selector_0 (
		.pixels (sprite_pixels),
		.pixel_select (pixel_count),

		.color_index (selected_color_index)
	);

	always @(posedge clk) begin
		if (reset) begin
			pixel_size_count <= 0;			
			pixel_count <= 0;
			active <= 0;
		end else begin
			if (start_showing_sprite) begin
				active <= 1;
			end else if (last_pixel_of_sprite) begin
				active <= 0;
			end

			if (active) begin
				if (last_pixel_of_size) begin
					pixel_size_count <= 0;
					pixel_count <= pixel_count + 1;
				end else begin
					pixel_size_count <= pixel_size_count + 1;
				end
			end else begin
				pixel_size_count <= 0;
				pixel_count <= 0;				
			end
		end
	end

endmodule
