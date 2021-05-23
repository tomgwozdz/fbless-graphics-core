`default_nettype none
`timescale 1ns/1ns

module vga_timing (
    input clk,
    input reset,

    input enabled,

    input [9:0] h_sync_start,
    input [9:0] h_sync_end,
    input [9:0] h_active_start,
    input [9:0] h_active_end,
    input h_pol,

    input [9:0] v_sync_start,
    input [9:0] v_sync_end,
    input [9:0] v_active_start,
    input [9:0] v_active_end,
    input v_pol,

    output h_sync,
    output v_sync,
    output h_active,
    output v_active,

	output reg [9:0] h_counter,
	output reg [9:0] v_counter
);

	assign h_sync = (h_counter >= h_sync_start && h_counter <= h_sync_end) ^ ~h_pol;
	assign v_sync = (v_counter >= v_sync_start && v_counter <= v_sync_end) ^ ~v_pol;

	assign h_active = (h_counter >= h_active_start && h_counter <= h_active_end);
	assign v_active = (v_counter >= v_active_start && v_counter <= v_active_end);

	always @(posedge clk) begin
		if (reset) begin
			h_counter <= 10'b0;
			v_counter <= 10'b0;
		end else begin
			h_counter <= h_counter + 1'b1;

			if (h_counter == h_active_end) begin
				h_counter <= 10'b0;
			end

			if (h_counter == 0) begin
				v_counter <= v_counter + 1'b1;

				if (v_counter == v_active_end) begin
					v_counter <= 10'b0;
				end
			end
		end
	end

endmodule
