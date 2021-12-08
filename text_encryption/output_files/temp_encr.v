module temp_encr(
input clk,
input rst,
input [63:0]key,
input [63:0]value,
output reg [63:0]msg//,
//output reg [63:0] tempr
);

reg [55:0] key_plus;
reg [27:0] C0;
reg [27:0] D0;

reg [27:0] c_blocks [16:0]; // C[i]
reg [27:0] d_blocks [16:0]; // D[i]

reg [55:0] concat [16:0];	// {c_blocks[i], d_blocks[i]}
reg [47:0] permutes [16:0];	// concat[i] --> K[i]

reg [63:0] value_plus;	// value being transformed by IP

reg [31:0] L0;	// value_plus[63:32]
reg [31:0] R0;	// value_plus[31:0]

//reg [31:0] lefts [15:0];
//reg [31:0] rights [15:0];

//reg ebits[47:0];
//reg function0[47:0];

//reg [2047:0] box_unrolled;
//reg [3:0] s_box[7:0] [3:0][15:0];
reg [63:0] s_box[7:0][3:0]; // 4 bit wide entries, 8 sboxes, 4 rows per sbox, 16 columns per sbox

reg [31:0] right_boxed [16:0];
reg [31:0] left_boxed [16:0];

reg [47:0] e_transform [16:0]; // E(right_boxed[i])
reg [47:0] keyXetran [16:0];	// K[i] + E(right_boxed[i])

reg [31:0] sbox_outs[16:0]; // 32 bit wide entries, 16 different outputs (ignoring index 0)
reg [1:0] row[7:0];	// row number of the sbox (i)
reg [3:0] column[7:0];	// column number of the sbox (j)

reg [4:0]i;
reg [7:0]j;

reg [31:0] f[16:0]; // function f in Step 2

reg [63:0] reversal; // R1L1 instead of L1R1

