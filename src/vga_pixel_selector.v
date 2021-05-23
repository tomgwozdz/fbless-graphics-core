`default_nettype none
`timescale 1ns/1ns

module vga_pixel_selector (
	input [31:0] pixels,
    input [3:0] pixel_select,

	output [1:0] color_index
);
	
	assign color_index = pixels[((16 - pixel_select) * 2) - 1 -: 2];

endmodule
