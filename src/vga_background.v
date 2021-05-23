`default_nettype none
`timescale 1ns/1ns

module vga_background_shifter (
	input [31:0] pixels,
    input [3:0] pixel_select,

	output [1:0] color_index
);
	
	assign color_index = pixels[((16 - pixel_select) * 2) - 1 -: 2];

endmodule



module vga_background (
    input clk,
    input reset,

    input h_active,
    input v_active,

    input [31:0] bg_pixels_0,
    input [31:0] bg_pixels_1,

    input [5:0] bg_size_0,
    input [5:0] bg_size_1,

    output reg [1:0] bg_color_index
);

	wire active = h_active && v_active;

	wire [1:0] color_0;
	wire [1:0] color_1;

	reg [5:0] pixel_size_count;
	reg last_pixel;

	reg [4:0] shift_count;
	wire shifter_index = shift_count[4];

	vga_background_shifter vga_background_shifter_0 (
		.pixels (bg_pixels_0),
		.pixel_select (shift_count[3:0]),

		.color_index (color_0)
	);

	vga_background_shifter vga_background_shifter_1 (
		.pixels (bg_pixels_1),
		.pixel_select (shift_count[3:0]),

		.color_index (color_1)
	);

	always @(posedge clk) begin
		if (reset) begin
			pixel_size_count <= 0;
			shift_count <= 0;
		end else begin
			if (active) begin
				if (last_pixel) begin
					pixel_size_count <= 0;
					shift_count <= shift_count + 1;
				end else begin
					pixel_size_count <= pixel_size_count + 1;
				end
			end else begin
				pixel_size_count <= 0;
				shift_count <= 0;				
			end
		end
	end

	always @(*) begin
		bg_color_index = 0;
		if (active) begin
			if (shifter_index == 0) begin
				bg_color_index = color_0;
			end else begin
				bg_color_index = color_1;
			end
		end

		last_pixel = 0;
		if (shifter_index == 0 && pixel_size_count == bg_size_0) begin
			last_pixel = 1;
		end else if (shifter_index == 1 && pixel_size_count == bg_size_1) begin
			last_pixel = 1;
		end
	end

endmodule
