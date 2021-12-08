module lcd_driver(
    input clk,
	 input rst,
	 input send_data,
	 input change_state,
	 input encr_go,
	 output check,
    output disp_rs,
    output disp_rw,
    output disp_en,
    output display_on,
    output [7:0]disp_data
);

reg [255:0]name;

reg [4:0]S;
reg [4:0]NS;

// States
parameter START = 5'd0,

			 IN_KEY_1 = 5'd1,
			 WAITING_1 = 5'd2,
			 IN_KEY_2 = 5'd3,
			 WAITING_2 = 5'd4,
			 IN_KEY_3 = 5'd5,
			 WAITING_3 = 5'd6,
			 IN_KEY_4 = 5'd7,
			 WAITING_4 = 5'd8,
			 
			 DISP_KEY = 5'd9,
			 
			 IN_VALUE_1 = 5'd10,
			 WAITING_5 = 5'd11,
			 IN_VALUE_2 = 5'd12,
			 WAITING_6 = 5'd13,
			 IN_VALUE_3 = 5'd14,
			 WAITING_7 = 5'd15,
			 IN_VALUE_4 = 5'd16,
			 WAITING_8 = 5'd17,
			 
			 DISP_VALUE = 5'd18,
			 
			 WAITING = 5'd19,
			 ENCR = 5'd20,
			 DONE = 5'd21,
			 
			 ERROR = 5'b11111;
			 
//reg pressed;	

/*
always @(negedge send_data)
begin
	
	case(S)
		START: NS = IN_KEY_1;
	
		// Taking user-entered key for encryption:
		IN_KEY_1: NS = WAITING_1;
		WAITING_1: NS = IN_KEY_2;
		IN_KEY_2: NS = WAITING_2;
		WAITING_2: NS = IN_KEY_3;
		
		IN_KEY_3: NS = WAITING_3;
		
		WAITING_3: NS = IN_KEY_4;
		
		IN_KEY_4: NS = WAITING_4;
		
		WAITING_4: NS = DISP_KEY;
		
		// Displaying user-entered key for encryption:
		DISP_KEY: NS = IN_VALUE_1;
		
		// Taking user-entered value to be encrypted:
		IN_VALUE_1: NS = WAITING_5;
		
		WAITING_5: NS = IN_VALUE_2;
		
		IN_VALUE_2: NS = WAITING_6;
		
		WAITING_6: NS = IN_VALUE_3;
		
		IN_VALUE_3: NS = WAITING_7;
		
		WAITING_7: NS = IN_VALUE_4;
		
		IN_VALUE_4: NS = WAITING_8;
		
		WAITING_8: NS = DISP_VALUE;
		
		// Displaying user entered value:
		DISP_VALUE: NS = WAITING;
	
		// Waiting for user to press button to encrypt:
		WAITING: NS = ENCR;
	
		// Encrypting the text:
		ENCR: NS = DONE;
		
		// Spins in Done forever until rst:
		DONE: NS = DONE;
		
		default: NS = ERROR;
		
	endcase
	
end	
*/	 


