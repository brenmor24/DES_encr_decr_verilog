module text_encryption(
input clk,
input rst,
input send_data,						// to save data from switches in the key or value reg, depending on the current state
input [15:0]user_input,				// user input from switches
input encr_go,							// button for user to press which starts the encryption
input [1:0]select_disp,				// for users to select between viewing each group of 16 bits in the key/value on the 7-seg display		
output reg temp,						// LEDR[0] turns on when DISP_KEY state is reached
output reg temp1,						// LEDG[0] turns on when DISP_VALUE state is reached
input change_state,					// to move to the next state from one of the DISP states

// To update the 7-seg display:
output [6:0]seg7_most,				
output [6:0]seg7_most_2,
output [6:0]seg7_least_2,
output [6:0]seg7_least,

/*
// To update the LCD:
output check,
output disp_rs,
output disp_rw,
output disp_en,
output display_on,
output [7:0]disp_data,
*/

// testing encr
output reg encr_led
);

//lcd_driver show_text(clk, rst, send_data, change_state, encr_go, check, disp_rs, disp_rw, disp_en, display_on, disp_data);

reg [63:0]key;		// user-entered key for encryption // key[63] = MSb
reg [63:0]value;	// user-entered value to encrypt

wire [63:0]msg;	// encrypted value will be stored here

reg button_press_counter; // to check whether button press has ended or not

/*
Total cumulative time spent: 20 hours

Design:
	1) 64-bit encryption key that we will get by flipping on 16 switches x 4 times
		- ALWAYS give the user the ability to go back and edit each bit in 1 of the 4 cycles
		- Counter to check how many times the button has been pressed before moving to the next state
		- Display each 16-bit hex value on the 7-seg and then display the 64-bit value on the LCD once all 4 cycles are done
	2) 64-bit input for encryption that we will get by flipping on 16 switches x 4 times
		- Update the LCD display (?) after each 16-bit hex digit is input, going from MSb to LSb
	3) Encrypt value using key
		- Create .mif files for the encryption?
	4) Store the encrypted value in on-chip memory (register?)
	5) Display the 4 16-bit hex digits on the LCD display (?)
	6) Have the user put in the same encryption key as before and then the output from the 7-seg display
	7) Output the decrypted value
		- THIS SHOULD BE THE SAME AS THE INPUT VALUE FROM STEP 2!
	
	BUTTONS:
	KEY[0] = rst
	KEY[1] = change_state 
	KEY[2] = encr_go
	KEY[3] = send_data
	
	SWITCHES:
	SW[15:0] = user_input[15:0]
	SW[17:16] = select_disp[1:0]

*/

reg [15:0]disp;	// to store the 16-bit value to display on the 7-segment
four_hex_vals my_disp(disp, seg7_most, seg7_most_2, seg7_least_2, seg7_least);	// displays a 16-bit value on the 7-segment display

//wire [63:0] sbox_outs_k1;
temp_encr my_encr_value(clk, rst, key, value, msg);

reg [63:0]temp_disp;

// FSM State variables:
reg [4:0]S;
reg [4:0]NS;

// Defining FSM states:
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
			if (encr_go == 1'b0)
				NS = ENCR;
			else
				NS = WAITING;
		end
	
		// Encrypting the text:
		ENCR: 
		begin
			if (change_state == 1'b0)
				NS = DONE;
			else
				NS = ENCR;
		end
		
		// Spins in Done forever until rst:
		DONE: NS = DONE;
		
		default: NS = ERROR;
		
	endcase
	
end

//reg [2:0] tester[1:0];

// What happens in each state
always @(posedge clk or negedge rst)
begin

	if (rst == 1'b0) begin
		disp <= 16'd0;
		key <= 64'd0;
		value <= 64'd0;
		//msg <= 64'd0;
		temp <= 1'b0;
		temp1 <= 1'b0;
		encr_led <= 1'b0;
		//tester[0] = 3'b010;
		//tester[1] = 3'b001;
	end
	
	else begin
		case(S)
			
			// Start state - resetting everything:
			START:
			begin
				disp <= 16'd0;
				key <= 64'd0;
				value <= 64'd0;
				//msg <= 64'd0;
				temp <= 1'b0;
				temp1 <= 1'b0;
				encr_led <= 1'b0;
				// set EVERYTHING to 0 (key, value, msg, buttons and switches if needed, etc)
			end
			
			// Taking user entered key:
			IN_KEY_1:
			begin
				disp <= user_input;
				key[63:48] <= user_input;
			end
			
			IN_KEY_2:
			begin
				disp <= user_input;
				key[47:32] <= user_input;
			end
			
			IN_KEY_3:
			begin
				disp <= user_input;
				key[31:16] <= user_input;
			end
			
			IN_KEY_4:
			begin
				disp <= user_input;
				key[15:0] <= user_input;
			end
			
			// Displaying user entered key:
			DISP_KEY:
			begin
				temp <= 1'b1;
				case(select_disp)
					2'd0: disp <= key[15:0];
					2'd1: disp <= key[31:16];
					2'd2: disp <= key[47:32];
					2'd3: disp <= key[63:48];
				endcase
			end
			
			// Taking user entered value:
			IN_VALUE_1:
			begin
				temp <= 1'b0;
				disp <= user_input;
				value[63:48] <= user_input;
			end
			
			IN_VALUE_2:
			begin
				disp <= user_input;
				value[47:32] <= user_input;
			end
			
			IN_VALUE_3:
			begin
				disp <= user_input;
				value[31:16] <= user_input;
			end
			
			IN_VALUE_4:
			begin
				disp <= user_input;
				value[15:0] <= user_input;
			end
			
			// Displaying user entered value:
			DISP_VALUE:
			begin
				temp1 <= 1'b1;
				case(select_disp)
					2'd0: disp <= value[15:0];
					2'd1: disp <= value[31:16];
					2'd2: disp <= value[47:32];
					2'd3: disp <= value[63:48];
				endcase
			end
		
			WAITING: 
			begin
				disp <= 16'd0;
				temp1 <= 1'b0;
			end
			
			ENCR:
			begin
				encr_led <= 1'b1;
				temp_disp <= msg; // {32'd0, sbox_outs_k1};
				case(select_disp)
					2'd0: disp <= temp_disp[15:0];
					2'd1: disp <= temp_disp[31:16];
					2'd2: disp <= temp_disp[47:32];
					2'd3: disp <= temp_disp[63:48];
				endcase
			end
		
		endcase
	end
	
end

// FSM init
always @(posedge clk or negedge rst)
begin
	if (rst == 1'b0)							// rst is mapped to buttons so have it pressed as soon as the program starts
		S <= START;
	else
		S <= NS;
end

endmodule
