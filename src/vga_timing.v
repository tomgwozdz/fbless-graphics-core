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

    output reg h_sync,
    output reg v_sync,
    output reg h_active,
    output reg v_active
);


	reg [9:0] h_counter;
	reg [9:0] v_counter;


	always @(posedge clk) begin
		if (reset) begin
			h_counter <= 10'b0;
			v_counter <= 10'b0;

			h_sync <= ~h_pol;
			v_sync <= ~v_pol;
			h_active <= 1'b0;
			v_active <= 1'b0;
		end else begin
			h_counter <= h_counter + 1'b1;

			if (h_counter == h_sync_start) begin
				h_sync <= h_pol;
			end else if (h_counter == h_sync_end) begin
				h_sync <= ~h_pol;
			end else if (h_counter == h_active_start) begin
				h_active <= 1'b1;
			end else if (h_counter == h_active_end) begin
				h_active <= 1'b0;
				h_counter <= 10'b0;
			end

			if (h_counter == 0) begin
				v_counter <= v_counter + 1'b1;

				if (v_counter == v_sync_start) begin
					v_sync <= v_pol;
				end else if (v_counter == v_sync_end) begin
					v_sync <= ~v_pol;
				end else if (v_counter == v_active_start) begin
					v_active <= 1'b1;
				end else if (v_counter == v_active_end) begin
					v_active <= 1'b0;
					v_counter <= 10'b0;
				end
			end
		end
	end

endmodule