// S --> NS transitions			 
always @(*)
begin
	
	case(S)
		START: NS = IN_KEY_1;
	
		// Taking user-entered key for encryption:
		IN_KEY_1:
		begin
			if (send_data == 1'b0)
				NS = WAITING_1;
			else
				NS = IN_KEY_1;
		end
		
		WAITING_1:
		begin
			if (send_data == 1'b1)
				NS = IN_KEY_2;
			else
				NS = WAITING_1;
		end
		
		IN_KEY_2:
		begin
			if (send_data == 1'b0)
				NS = WAITING_2;
			else
				NS = IN_KEY_2;
		end
		
		WAITING_2:
		begin
			if (send_data == 1'b1)
				NS = IN_KEY_3;
			else
				NS = WAITING_2;
		end
		
		IN_KEY_3:
		begin
			if (send_data == 1'b0)
				NS = WAITING_3;
			else
				NS = IN_KEY_3;
		end
		
		WAITING_3:
		begin
			if (send_data == 1'b1)
				NS = IN_KEY_4;
			else
				NS = WAITING_3;
		end
		
		IN_KEY_4:
		begin
			if (send_data == 1'b0)
				NS = WAITING_4;
			else
				NS = IN_KEY_4;
		end
		
		WAITING_4:
		begin
			if (send_data == 1'b1)
				NS = DISP_KEY;
			else
				NS = WAITING_4;
		end
		
		// Displaying user-entered key for encryption:
		DISP_KEY:
		begin
			if (change_state == 1'b0)
				NS = IN_VALUE_1;
			else
				NS = DISP_KEY;
		end
		
		// Taking user-entered value to be encrypted:
		IN_VALUE_1:
		begin
			if (send_data == 1'b0)
				NS = WAITING_5;
			else
				NS = IN_VALUE_1;
		end
		
		WAITING_5:
		begin
			if (send_data == 1'b1)
				NS = IN_VALUE_2;
			else
				NS = WAITING_5;
		end
		
		IN_VALUE_2:
		begin
			if (send_data == 1'b0)
				NS = WAITING_6;
			else
				NS = IN_VALUE_2;
		end
		
		WAITING_6:
		begin
			if (send_data == 1'b1)
				NS = IN_VALUE_3;
			else
				NS = WAITING_6;
		end
		
		IN_VALUE_3:
		begin
			if (send_data == 1'b0)
				NS = WAITING_7;
			else
				NS = IN_VALUE_3;
		end
		
		WAITING_7:
		begin
			if (send_data == 1'b1)
				NS = IN_VALUE_4;
			else
				NS = WAITING_7;
		end
		
		IN_VALUE_4:
		begin
			if (send_data == 1'b0)
				NS = WAITING_8;
			else
				NS = IN_VALUE_4;
		end
		
		WAITING_8:
		begin
			if (send_data == 1'b1)
				NS = DISP_VALUE;
			else
				NS = WAITING_8;
		end
		
		// Displaying user entered value:
		DISP_VALUE:
		begin
			if (change_state == 1'b0)
				NS = WAITING;
			else
				NS = DISP_VALUE;
		end
	
		// Waiting for user to press button to encrypt:
		WAITING:
		begin
			if (encr_go == 1'b1)
				NS = ENCR;
			else
				NS = WAITING;
		end
	
		// Encrypting the text:
		ENCR: NS = DONE;
		
		// Spins in Done forever until rst:
		DONE: NS = DONE;
		
		default: NS = ERROR;
		
	endcase
	
end


// FSM init
always@(posedge clk or negedge rst) begin
	if (rst == 1'b0) 
		S <= START;
	else 
		S <= NS;
end 

// LCD message for each state
always @(posedge clk or negedge rst) begin
	if (rst == 1'b0) begin
		name <= "Welcome to the  Text Encryptor  ";
				 //0123456789ABCDEF0123456789ABCDEF
	end else begin 
		case(S)
		      START:
				  name <= "Welcome to the  Text Encryptor  ";
						   //0123456789ABCDEF0123456789ABCDEF
							
				IN_KEY_1:
					name <= "Enter [63:48]key                ";
							 //0123456789ABCDEF0123456789ABCDEF
							 
				WAITING_1:
					name <= "Waiting 1 Stage                 ";
							 //0123456789ABCDEF0123456789ABCDEF
							 
				IN_KEY_2:
					name <= "Enter [47:32]key                ";
							 //0123456789ABCDEF0123456789ABCDEF
							 
				IN_KEY_3:
					name <= "Enter [31:16]key                ";
							 //0123456789ABCDEF0123456789ABCDEF
				
				IN_KEY_4:
					name <= "Enter [15:0]key                 ";
							 //0123456789ABCDEF0123456789ABCDEF
							 
				DISP_KEY:
					name <= "Displaying key                  ";
							 //0123456789ABCDEF0123456789ABCDEF
		endcase
	end
end

assign display_on = 1'b1;

lcd_control lcd(clk, rst, name, disp_rs, disp_rw, disp_en, disp_data);
 
endmodule 