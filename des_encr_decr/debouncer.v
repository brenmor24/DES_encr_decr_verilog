// This code was obtained from Dr. Peter Jamieson.

module debouncer(
	input clk,
	input rst,
	input to_debounce,
	output reg now_debounced
);

//=======================================================
//  PORT declarations
//=======================================================
reg [2:0] S;
reg [2:0] NS;
reg [9:0] ticks_going;

parameter IS_1 = 3'd0,
		IS_0 = 3'd1,
		GOING_1 = 3'd2,
		GOING_0 = 3'd3,
		ERROR = 3'b111;
		
parameter TICKS_TILL_STABILIZED = 1000; // at 50MHz of the DE2 this is 1 microsecond = 1000 ticks

//=======================================================
//  Design
//=======================================================

always @(*)
begin
	case (S)
		IS_1: 
			if (to_debounce == 1'b0)
				NS = GOING_0;
			else
				NS = IS_1;
		GOING_0:
			if (to_debounce == 1'b1)
				NS = IS_1;
			else
				if (ticks_going < TICKS_TILL_STABILIZED)
					NS = GOING_0;
				else
					NS = IS_0;
		IS_0: 
			if (to_debounce == 1'b1)
				NS = GOING_1;
			else
				NS = IS_0;
		GOING_1:
			if (to_debounce == 1'b0)
				NS = IS_0;
			else
				if (ticks_going < TICKS_TILL_STABILIZED)
					NS = GOING_1;
				else
					NS = IS_1;
		ERROR: NS = ERROR;
	endcase
end

always @(posedge clk or negedge rst)
begin
	if (rst == 1'b0)
	begin
		ticks_going <= 10'd0;
		now_debounced <= 1'b1;
	end
	else
	begin
		case (S)
			IS_1: 
			begin
				ticks_going <= 10'd0;
				now_debounced <= 1'b1;
			end
			GOING_0:
			begin
				ticks_going <= ticks_going + 1'b1;
			end
			IS_0: 
			begin
				ticks_going <= 10'd0;
				now_debounced <= 1'b0;
			end
			GOING_1:
			begin
				ticks_going <= ticks_going + 1'b1;
			end
		endcase
	end
end

always @(posedge clk or negedge rst)
begin
	if (rst == 1'b0)
		S <= IS_1;
	else
		S <= NS;
end

endmodule