always @(*)
begin

    // first state
    key_plus = {key[64-57], key[64-49], key[64-41], key[64-33], key[64-25], key[64-17], key[64-9],
                key[64-1],  key[64-58], key[64-50], key[64-42], key[64-34], key[64-26], key[64-18],
                key[64-10], key[64-2],  key[64-59], key[64-51], key[64-43], key[64-35], key[64-27],
                key[64-19], key[64-11], key[64-3],  key[64-60], key[64-52], key[64-44], key[64-36],
                key[64-63], key[64-55], key[64-47], key[64-39], key[64-31], key[64-23], key[64-15],
                key[64-7],  key[64-62], key[64-54], key[64-46], key[64-38], key[64-30], key[64-22],
                key[64-14], key[64-6],  key[64-61], key[64-53], key[64-45], key[64-37], key[64-29],
                key[64-21], key[64-13], key[64-5],  key[64-28], key[64-20], key[64-12], key[64-4]};
    
	 
    // second state
    C0 = key_plus[55:28];
    D0 = key_plus[27:0];

    // third state
	 
	 c_blocks[0] = C0;
	 c_blocks[0] = D0;

    c_blocks[1] = {C0[26:0], C0[27]};
    d_blocks[1] = {D0[26:0], D0[27]};

    c_blocks[2] = {C0[25:0], C0[27:26]};
    d_blocks[2] = {D0[25:0], D0[27:26]};

    c_blocks[3] = {C0[23:0], C0[27:24]};
    d_blocks[3] = {D0[23:0], D0[27:24]};

    c_blocks[4] = {C0[21:0], C0[27:22]};
    d_blocks[4] = {D0[21:0], D0[27:22]};

    c_blocks[5] = {C0[19:0], C0[27:20]};
    d_blocks[5] = {D0[19:0], D0[27:20]};

    c_blocks[6] = {C0[17:0], C0[27:18]};
    d_blocks[6] = {D0[17:0], D0[27:18]};		

    c_blocks[7] = {C0[15:0], C0[27:16]};
    d_blocks[7] = {D0[15:0], D0[27:16]};

    c_blocks[8] = {C0[13:0], C0[27:14]};
    d_blocks[8] = {D0[13:0], D0[27:14]};

    c_blocks[9] = {C0[12:0], C0[27:13]};
    d_blocks[9] = {D0[12:0], D0[27:13]};

    c_blocks[10] = {C0[10:0], C0[27:11]};
    d_blocks[10] = {D0[10:0], D0[27:11]};

    c_blocks[11] = {C0[8:0], C0[27:9]};
    d_blocks[11] = {D0[8:0], D0[27:9]};

    c_blocks[12] = {C0[6:0], C0[27:7]};
    d_blocks[12] = {D0[6:0], D0[27:7]};

    c_blocks[13] = {C0[4:0], C0[27:5]};
    d_blocks[13] = {D0[4:0], D0[27:5]};

    c_blocks[14] = {C0[2:0], C0[27:3]};
    d_blocks[14] = {D0[2:0], D0[27:3]};

    c_blocks[15] = {C0[0], C0[27:1]};
    d_blocks[15] = {D0[0], D0[27:1]};
	 
    c_blocks[16] = C0;
    d_blocks[16] = D0;

	 
    // fourth state
    for (i = 5'd1; i < 5'd17; i = i + 5'd1)
    begin
        concat[i] = {c_blocks[i], d_blocks[i]};// CHANGE MADE HERE
    end

	 
    // fifth state
    for (i = 5'd1; i < 5'd17; i = i + 5'd1)
    begin
        permutes[i] = { concat[i][56-14], concat[i][56-17], concat[i][56-11], concat[i][56-24], concat[i][56-1],  concat[i][56-5],
                        concat[i][56-3],  concat[i][56-28], concat[i][56-15], concat[i][56-6],  concat[i][56-21], concat[i][56-10],
                        concat[i][56-23], concat[i][56-19], concat[i][56-12], concat[i][56-4],  concat[i][56-26], concat[i][56-8],
                        concat[i][56-16], concat[i][56-7],  concat[i][56-27], concat[i][56-20], concat[i][56-13], concat[i][56-2],
                        concat[i][56-41], concat[i][56-52], concat[i][56-31], concat[i][56-37], concat[i][56-47], concat[i][56-55],
                        concat[i][56-30], concat[i][56-40], concat[i][56-51], concat[i][56-45], concat[i][56-33], concat[i][56-48],
                        concat[i][56-44], concat[i][56-49], concat[i][56-39], concat[i][56-56], concat[i][56-34], concat[i][56-53],
                        concat[i][56-46], concat[i][56-42], concat[i][56-50], concat[i][56-36], concat[i][56-29], concat[i][56-32]};
    end
	 
	 // S1:
	 s_box[0][0] = {4'd14, 4'd4, 4'd13, 4'd1, 4'd2, 4'd15, 4'd11, 4'd8, 4'd3, 4'd10, 4'd6, 4'd12, 4'd5, 4'd9, 4'd0, 4'd7}; // S1 begin
	 s_box[0][1] = {4'd0, 4'd15, 4'd7, 4'd4, 4'd14, 4'd2, 4'd13, 4'd1, 4'd10, 4'd6, 4'd12, 4'd11, 4'd9, 4'd5, 4'd3, 4'd8};
	 s_box[0][2] = {4'd4, 4'd1, 4'd14, 4'd8, 4'd13, 4'd6, 4'd2, 4'd11, 4'd15, 4'd12, 4'd9, 4'd7, 4'd3, 4'd10, 4'd5, 4'd0};
	 s_box[0][3] = {4'd15, 4'd12, 4'd8, 4'd2, 4'd4, 4'd9, 4'd1, 4'd7, 4'd5, 4'd11, 4'd3, 4'd14, 4'd10, 4'd0, 4'd6, 4'd13}; // S1 end
	 
	 // S2:
	 s_box[1][0] = {4'd15, 4'd1, 4'd8, 4'd14, 4'd6, 4'd11, 4'd3, 4'd4, 4'd9, 4'd7, 4'd2, 4'd13, 4'd12, 4'd0, 4'd5, 4'd10}; // S2 begin
	 s_box[1][1] = {4'd3, 4'd13, 4'd4, 4'd7, 4'd15, 4'd2, 4'd8, 4'd14, 4'd12, 4'd0, 4'd1, 4'd10, 4'd6, 4'd9, 4'd11, 4'd5};
	 s_box[1][2] = {4'd0, 4'd14, 4'd7, 4'd11, 4'd10, 4'd4, 4'd13, 4'd1, 4'd5, 4'd8, 4'd12, 4'd6, 4'd9, 4'd3, 4'd2, 4'd15};
	 s_box[1][3] = {4'd13, 4'd8, 4'd10, 4'd1, 4'd3, 4'd15, 4'd4, 4'd2, 4'd11, 4'd6, 4'd7, 4'd12, 4'd0, 4'd5, 4'd14, 4'd9}; // S2 end
	 
	 // S3:
	 s_box[2][0] = {4'd10, 4'd0, 4'd9, 4'd14, 4'd6, 4'd3, 4'd15, 4'd5, 4'd1, 4'd13, 4'd12, 4'd7, 4'd11, 4'd4, 4'd2, 4'd8}; // S3 begin
	 s_box[2][1] = {4'd3, 4'd13, 4'd4, 4'd7, 4'd15, 4'd2, 4'd8, 4'd14, 4'd12, 4'd0, 4'd1, 4'd10, 4'd6, 4'd9, 4'd11, 4'd5};
	 s_box[2][2] = {4'd13, 4'd6, 4'd4, 4'd9, 4'd8, 4'd15, 4'd3, 4'd0, 4'd11, 4'd1, 4'd2, 4'd12, 4'd5, 4'd10, 4'd14, 4'd7};
	 s_box[2][3] = {4'd1, 4'd10, 4'd13, 4'd0, 4'd6, 4'd9, 4'd8, 4'd7, 4'd4, 4'd15, 4'd14, 4'd3, 4'd11, 4'd5, 4'd2, 4'd12}; // S3 end
	 
	 // S4:
	 s_box[3][0] = {4'd7, 4'd13, 4'd14, 4'd3, 4'd0, 4'd6, 4'd9, 4'd10, 4'd1, 4'd2, 4'd8, 4'd5, 4'd11, 4'd12, 4'd4, 4'd15}; // S4 begin
	 s_box[3][1] = {4'd13, 4'd8, 4'd11, 4'd5, 4'd6, 4'd15, 4'd0, 4'd3, 4'd4, 4'd7, 4'd2, 4'd12, 4'd1, 4'd10, 4'd14, 4'd9};
	 s_box[3][2] = {4'd10, 4'd6, 4'd9, 4'd0, 4'd12, 4'd11, 4'd7, 4'd13, 4'd15, 4'd1, 4'd3, 4'd14, 4'd5, 4'd2, 4'd8, 4'd4};
	 s_box[3][3] = {4'd3, 4'd15, 4'd0, 4'd6, 4'd10, 4'd1, 4'd13, 4'd8, 4'd9, 4'd4, 4'd5, 4'd11, 4'd12, 4'd7, 4'd2, 4'd14}; // S4 end
	 
	 // S5:
	 s_box[4][0] = {4'd2, 4'd12, 4'd4, 4'd1, 4'd7, 4'd10, 4'd11, 4'd6, 4'd8, 4'd5, 4'd3, 4'd15, 4'd13, 4'd0, 4'd14, 4'd9}; // S5 begin
    s_box[4][1] = {4'd14, 4'd11, 4'd2, 4'd12, 4'd4, 4'd7, 4'd13, 4'd1, 4'd5, 4'd0, 4'd15, 4'd10, 4'd3, 4'd9, 4'd8, 4'd6};
    s_box[4][2] = {4'd4, 4'd2, 4'd1, 4'd11, 4'd10, 4'd13, 4'd7, 4'd8, 4'd15, 4'd9, 4'd12, 4'd5, 4'd6, 4'd3, 4'd0, 4'd14};
    s_box[4][3] = {4'd11, 4'd8, 4'd12, 4'd7, 4'd1, 4'd14, 4'd2, 4'd13, 4'd6, 4'd15, 4'd0, 4'd9, 4'd10, 4'd4, 4'd5, 4'd3}; // S5 end
	 
	 // S6:
	 s_box[5][0] = {4'd12, 4'd1, 4'd10, 4'd15, 4'd9, 4'd2, 4'd6, 4'd8, 4'd0, 4'd13, 4'd3, 4'd4, 4'd14, 4'd7, 4'd5, 4'd11}; // S6 begin
    s_box[5][1] = {4'd10, 4'd15, 4'd4, 4'd2, 4'd7, 4'd12, 4'd9, 4'd5, 4'd6, 4'd1, 4'd13, 4'd14, 4'd0, 4'd11, 4'd3, 4'd8};
    s_box[5][2] = {4'd9, 4'd14, 4'd15, 4'd5, 4'd2, 4'd8, 4'd12, 4'd3, 4'd7, 4'd0, 4'd4, 4'd10, 4'd1, 4'd13, 4'd11, 4'd6};
    s_box[5][3] = {4'd4, 4'd3, 4'd2, 4'd12, 4'd9, 4'd5, 4'd15, 4'd10, 4'd11, 4'd14, 4'd1, 4'd7, 4'd6, 4'd0, 4'd8, 4'd13}; // S6 end
	 
	 // S7:
	 s_box[6][0] = {4'd4, 4'd11, 4'd2, 4'd14, 4'd15, 4'd0, 4'd8, 4'd13, 4'd3, 4'd12, 4'd9, 4'd7, 4'd5, 4'd10, 4'd6, 4'd1}; // S7 begin
    s_box[6][1] = {4'd13, 4'd0, 4'd11, 4'd7, 4'd4, 4'd9, 4'd1, 4'd10, 4'd14, 4'd3, 4'd5, 4'd12, 4'd2, 4'd15, 4'd8, 4'd6};
    s_box[6][2] = {4'd1, 4'd4, 4'd11, 4'd13, 4'd12, 4'd3, 4'd7, 4'd14, 4'd10, 4'd15, 4'd6, 4'd8, 4'd0, 4'd5, 4'd9, 4'd2};
    s_box[6][3] = {4'd6, 4'd11, 4'd13, 4'd8, 4'd1, 4'd4, 4'd10, 4'd7, 4'd9, 4'd5, 4'd0, 4'd15, 4'd14, 4'd2, 4'd3, 4'd12}; // S7 end
	 
	 // S8:
	 s_box[7][0] = {4'd13, 4'd2, 4'd8, 4'd4, 4'd6, 4'd15, 4'd11, 4'd1, 4'd10, 4'd9, 4'd3, 4'd14, 4'd5, 4'd0, 4'd12, 4'd7}; // S8 begin
    s_box[7][1] = {4'd1, 4'd15, 4'd13, 4'd8, 4'd10, 4'd3, 4'd7, 4'd4, 4'd12, 4'd5, 4'd6, 4'd11, 4'd0, 4'd14, 4'd9, 4'd2};
    s_box[7][2] = {4'd7, 4'd11, 4'd4, 4'd1, 4'd9, 4'd12, 4'd14, 4'd2, 4'd0, 4'd6, 4'd10, 4'd13, 4'd15, 4'd3, 4'd5, 4'd8};
    s_box[7][3] = {4'd2, 4'd1, 4'd14, 4'd7, 4'd4, 4'd10, 4'd8, 4'd13, 4'd15, 4'd12, 4'd9, 4'd0, 4'd3, 4'd5, 4'd6, 4'd11}; // S8 end
	 
	 //s1_r0 = s_box[5][2]; // sbox 6, row 3

    // sixth state
    value_plus={value[64-58], value[64-50], value[64-42], value[64-34], value[64-26], value[64-18], value[64-10], value[64-2],
                value[64-60], value[64-52], value[64-44], value[64-36], value[64-28], value[64-20], value[64-12], value[64-4],
                value[64-62], value[64-54], value[64-46], value[64-38], value[64-30], value[64-22], value[64-14], value[64-6],
                value[64-64], value[64-56], value[64-48], value[64-40], value[64-32], value[64-24], value[64-16], value[64-8],
                value[64-57], value[64-49], value[64-41], value[64-33], value[64-25], value[64-17], value[64-9],  value[64-1],
                value[64-59], value[64-51], value[64-43], value[64-35], value[64-27], value[64-19], value[64-11], value[64-3],
                value[64-61], value[64-53], value[64-45], value[64-37], value[64-29], value[64-21], value[64-13], value[64-5],
                value[64-63], value[64-55], value[64-47], value[64-39], value[64-31], value[64-23], value[64-15], value[64-7]};

	 
    L0 = value_plus[63:32];
    R0 = value_plus[31:0];

	 
    left_boxed[0] = L0;
    right_boxed[0] = R0;

	for (i = 5'd1; i < 5'd17; i = i + 5'd1)
   begin
        left_boxed[i] = right_boxed[i - 1];
		  
        e_transform[i] = {right_boxed[i-1][32-32], right_boxed[i-1][32-1],  right_boxed[i-1][32-2],  right_boxed[i-1][32-3],  right_boxed[i-1][32-4],  right_boxed[i-1][32-5],
                            right_boxed[i-1][32-4],  right_boxed[i-1][32-5],  right_boxed[i-1][32-6],  right_boxed[i-1][32-7],  right_boxed[i-1][32-8],  right_boxed[i-1][32-9],
                            right_boxed[i-1][32-8],  right_boxed[i-1][32-9],  right_boxed[i-1][32-10], right_boxed[i-1][32-11], right_boxed[i-1][32-12], right_boxed[i-1][32-13],
                            right_boxed[i-1][32-12], right_boxed[i-1][32-13], right_boxed[i-1][32-14], right_boxed[i-1][32-15], right_boxed[i-1][32-16], right_boxed[i-1][32-17],
                            right_boxed[i-1][32-16], right_boxed[i-1][32-17], right_boxed[i-1][32-18], right_boxed[i-1][32-19], right_boxed[i-1][32-20], right_boxed[i-1][32-21],
                            right_boxed[i-1][32-20], right_boxed[i-1][32-21], right_boxed[i-1][32-22], right_boxed[i-1][32-23], right_boxed[i-1][32-24], right_boxed[i-1][32-25],
                            right_boxed[i-1][32-24], right_boxed[i-1][32-25], right_boxed[i-1][32-26], right_boxed[i-1][32-27], right_boxed[i-1][32-28], right_boxed[i-1][32-29],
                            right_boxed[i-1][32-28], right_boxed[i-1][32-29], right_boxed[i-1][32-30], right_boxed[i-1][32-31], right_boxed[i-1][32-32], right_boxed[i-1][32-1]};

        keyXetran[i] = e_transform[i]^permutes[i];
		  
		   // s-box-1
			row[0] = {keyXetran[i][47], keyXetran[i][42]};
			column[0] = keyXetran[i][46:43];
			sbox_outs[i][31:28] = s_box[0][row[0]][8'd63 - column[0] * 4'd4 -: 4];
			
			// s-box-2
			row[1] = {keyXetran[i][41], keyXetran[i][36]};
			column[1] = keyXetran[i][40:37];
			sbox_outs[i][27:24] = s_box[1][row[1]][63 - column[1] * 4 -: 4];
			
			// s-box-3
			row[2] = {keyXetran[i][35], keyXetran[i][30]};
			column[2] = keyXetran[i][34:31];
			sbox_outs[i][23:20] = s_box[2][row[2]][63 - column[2] * 4 -: 4];
			
			// s-box-4
			row[3] = {keyXetran[i][29], keyXetran[i][24]};
			column[3] = keyXetran[i][28:25];
			sbox_outs[i][19:16] = s_box[3][row[3]][63 - column[3] * 4 -: 4];
			
			// s-box-5
			row[4] = {keyXetran[i][23], keyXetran[i][18]};
			column[4] = keyXetran[i][21:19];
			sbox_outs[i][15:12] = s_box[4][row[4]][63 - column[4] * 4 -: 4];
			
			// s-box-6
			row[5] = {keyXetran[i][17], keyXetran[i][12]};
			column[5] = keyXetran[i][16:13];
			sbox_outs[i][11:8] = s_box[5][row[5]][63 - column[5] * 4 -: 4];
			
			// s-box-7
			row[6] = {keyXetran[i][11], keyXetran[i][6]};
			column[6] = keyXetran[i][10:7];
			sbox_outs[i][7:4] = s_box[6][row[6]][63 - column[6] * 4 -: 4];
			
			// s-box-8
			row[7] = {keyXetran[i][5], keyXetran[i][0]};
			column[7] = keyXetran[i][4:1];
			sbox_outs[i][3:0] = s_box[7][row[7]][63 - column[7] * 4 -: 4];
			
			// final calculations for function f:
			f[i] = {sbox_outs[i][32-16], sbox_outs[i][32-7], sbox_outs[i][32-20], sbox_outs[i][32-21],
					  sbox_outs[i][32-29], sbox_outs[i][32-12], sbox_outs[i][32-28], sbox_outs[i][32-17],
					  sbox_outs[i][32-1], sbox_outs[i][32-15], sbox_outs[i][32-23], sbox_outs[i][32-26],
					  sbox_outs[i][32-5], sbox_outs[i][32-18], sbox_outs[i][32-31], sbox_outs[i][32-10],
					  sbox_outs[i][32-2], sbox_outs[i][32-8], sbox_outs[i][32-24], sbox_outs[i][32-14],
					  sbox_outs[i][32-32], sbox_outs[i][32-27], sbox_outs[i][32-3], sbox_outs[i][32-9],
					  sbox_outs[i][32-19], sbox_outs[i][32-13], sbox_outs[i][32-30], sbox_outs[i][32-6],
					  sbox_outs[i][32-22], sbox_outs[i][32-11], sbox_outs[i][32-4], sbox_outs[i][32-25]};
					  
			right_boxed[i] = left_boxed[i - 1]^f[i];
			
			// reversal concatenation:
			//reversal[i] = {right_boxed[i], left_boxed[i]};
		  
    end // end giant for loop
	 
	 //00001010 01001100 11011001 10010101 01000011 01000010 00110010 00110100 --> EXPECTED
	 //11101011 10101000 01000101 11001100 01110100 10111011 00001000 01100010 --> ACTUAL
	 //EBA8					45CC					74BB					0862
	 
	 reversal = {right_boxed[16], left_boxed[16]};
	 
	 msg = {reversal[64-40], reversal[64-8], reversal[64-48], reversal[64-16], reversal[64-56], reversal[64-24], reversal[64-64], reversal[64-32],
			  reversal[64-39], reversal[64-7], reversal[64-47], reversal[64-15], reversal[64-55], reversal[64-23], reversal[64-63], reversal[64-31],
			  reversal[64-38], reversal[64-6], reversal[64-46], reversal[64-14], reversal[64-54], reversal[64-22], reversal[64-62], reversal[64-30],
			  reversal[64-37], reversal[64-5], reversal[64-45], reversal[64-13], reversal[64-53], reversal[64-21], reversal[64-61], reversal[64-29],
			  reversal[64-36], reversal[64-4], reversal[64-44], reversal[64-12], reversal[64-52], reversal[64-20], reversal[64-60], reversal[64-28],
			  reversal[64-35], reversal[64-3], reversal[64-43], reversal[64-11], reversal[64-51], reversal[64-19], reversal[64-59], reversal[64-27],
			  reversal[64-34], reversal[64-2], reversal[64-42], reversal[64-10], reversal[64-50], reversal[64-18], reversal[64-58], reversal[64-26],
			  reversal[64-33], reversal[64-1], reversal[64-41], reversal[64-9], reversal[64-49], reversal[64-17], reversal[64-57], reversal[64-25]};
	 
	 //tempr = {32'd0, sbox_outs[1]};
	 
	 

end

// ****************************************************************************************************************************************************

/*
reg [3:0]S;
reg [3:0]NS;

reg [4:0]k;

parameter START = 4'd0,
			 FOR_INIT = 4'd1,
			 FOR_COND = 4'd2,
			 FOR_BODY = 4'd3,
			 INCR = 4'd4,
			 DONE = 4'd5,
			 ERROR = 4'hF;

// FSM init
always @(posedge clk or negedge rst)
begin
	if (rst == 1'b0)
		S = START;
	else
		S = NS;
end

// State transitions
always @(*)
begin
	case(S)
		START: NS = FOR_INIT;
		FOR_INIT: NS = FOR_COND;
		FOR_COND:
		begin
			if (k < 5'd17)
				NS = FOR_BODY;
			else
				NS = DONE;
		end
		FOR_BODY: NS = INCR;
		INCR: NS = FOR_COND;
		DONE: NS = DONE;
		default: NS = ERROR;
	endcase
end

// What to do in each State
always @(posedge clk or negedge rst)
begin
	if (rst == 1'b0)
		k = 5'd1;
	else
		case(S)
			START:
			begin
				k = 5'd1;
				
				left_boxed[16:0] = 544'd0;
				right_boxed[16:0] = 544'd0;
				e_transform[16:0] = 816'd0;
				keyXetran[16:0] = 816'd0;
				row[7:0] = 16'd0;
				column[7:0] = 32'd0;
				sbox_outs[16:0] = 544'd0;
				f[16:0] = 544'd0;
				reversal[16:0] = 1088'd0;
				
			end
			
			FOR_INIT: k = 5'd0;
			
			FOR_BODY:
			begin
				left_boxed[0] = L0;
				right_boxed[0] = R0;
				left_boxed[k] = right_boxed[k - 1];
				
				e_transform[k] = {right_boxed[k-1][32-32], right_boxed[k-1][32-1],  right_boxed[k-1][32-2],  right_boxed[k-1][32-3],  right_boxed[k-1][32-4],  right_boxed[k-1][32-5],
                            right_boxed[k-1][32-4],  right_boxed[k-1][32-5],  right_boxed[k-1][32-6],  right_boxed[k-1][32-7],  right_boxed[k-1][32-8],  right_boxed[k-1][32-9],
                            right_boxed[k-1][32-8],  right_boxed[k-1][32-9],  right_boxed[k-1][32-10], right_boxed[k-1][32-11], right_boxed[k-1][32-12], right_boxed[k-1][32-13],
                            right_boxed[k-1][32-12], right_boxed[k-1][32-13], right_boxed[k-1][32-14], right_boxed[k-1][32-15], right_boxed[k-1][32-16], right_boxed[k-1][32-17],
                            right_boxed[k-1][32-16], right_boxed[k-1][32-17], right_boxed[k-1][32-18], right_boxed[k-1][32-19], right_boxed[k-1][32-20], right_boxed[k-1][32-21],
                            right_boxed[k-1][32-20], right_boxed[k-1][32-21], right_boxed[k-1][32-22], right_boxed[k-1][32-23], right_boxed[k-1][32-24], right_boxed[k-1][32-25],
                            right_boxed[k-1][32-24], right_boxed[k-1][32-25], right_boxed[k-1][32-26], right_boxed[k-1][32-27], right_boxed[k-1][32-28], right_boxed[k-1][32-29],
                            right_boxed[k-1][32-28], right_boxed[k-1][32-29], right_boxed[k-1][32-30], right_boxed[k-1][32-31], right_boxed[k-1][32-32], right_boxed[k-1][32-1]};

									 
				keyXetran[k] = e_transform[k]^permutes[k];
				
				// s-box-1
				row[0] = {keyXetran[k][47], keyXetran[k][42]};
				column[0] = keyXetran[k][46:43];
				sbox_outs[k][31:28] = s_box[0][row[0]][8'd63 - column[0] * 4'd4 -: 4];
				
				// s-box-2
				row[1] = {keyXetran[k][41], keyXetran[k][36]};
				column[1] = keyXetran[k][40:37];
				sbox_outs[k][27:24] = s_box[1][row[1]][63 - column[1] * 4 -: 4];
			
				// s-box-3
				row[2] = {keyXetran[k][35], keyXetran[k][30]};
				column[2] = keyXetran[k][34:31];
				sbox_outs[k][23:20] = s_box[2][row[2]][63 - column[2] * 4 -: 4];
			
				// s-box-4
				row[3] = {keyXetran[k][29], keyXetran[k][24]};
				column[3] = keyXetran[k][28:25];
				sbox_outs[k][19:16] = s_box[3][row[3]][63 - column[3] * 4 -: 4];
			
				// s-box-5
				row[4] = {keyXetran[k][23], keyXetran[k][18]};
				column[4] = keyXetran[k][21:19];
				sbox_outs[k][15:12] = s_box[4][row[4]][63 - column[4] * 4 -: 4];
			
				// s-box-6
				row[5] = {keyXetran[k][17], keyXetran[k][12]};
				column[5] = keyXetran[k][16:13];
				sbox_outs[k][11:8] = s_box[5][row[5]][63 - column[5] * 4 -: 4];
			
				// s-box-7
				row[6] = {keyXetran[k][11], keyXetran[k][6]};
				column[6] = keyXetran[k][10:7];
				sbox_outs[k][7:4] = s_box[6][row[6]][63 - column[6] * 4 -: 4];
			
				// s-box-8
				row[7] = {keyXetran[k][5], keyXetran[k][0]};
				column[7] = keyXetran[k][4:1];
				sbox_outs[k][3:0] = s_box[7][row[7]][63 - column[7] * 4 -: 4];
				
				sbox_outs_k1 = {32'd0, sbox_outs[1]};
				
			end
			
			INCR: k = k + 5'd1;
		endcase
end
*/

endmodule
