`default_nettype none
`timescale 1ns/1ns

module vga_background_shifter (
    input clk,
    input reset,

	input shift,

	input [31:0] in_pixels,
	input load_pixels,

	output [1:0] color_index
);
	
	reg [31:0] pixels;

	assign color_index = pixels[31:30];

	always @(posedge clk) begin
		if (reset) begin
			pixels <= 0;
		end else begin
			if (load_pixels) begin
				pixels <= in_pixels;
			end

			if (shift) begin
				pixels <= { pixels[29:0], pixels[31:30] };
			end

		end
	end

endmodule



module vga_background (
    input clk,
    input reset,

    input h_active,
    input v_active,

    input [31:0] bg_pixels,
    input bg_pixels_load_0,
    input bg_pixels_load_1,

    input [5:0] bg_size_0,
    input [5:0] bg_size_1,

    output reg [1:0] bg_color_index
);

	wire active = h_active && v_active;

	wire [1:0] color_0;
	wire [1:0] color_1;

	reg [5:0] pixel_size_count;
	reg last_pixel;

	wire shift_0 = last_pixel && active && shifter_index == 0;	
	wire shift_1 = last_pixel && active && shifter_index == 1;

	reg [4:0] shift_count;
	wire shifter_index = shift_count[4];

	vga_background_shifter vga_background_shifter_0 (
		.clk (clk),
		.reset (reset),

		.shift (shift_0),

		.in_pixels (bg_pixels),
		.load_pixels (bg_pixels_load_0),

		.color_index (color_0)
	);

	vga_background_shifter vga_background_shifter_1 (
		.clk (clk),
		.reset (reset),

		.shift (shift_1),

		.in_pixels (bg_pixels),
		.load_pixels (bg_pixels_load_1),

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
