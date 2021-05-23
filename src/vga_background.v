`default_nettype none
`timescale 1ns/1ns


module vga_background (
    input clk,
    input reset,

    input h_active,
    input v_active,

    input [31:0] bg_pixels_0,
    input [31:0] bg_pixels_1,

    input [5:0] bg_size_0,
    input [5:0] bg_size_1,

    output [1:0] bg_color_index
);

	wire active = h_active && v_active;

	wire [1:0] color_0;
	wire [1:0] color_1;

	reg [5:0] pixel_size_count;
	reg last_pixel;

	reg [4:0] pixel_count;
	wire shifter_index = pixel_count[4];

	vga_pixel_selector vga_pixel_selector_0 (
		.pixels (bg_pixels_0),
		.pixel_select (pixel_count[3:0]),

		.color_index (color_0)
	);

	vga_pixel_selector vga_pixel_selector_1 (
		.pixels (bg_pixels_1),
		.pixel_select (pixel_count[3:0]),

		.color_index (color_1)
	);

	always @(posedge clk) begin
		if (reset) begin
			pixel_size_count <= 0;
			pixel_count <= 0;
		end else begin
			if (active) begin
				if (last_pixel) begin
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

	assign bg_color_index = (shifter_index == 0) ? color_0 : color_1;

	always @(*) begin
		last_pixel = 0;
		if (shifter_index == 0 && pixel_size_count == bg_size_0) begin
			last_pixel = 1;
		end else if (shifter_index == 1 && pixel_size_count == bg_size_1) begin
			last_pixel = 1;
		end
	end

endmodule
