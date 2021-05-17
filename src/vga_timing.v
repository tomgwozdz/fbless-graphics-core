`default_nettype none
`timescale 1ns/1ns

module vga_timing (
    input clk,
    input reset,

    output reg h_sync,
    output reg v_sync,
    output reg h_active,
    output reg v_active,
    output reg active
);
	// states
	localparam STATE_FP   = 0;
	localparam STATE_SYNC = 1;
	localparam STATE_BP	  = 2;
	localparam STATE_VIS  = 3;

	reg [1:0] h_state;
	reg [1:0] v_state;

	reg [9:0] h_counter;
	reg [8:0] v_counter;

	reg [9:0] h_counter_end;
	reg [8:0] v_counter_end;


	assign h_sync = (h_state == STATE_SYNC);
	assign v_sync = (v_state == STATE_SYNC);
	assign h_active = (h_state == STATE_VIS);
	assign v_active = (v_state == STATE_VIS);
	assign active = (h_active & v_active);


	always @(*) begin
		case (h_state)
			STATE_FP:	h_counter_end = 15;
			STATE_SYNC:	h_counter_end = 95;
			STATE_BP:	h_counter_end = 47;
			STATE_VIS:  h_counter_end = 639;
		endcase

		case (v_state)
			STATE_FP:	v_counter_end = 9;
			STATE_SYNC:	v_counter_end = 1;
			STATE_BP:	v_counter_end = 32;
			STATE_VIS:  v_counter_end = 479;
		endcase
	end


	always @(posedge clk) begin
		if (reset) begin
			h_state <= STATE_FP;
			v_state <= STATE_FP;

			h_counter <= 10'b0;
			v_counter <= 9'b0;
		end else begin
			h_counter <= h_counter + 1'b1;

			if (h_counter == h_counter_end) begin
				h_counter <= 0;
				h_state <= h_state + 1'b1;
			end

			if (h_counter == 0 && h_state == 0) begin
				v_counter <= v_counter + 1'b1;

				if (v_counter == v_counter_end) begin
					v_counter <= 0;
					v_state <= v_state + 1'b1;
				end
			end
		end
	end

endmodule
