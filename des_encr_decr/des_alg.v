// Runs the DES algorithm.

module des_alg(
input mode, // 1 if encr, 0 if decr
input [63:0]key, // user-entered 64-bit key
input [63:0]value, // user-entered 64-bit value
output reg [63:0]msg // output of des encryption
);

reg [55:0] key_plus; // initial 56-bit permutation of the key
reg [27:0] C0; // left half of key_plus
reg [27:0] D0; // right half of key_plus

// Numbering: only 16:1 are used to stay consistent with steps from our main resource
reg [27:0] c_blocks [16:0]; // shifting C0 to get C[i]
reg [27:0] d_blocks [16:0]; // shifting D0 to get D[i]

// Numbering: only 16:1 are used to stay consistent with steps from our main resource
reg [55:0] concat [16:0];	// {c_blocks[i], d_blocks[i]}
reg [47:0] permutes [16:0]; // concat[1] --> K[i]

reg [63:0] value_plus; // value is being transformed by IP (permutation)

reg [31:0] L0;	// left half of value_plus
reg [31:0] R0;	// right half of value_plus

reg [63:0] s_box[7:0][3:0]; // 63 bit wide entries per row, 8 sboxes, 4 rows per sbox

// Numbering: only 16:1 are used to stay consistent with steps from our main resource
reg [31:0] right_boxed [16:0]; // right half of value plus: R[i]
reg [31:0] left_boxed [16:0]; // left half of value plus: L[i]

// Numbering: only 16:1 are used to stay consistent with steps from our main resource
reg [47:0] e_transform [16:0]; // E(right_boxed[i-1])
reg [47:0] keyXetran [16:0];	// K[i] + E(right_boxed[i])

// Numbering: only 16:1 are used to stay consistent with steps from our main resource
reg [31:0] sbox_outs[16:0]; // 32 bit wide entries, 16 different outputs (ignoring index 0)
reg [1:0] row[7:0];	// row number of the sbox (i), 0 is used here
reg [3:0] column[7:0]; // column number of the sbox (j), 0 is used here

// Numbering: only 16:1 are used to stay consistent with steps from our main resource
reg [31:0] f[16:0]; // function f in Step 2

reg [63:0] reversal; // R16L16

always @(*)
begin

	// Creating the initial 56-bit permutation of the key
	key_plus = {key[64-57], key[64-49], key[64-41], key[64-33], key[64-25], key[64-17], key[64-9],
               key[64-1],  key[64-58], key[64-50], key[64-42], key[64-34], key[64-26], key[64-18],
               key[64-10], key[64-2],  key[64-59], key[64-51], key[64-43], key[64-35], key[64-27],
               key[64-19], key[64-11], key[64-3],  key[64-60], key[64-52], key[64-44], key[64-36],
               key[64-63], key[64-55], key[64-47], key[64-39], key[64-31], key[64-23], key[64-15],
               key[64-7],  key[64-62], key[64-54], key[64-46], key[64-38], key[64-30], key[64-22],
               key[64-14], key[64-6],  key[64-61], key[64-53], key[64-45], key[64-37], key[64-29],
               key[64-21], key[64-13], key[64-5],  key[64-28], key[64-20], key[64-12], key[64-4]};
	
	// left and right half of key_plus
   C0 = key_plus[55:28];
   D0 = key_plus[27:0];
	
	// Creating the shifted blocks from C0 and D0:
	c_blocks[0] = C0;
	d_blocks[0] = D0;

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
	 
	// **********************************************************************************************************************************
	// Concatenating the c_blocks and d_blocks together
	 
	concat[1] = {c_blocks[1], d_blocks[1]};
	concat[2] = {c_blocks[2], d_blocks[2]};
	concat[3] = {c_blocks[3], d_blocks[3]};
	concat[4] = {c_blocks[4], d_blocks[4]};
	 
	concat[5] = {c_blocks[5], d_blocks[5]};
	concat[6] = {c_blocks[6], d_blocks[6]};
	concat[7] = {c_blocks[7], d_blocks[7]};
	concat[8] = {c_blocks[8], d_blocks[8]};
	 
	concat[9] = {c_blocks[9], d_blocks[9]};
	concat[10] = {c_blocks[10], d_blocks[10]};
	concat[11] = {c_blocks[11], d_blocks[11]};
	concat[12] = {c_blocks[12], d_blocks[12]};
	 
	concat[13] = {c_blocks[13], d_blocks[13]};
	concat[14] = {c_blocks[14], d_blocks[14]};
	concat[15] = {c_blocks[15], d_blocks[15]};
	concat[16] = {c_blocks[16], d_blocks[16]};
	 
	// *********************************************************************************************************************************
	// Calculating the sub keys (aka permutes) - if mode == 1'b1 aka encryption or mode == 1'b0 aka decryption
	 
	if (mode == 1'b1)
	begin
		permutes[1] = {concat[1][56-14], concat[1][56-17], concat[1][56-11], concat[1][56-24], concat[1][56-1],  concat[1][56-5],
							concat[1][56-3],  concat[1][56-28], concat[1][56-15], concat[1][56-6],  concat[1][56-21], concat[1][56-10],
							concat[1][56-23], concat[1][56-19], concat[1][56-12], concat[1][56-4],  concat[1][56-26], concat[1][56-8],
							concat[1][56-16], concat[1][56-7],  concat[1][56-27], concat[1][56-20], concat[1][56-13], concat[1][56-2],
							concat[1][56-41], concat[1][56-52], concat[1][56-31], concat[1][56-37], concat[1][56-47], concat[1][56-55],
							concat[1][56-30], concat[1][56-40], concat[1][56-51], concat[1][56-45], concat[1][56-33], concat[1][56-48],
							concat[1][56-44], concat[1][56-49], concat[1][56-39], concat[1][56-56], concat[1][56-34], concat[1][56-53],
							concat[1][56-46], concat[1][56-42], concat[1][56-50], concat[1][56-36], concat[1][56-29], concat[1][56-32]};
						 
		permutes[2] = {concat[2][56-14], concat[2][56-17], concat[2][56-11], concat[2][56-24], concat[2][56-1],  concat[2][56-5],
							concat[2][56-3],  concat[2][56-28], concat[2][56-15], concat[2][56-6],  concat[2][56-21], concat[2][56-10],
							concat[2][56-23], concat[2][56-19], concat[2][56-12], concat[2][56-4],  concat[2][56-26], concat[2][56-8],
							concat[2][56-16], concat[2][56-7],  concat[2][56-27], concat[2][56-20], concat[2][56-13], concat[2][56-2],
							concat[2][56-41], concat[2][56-52], concat[2][56-31], concat[2][56-37], concat[2][56-47], concat[2][56-55],
							concat[2][56-30], concat[2][56-40], concat[2][56-51], concat[2][56-45], concat[2][56-33], concat[2][56-48],
							concat[2][56-44], concat[2][56-49], concat[2][56-39], concat[2][56-56], concat[2][56-34], concat[2][56-53],
							concat[2][56-46], concat[2][56-42], concat[2][56-50], concat[2][56-36], concat[2][56-29], concat[2][56-32]};
						
		permutes[3] = {concat[3][56-14], concat[3][56-17], concat[3][56-11], concat[3][56-24], concat[3][56-1],  concat[3][56-5],
							concat[3][56-3],  concat[3][56-28], concat[3][56-15], concat[3][56-6],  concat[3][56-21], concat[3][56-10],
							concat[3][56-23], concat[3][56-19], concat[3][56-12], concat[3][56-4],  concat[3][56-26], concat[3][56-8],
							concat[3][56-16], concat[3][56-7],  concat[3][56-27], concat[3][56-20], concat[3][56-13], concat[3][56-2],
							concat[3][56-41], concat[3][56-52], concat[3][56-31], concat[3][56-37], concat[3][56-47], concat[3][56-55],
							concat[3][56-30], concat[3][56-40], concat[3][56-51], concat[3][56-45], concat[3][56-33], concat[3][56-48],
							concat[3][56-44], concat[3][56-49], concat[3][56-39], concat[3][56-56], concat[3][56-34], concat[3][56-53],
							concat[3][56-46], concat[3][56-42], concat[3][56-50], concat[3][56-36], concat[3][56-29], concat[3][56-32]};
						
		permutes[4] = {concat[4][56-14], concat[4][56-17], concat[4][56-11], concat[4][56-24], concat[4][56-1],  concat[4][56-5],
							concat[4][56-3],  concat[4][56-28], concat[4][56-15], concat[4][56-6],  concat[4][56-21], concat[4][56-10],
							concat[4][56-23], concat[4][56-19], concat[4][56-12], concat[4][56-4],  concat[4][56-26], concat[4][56-8],
							concat[4][56-16], concat[4][56-7],  concat[4][56-27], concat[4][56-20], concat[4][56-13], concat[4][56-2],
							concat[4][56-41], concat[4][56-52], concat[4][56-31], concat[4][56-37], concat[4][56-47], concat[4][56-55],
							concat[4][56-30], concat[4][56-40], concat[4][56-51], concat[4][56-45], concat[4][56-33], concat[4][56-48],
							concat[4][56-44], concat[4][56-49], concat[4][56-39], concat[4][56-56], concat[4][56-34], concat[4][56-53],
							concat[4][56-46], concat[4][56-42], concat[4][56-50], concat[4][56-36], concat[4][56-29], concat[4][56-32]};
						
		permutes[5] = {concat[5][56-14], concat[5][56-17], concat[5][56-11], concat[5][56-24], concat[5][56-1],  concat[5][56-5],
							concat[5][56-3],  concat[5][56-28], concat[5][56-15], concat[5][56-6],  concat[5][56-21], concat[5][56-10],
							concat[5][56-23], concat[5][56-19], concat[5][56-12], concat[5][56-4],  concat[5][56-26], concat[5][56-8],
							concat[5][56-16], concat[5][56-7],  concat[5][56-27], concat[5][56-20], concat[5][56-13], concat[5][56-2],
							concat[5][56-41], concat[5][56-52], concat[5][56-31], concat[5][56-37], concat[5][56-47], concat[5][56-55],
							concat[5][56-30], concat[5][56-40], concat[5][56-51], concat[5][56-45], concat[5][56-33], concat[5][56-48],
							concat[5][56-44], concat[5][56-49], concat[5][56-39], concat[5][56-56], concat[5][56-34], concat[5][56-53],
							concat[5][56-46], concat[5][56-42], concat[5][56-50], concat[5][56-36], concat[5][56-29], concat[5][56-32]};
						
		permutes[6] = {concat[6][56-14], concat[6][56-17], concat[6][56-11], concat[6][56-24], concat[6][56-1],  concat[6][56-5],
							concat[6][56-3],  concat[6][56-28], concat[6][56-15], concat[6][56-6],  concat[6][56-21], concat[6][56-10],
							concat[6][56-23], concat[6][56-19], concat[6][56-12], concat[6][56-4],  concat[6][56-26], concat[6][56-8],
							concat[6][56-16], concat[6][56-7],  concat[6][56-27], concat[6][56-20], concat[6][56-13], concat[6][56-2],
							concat[6][56-41], concat[6][56-52], concat[6][56-31], concat[6][56-37], concat[6][56-47], concat[6][56-55],
							concat[6][56-30], concat[6][56-40], concat[6][56-51], concat[6][56-45], concat[6][56-33], concat[6][56-48],
							concat[6][56-44], concat[6][56-49], concat[6][56-39], concat[6][56-56], concat[6][56-34], concat[6][56-53],
							concat[6][56-46], concat[6][56-42], concat[6][56-50], concat[6][56-36], concat[6][56-29], concat[6][56-32]};
						
		permutes[7] = {concat[7][56-14], concat[7][56-17], concat[7][56-11], concat[7][56-24], concat[7][56-1],  concat[7][56-5],
							concat[7][56-3],  concat[7][56-28], concat[7][56-15], concat[7][56-6],  concat[7][56-21], concat[7][56-10],
							concat[7][56-23], concat[7][56-19], concat[7][56-12], concat[7][56-4],  concat[7][56-26], concat[7][56-8],
							concat[7][56-16], concat[7][56-7],  concat[7][56-27], concat[7][56-20], concat[7][56-13], concat[7][56-2],
							concat[7][56-41], concat[7][56-52], concat[7][56-31], concat[7][56-37], concat[7][56-47], concat[7][56-55],
							concat[7][56-30], concat[7][56-40], concat[7][56-51], concat[7][56-45], concat[7][56-33], concat[7][56-48],
							concat[7][56-44], concat[7][56-49], concat[7][56-39], concat[7][56-56], concat[7][56-34], concat[7][56-53],
							concat[7][56-46], concat[7][56-42], concat[7][56-50], concat[7][56-36], concat[7][56-29], concat[7][56-32]};
						
		permutes[8] = {concat[8][56-14], concat[8][56-17], concat[8][56-11], concat[8][56-24], concat[8][56-1],  concat[8][56-5],
							concat[8][56-3],  concat[8][56-28], concat[8][56-15], concat[8][56-6],  concat[8][56-21], concat[8][56-10],
							concat[8][56-23], concat[8][56-19], concat[8][56-12], concat[8][56-4],  concat[8][56-26], concat[8][56-8],
							concat[8][56-16], concat[8][56-7],  concat[8][56-27], concat[8][56-20], concat[8][56-13], concat[8][56-2],
							concat[8][56-41], concat[8][56-52], concat[8][56-31], concat[8][56-37], concat[8][56-47], concat[8][56-55],
							concat[8][56-30], concat[8][56-40], concat[8][56-51], concat[8][56-45], concat[8][56-33], concat[8][56-48],
							concat[8][56-44], concat[8][56-49], concat[8][56-39], concat[8][56-56], concat[8][56-34], concat[8][56-53],
							concat[8][56-46], concat[8][56-42], concat[8][56-50], concat[8][56-36], concat[8][56-29], concat[8][56-32]};
							
		permutes[9] = {concat[9][56-14], concat[9][56-17], concat[9][56-11], concat[9][56-24], concat[9][56-1],  concat[9][56-5],
							concat[9][56-3],  concat[9][56-28], concat[9][56-15], concat[9][56-6],  concat[9][56-21], concat[9][56-10],
							concat[9][56-23], concat[9][56-19], concat[9][56-12], concat[9][56-4],  concat[9][56-26], concat[9][56-8],
							concat[9][56-16], concat[9][56-7],  concat[9][56-27], concat[9][56-20], concat[9][56-13], concat[9][56-2],
							concat[9][56-41], concat[9][56-52], concat[9][56-31], concat[9][56-37], concat[9][56-47], concat[9][56-55],
							concat[9][56-30], concat[9][56-40], concat[9][56-51], concat[9][56-45], concat[9][56-33], concat[9][56-48],
							concat[9][56-44], concat[9][56-49], concat[9][56-39], concat[9][56-56], concat[9][56-34], concat[9][56-53],
							concat[9][56-46], concat[9][56-42], concat[9][56-50], concat[9][56-36], concat[9][56-29], concat[9][56-32]};
						
		permutes[10] = {concat[10][56-14], concat[10][56-17], concat[10][56-11], concat[10][56-24], concat[10][56-1],  concat[10][56-5],
							concat[10][56-3],  concat[10][56-28], concat[10][56-15], concat[10][56-6],  concat[10][56-21], concat[10][56-10],
							concat[10][56-23], concat[10][56-19], concat[10][56-12], concat[10][56-4],  concat[10][56-26], concat[10][56-8],
							concat[10][56-16], concat[10][56-7],  concat[10][56-27], concat[10][56-20], concat[10][56-13], concat[10][56-2],
							concat[10][56-41], concat[10][56-52], concat[10][56-31], concat[10][56-37], concat[10][56-47], concat[10][56-55],
							concat[10][56-30], concat[10][56-40], concat[10][56-51], concat[10][56-45], concat[10][56-33], concat[10][56-48],
							concat[10][56-44], concat[10][56-49], concat[10][56-39], concat[10][56-56], concat[10][56-34], concat[10][56-53],
							concat[10][56-46], concat[10][56-42], concat[10][56-50], concat[10][56-36], concat[10][56-29], concat[10][56-32]};
						
		permutes[11] = {concat[11][56-14], concat[11][56-17], concat[11][56-11], concat[11][56-24], concat[11][56-1],  concat[11][56-5],
							 concat[11][56-3],  concat[11][56-28], concat[11][56-15], concat[11][56-6],  concat[11][56-21], concat[11][56-10],
							 concat[11][56-23], concat[11][56-19], concat[11][56-12], concat[11][56-4],  concat[11][56-26], concat[11][56-8],
							 concat[11][56-16], concat[11][56-7],  concat[11][56-27], concat[11][56-20], concat[11][56-13], concat[11][56-2],
							 concat[11][56-41], concat[11][56-52], concat[11][56-31], concat[11][56-37], concat[11][56-47], concat[11][56-55],
							 concat[11][56-30], concat[11][56-40], concat[11][56-51], concat[11][56-45], concat[11][56-33], concat[11][56-48],
							 concat[11][56-44], concat[11][56-49], concat[11][56-39], concat[11][56-56], concat[11][56-34], concat[11][56-53],
							 concat[11][56-46], concat[11][56-42], concat[11][56-50], concat[11][56-36], concat[11][56-29], concat[11][56-32]};
						 
		permutes[12] = {concat[12][56-14], concat[12][56-17], concat[12][56-11], concat[12][56-24], concat[12][56-1],  concat[12][56-5],
							 concat[12][56-3],  concat[12][56-28], concat[12][56-15], concat[12][56-6],  concat[12][56-21], concat[12][56-10],
							 concat[12][56-23], concat[12][56-19], concat[12][56-12], concat[12][56-4],  concat[12][56-26], concat[12][56-8],
							 concat[12][56-16], concat[12][56-7],  concat[12][56-27], concat[12][56-20], concat[12][56-13], concat[12][56-2],
							 concat[12][56-41], concat[12][56-52], concat[12][56-31], concat[12][56-37], concat[12][56-47], concat[12][56-55],
							 concat[12][56-30], concat[12][56-40], concat[12][56-51], concat[12][56-45], concat[12][56-33], concat[12][56-48],
							 concat[12][56-44], concat[12][56-49], concat[12][56-39], concat[12][56-56], concat[12][56-34], concat[12][56-53],
							 concat[12][56-46], concat[12][56-42], concat[12][56-50], concat[12][56-36], concat[12][56-29], concat[12][56-32]};
						 
		permutes[13] = {concat[13][56-14], concat[13][56-17], concat[13][56-11], concat[13][56-24], concat[13][56-1],  concat[13][56-5],
							 concat[13][56-3],  concat[13][56-28], concat[13][56-15], concat[13][56-6],  concat[13][56-21], concat[13][56-10],
							 concat[13][56-23], concat[13][56-19], concat[13][56-12], concat[13][56-4],  concat[13][56-26], concat[13][56-8],
							 concat[13][56-16], concat[13][56-7],  concat[13][56-27], concat[13][56-20], concat[13][56-13], concat[13][56-2],
							 concat[13][56-41], concat[13][56-52], concat[13][56-31], concat[13][56-37], concat[13][56-47], concat[13][56-55],
							 concat[13][56-30], concat[13][56-40], concat[13][56-51], concat[13][56-45], concat[13][56-33], concat[13][56-48],
							 concat[13][56-44], concat[13][56-49], concat[13][56-39], concat[13][56-56], concat[13][56-34], concat[13][56-53],
							 concat[13][56-46], concat[13][56-42], concat[13][56-50], concat[13][56-36], concat[13][56-29], concat[13][56-32]};
						 
		permutes[14] = {concat[14][56-14], concat[14][56-17], concat[14][56-11], concat[14][56-24], concat[14][56-1],  concat[14][56-5],
							 concat[14][56-3],  concat[14][56-28], concat[14][56-15], concat[14][56-6],  concat[14][56-21], concat[14][56-10],
							 concat[14][56-23], concat[14][56-19], concat[14][56-12], concat[14][56-4],  concat[14][56-26], concat[14][56-8],
							 concat[14][56-16], concat[14][56-7],  concat[14][56-27], concat[14][56-20], concat[14][56-13], concat[14][56-2],
							 concat[14][56-41], concat[14][56-52], concat[14][56-31], concat[14][56-37], concat[14][56-47], concat[14][56-55],
							 concat[14][56-30], concat[14][56-40], concat[14][56-51], concat[14][56-45], concat[14][56-33], concat[14][56-48],
							 concat[14][56-44], concat[14][56-49], concat[14][56-39], concat[14][56-56], concat[14][56-34], concat[14][56-53],
							 concat[14][56-46], concat[14][56-42], concat[14][56-50], concat[14][56-36], concat[14][56-29], concat[14][56-32]};
						 
		permutes[15] = {concat[15][56-14], concat[15][56-17], concat[15][56-11], concat[15][56-24], concat[15][56-1],  concat[15][56-5],
							 concat[15][56-3],  concat[15][56-28], concat[15][56-15], concat[15][56-6],  concat[15][56-21], concat[15][56-10],
							 concat[15][56-23], concat[15][56-19], concat[15][56-12], concat[15][56-4],  concat[15][56-26], concat[15][56-8],
							 concat[15][56-16], concat[15][56-7],  concat[15][56-27], concat[15][56-20], concat[15][56-13], concat[15][56-2],
							 concat[15][56-41], concat[15][56-52], concat[15][56-31], concat[15][56-37], concat[15][56-47], concat[15][56-55],
							 concat[15][56-30], concat[15][56-40], concat[15][56-51], concat[15][56-45], concat[15][56-33], concat[15][56-48],
							 concat[15][56-44], concat[15][56-49], concat[15][56-39], concat[15][56-56], concat[15][56-34], concat[15][56-53],
							 concat[15][56-46], concat[15][56-42], concat[15][56-50], concat[15][56-36], concat[15][56-29], concat[15][56-32]};
						 
		permutes[16] = {concat[16][56-14], concat[16][56-17], concat[16][56-11], concat[16][56-24], concat[16][56-1],  concat[16][56-5],
							 concat[16][56-3],  concat[16][56-28], concat[16][56-15], concat[16][56-6],  concat[16][56-21], concat[16][56-10],
							 concat[16][56-23], concat[16][56-19], concat[16][56-12], concat[16][56-4],  concat[16][56-26], concat[16][56-8],
							 concat[16][56-16], concat[16][56-7],  concat[16][56-27], concat[16][56-20], concat[16][56-13], concat[16][56-2],
							 concat[16][56-41], concat[16][56-52], concat[16][56-31], concat[16][56-37], concat[16][56-47], concat[16][56-55],
							 concat[16][56-30], concat[16][56-40], concat[16][56-51], concat[16][56-45], concat[16][56-33], concat[16][56-48],
							 concat[16][56-44], concat[16][56-49], concat[16][56-39], concat[16][56-56], concat[16][56-34], concat[16][56-53],
							 concat[16][56-46], concat[16][56-42], concat[16][56-50], concat[16][56-36], concat[16][56-29], concat[16][56-32]};
						 
	end else if (mode == 1'b0)
	begin
		
		permutes[16] = {concat[1][56-14], concat[1][56-17], concat[1][56-11], concat[1][56-24], concat[1][56-1],  concat[1][56-5],
							 concat[1][56-3],  concat[1][56-28], concat[1][56-15], concat[1][56-6],  concat[1][56-21], concat[1][56-10],
							 concat[1][56-23], concat[1][56-19], concat[1][56-12], concat[1][56-4],  concat[1][56-26], concat[1][56-8],
							 concat[1][56-16], concat[1][56-7],  concat[1][56-27], concat[1][56-20], concat[1][56-13], concat[1][56-2],
							 concat[1][56-41], concat[1][56-52], concat[1][56-31], concat[1][56-37], concat[1][56-47], concat[1][56-55],
							 concat[1][56-30], concat[1][56-40], concat[1][56-51], concat[1][56-45], concat[1][56-33], concat[1][56-48],
							 concat[1][56-44], concat[1][56-49], concat[1][56-39], concat[1][56-56], concat[1][56-34], concat[1][56-53],
							 concat[1][56-46], concat[1][56-42], concat[1][56-50], concat[1][56-36], concat[1][56-29], concat[1][56-32]};
						 
		permutes[15] = {concat[2][56-14], concat[2][56-17], concat[2][56-11], concat[2][56-24], concat[2][56-1],  concat[2][56-5],
							 concat[2][56-3],  concat[2][56-28], concat[2][56-15], concat[2][56-6],  concat[2][56-21], concat[2][56-10],
							 concat[2][56-23], concat[2][56-19], concat[2][56-12], concat[2][56-4],  concat[2][56-26], concat[2][56-8],
							 concat[2][56-16], concat[2][56-7],  concat[2][56-27], concat[2][56-20], concat[2][56-13], concat[2][56-2],
							 concat[2][56-41], concat[2][56-52], concat[2][56-31], concat[2][56-37], concat[2][56-47], concat[2][56-55],
							 concat[2][56-30], concat[2][56-40], concat[2][56-51], concat[2][56-45], concat[2][56-33], concat[2][56-48],
							 concat[2][56-44], concat[2][56-49], concat[2][56-39], concat[2][56-56], concat[2][56-34], concat[2][56-53],
							 concat[2][56-46], concat[2][56-42], concat[2][56-50], concat[2][56-36], concat[2][56-29], concat[2][56-32]};
						
		permutes[14] = {concat[3][56-14], concat[3][56-17], concat[3][56-11], concat[3][56-24], concat[3][56-1],  concat[3][56-5],
							 concat[3][56-3],  concat[3][56-28], concat[3][56-15], concat[3][56-6],  concat[3][56-21], concat[3][56-10],
							 concat[3][56-23], concat[3][56-19], concat[3][56-12], concat[3][56-4],  concat[3][56-26], concat[3][56-8],
							 concat[3][56-16], concat[3][56-7],  concat[3][56-27], concat[3][56-20], concat[3][56-13], concat[3][56-2],
							 concat[3][56-41], concat[3][56-52], concat[3][56-31], concat[3][56-37], concat[3][56-47], concat[3][56-55],
							 concat[3][56-30], concat[3][56-40], concat[3][56-51], concat[3][56-45], concat[3][56-33], concat[3][56-48],
							 concat[3][56-44], concat[3][56-49], concat[3][56-39], concat[3][56-56], concat[3][56-34], concat[3][56-53],
							 concat[3][56-46], concat[3][56-42], concat[3][56-50], concat[3][56-36], concat[3][56-29], concat[3][56-32]};
						
		permutes[13] = {concat[4][56-14], concat[4][56-17], concat[4][56-11], concat[4][56-24], concat[4][56-1],  concat[4][56-5],
							 concat[4][56-3],  concat[4][56-28], concat[4][56-15], concat[4][56-6],  concat[4][56-21], concat[4][56-10],
							 concat[4][56-23], concat[4][56-19], concat[4][56-12], concat[4][56-4],  concat[4][56-26], concat[4][56-8],
							 concat[4][56-16], concat[4][56-7],  concat[4][56-27], concat[4][56-20], concat[4][56-13], concat[4][56-2],
							 concat[4][56-41], concat[4][56-52], concat[4][56-31], concat[4][56-37], concat[4][56-47], concat[4][56-55],
							 concat[4][56-30], concat[4][56-40], concat[4][56-51], concat[4][56-45], concat[4][56-33], concat[4][56-48],
							 concat[4][56-44], concat[4][56-49], concat[4][56-39], concat[4][56-56], concat[4][56-34], concat[4][56-53],
							 concat[4][56-46], concat[4][56-42], concat[4][56-50], concat[4][56-36], concat[4][56-29], concat[4][56-32]};
						
		permutes[12] = {concat[5][56-14], concat[5][56-17], concat[5][56-11], concat[5][56-24], concat[5][56-1],  concat[5][56-5],
							 concat[5][56-3],  concat[5][56-28], concat[5][56-15], concat[5][56-6],  concat[5][56-21], concat[5][56-10],
							 concat[5][56-23], concat[5][56-19], concat[5][56-12], concat[5][56-4],  concat[5][56-26], concat[5][56-8],
							 concat[5][56-16], concat[5][56-7],  concat[5][56-27], concat[5][56-20], concat[5][56-13], concat[5][56-2],
							 concat[5][56-41], concat[5][56-52], concat[5][56-31], concat[5][56-37], concat[5][56-47], concat[5][56-55],
							 concat[5][56-30], concat[5][56-40], concat[5][56-51], concat[5][56-45], concat[5][56-33], concat[5][56-48],
							 concat[5][56-44], concat[5][56-49], concat[5][56-39], concat[5][56-56], concat[5][56-34], concat[5][56-53],
							 concat[5][56-46], concat[5][56-42], concat[5][56-50], concat[5][56-36], concat[5][56-29], concat[5][56-32]};
						
		permutes[11] = {concat[6][56-14], concat[6][56-17], concat[6][56-11], concat[6][56-24], concat[6][56-1],  concat[6][56-5],
							 concat[6][56-3],  concat[6][56-28], concat[6][56-15], concat[6][56-6],  concat[6][56-21], concat[6][56-10],
							 concat[6][56-23], concat[6][56-19], concat[6][56-12], concat[6][56-4],  concat[6][56-26], concat[6][56-8],
							 concat[6][56-16], concat[6][56-7],  concat[6][56-27], concat[6][56-20], concat[6][56-13], concat[6][56-2],
							 concat[6][56-41], concat[6][56-52], concat[6][56-31], concat[6][56-37], concat[6][56-47], concat[6][56-55],
							 concat[6][56-30], concat[6][56-40], concat[6][56-51], concat[6][56-45], concat[6][56-33], concat[6][56-48],
							 concat[6][56-44], concat[6][56-49], concat[6][56-39], concat[6][56-56], concat[6][56-34], concat[6][56-53],
							 concat[6][56-46], concat[6][56-42], concat[6][56-50], concat[6][56-36], concat[6][56-29], concat[6][56-32]};
						
		permutes[10] = {concat[7][56-14], concat[7][56-17], concat[7][56-11], concat[7][56-24], concat[7][56-1],  concat[7][56-5],
							 concat[7][56-3],  concat[7][56-28], concat[7][56-15], concat[7][56-6],  concat[7][56-21], concat[7][56-10],
							 concat[7][56-23], concat[7][56-19], concat[7][56-12], concat[7][56-4],  concat[7][56-26], concat[7][56-8],
							 concat[7][56-16], concat[7][56-7],  concat[7][56-27], concat[7][56-20], concat[7][56-13], concat[7][56-2],
							 concat[7][56-41], concat[7][56-52], concat[7][56-31], concat[7][56-37], concat[7][56-47], concat[7][56-55],
							 concat[7][56-30], concat[7][56-40], concat[7][56-51], concat[7][56-45], concat[7][56-33], concat[7][56-48],
							 concat[7][56-44], concat[7][56-49], concat[7][56-39], concat[7][56-56], concat[7][56-34], concat[7][56-53],
							 concat[7][56-46], concat[7][56-42], concat[7][56-50], concat[7][56-36], concat[7][56-29], concat[7][56-32]};
						
		permutes[9] = {concat[8][56-14], concat[8][56-17], concat[8][56-11], concat[8][56-24], concat[8][56-1],  concat[8][56-5],
							concat[8][56-3],  concat[8][56-28], concat[8][56-15], concat[8][56-6],  concat[8][56-21], concat[8][56-10],
							concat[8][56-23], concat[8][56-19], concat[8][56-12], concat[8][56-4],  concat[8][56-26], concat[8][56-8],
							concat[8][56-16], concat[8][56-7],  concat[8][56-27], concat[8][56-20], concat[8][56-13], concat[8][56-2],
							concat[8][56-41], concat[8][56-52], concat[8][56-31], concat[8][56-37], concat[8][56-47], concat[8][56-55],
							concat[8][56-30], concat[8][56-40], concat[8][56-51], concat[8][56-45], concat[8][56-33], concat[8][56-48],
							concat[8][56-44], concat[8][56-49], concat[8][56-39], concat[8][56-56], concat[8][56-34], concat[8][56-53],
							concat[8][56-46], concat[8][56-42], concat[8][56-50], concat[8][56-36], concat[8][56-29], concat[8][56-32]};
							
		permutes[8] = {concat[9][56-14], concat[9][56-17], concat[9][56-11], concat[9][56-24], concat[9][56-1],  concat[9][56-5],
							concat[9][56-3],  concat[9][56-28], concat[9][56-15], concat[9][56-6],  concat[9][56-21], concat[9][56-10],
							concat[9][56-23], concat[9][56-19], concat[9][56-12], concat[9][56-4],  concat[9][56-26], concat[9][56-8],
							concat[9][56-16], concat[9][56-7],  concat[9][56-27], concat[9][56-20], concat[9][56-13], concat[9][56-2],
							concat[9][56-41], concat[9][56-52], concat[9][56-31], concat[9][56-37], concat[9][56-47], concat[9][56-55],
							concat[9][56-30], concat[9][56-40], concat[9][56-51], concat[9][56-45], concat[9][56-33], concat[9][56-48],
							concat[9][56-44], concat[9][56-49], concat[9][56-39], concat[9][56-56], concat[9][56-34], concat[9][56-53],
							concat[9][56-46], concat[9][56-42], concat[9][56-50], concat[9][56-36], concat[9][56-29], concat[9][56-32]};
						
		permutes[7] = {concat[10][56-14], concat[10][56-17], concat[10][56-11], concat[10][56-24], concat[10][56-1],  concat[10][56-5],
							concat[10][56-3],  concat[10][56-28], concat[10][56-15], concat[10][56-6],  concat[10][56-21], concat[10][56-10],
							concat[10][56-23], concat[10][56-19], concat[10][56-12], concat[10][56-4],  concat[10][56-26], concat[10][56-8],
							concat[10][56-16], concat[10][56-7],  concat[10][56-27], concat[10][56-20], concat[10][56-13], concat[10][56-2],
							concat[10][56-41], concat[10][56-52], concat[10][56-31], concat[10][56-37], concat[10][56-47], concat[10][56-55],
							concat[10][56-30], concat[10][56-40], concat[10][56-51], concat[10][56-45], concat[10][56-33], concat[10][56-48],
							concat[10][56-44], concat[10][56-49], concat[10][56-39], concat[10][56-56], concat[10][56-34], concat[10][56-53],
							concat[10][56-46], concat[10][56-42], concat[10][56-50], concat[10][56-36], concat[10][56-29], concat[10][56-32]};
						
		permutes[6] = {concat[11][56-14], concat[11][56-17], concat[11][56-11], concat[11][56-24], concat[11][56-1],  concat[11][56-5],
							concat[11][56-3],  concat[11][56-28], concat[11][56-15], concat[11][56-6],  concat[11][56-21], concat[11][56-10],
							concat[11][56-23], concat[11][56-19], concat[11][56-12], concat[11][56-4],  concat[11][56-26], concat[11][56-8],
							concat[11][56-16], concat[11][56-7],  concat[11][56-27], concat[11][56-20], concat[11][56-13], concat[11][56-2],
							concat[11][56-41], concat[11][56-52], concat[11][56-31], concat[11][56-37], concat[11][56-47], concat[11][56-55],
							concat[11][56-30], concat[11][56-40], concat[11][56-51], concat[11][56-45], concat[11][56-33], concat[11][56-48],
							concat[11][56-44], concat[11][56-49], concat[11][56-39], concat[11][56-56], concat[11][56-34], concat[11][56-53],
							concat[11][56-46], concat[11][56-42], concat[11][56-50], concat[11][56-36], concat[11][56-29], concat[11][56-32]};
						 
		permutes[5] = {concat[12][56-14], concat[12][56-17], concat[12][56-11], concat[12][56-24], concat[12][56-1],  concat[12][56-5],
							concat[12][56-3],  concat[12][56-28], concat[12][56-15], concat[12][56-6],  concat[12][56-21], concat[12][56-10],
							concat[12][56-23], concat[12][56-19], concat[12][56-12], concat[12][56-4],  concat[12][56-26], concat[12][56-8],
							concat[12][56-16], concat[12][56-7],  concat[12][56-27], concat[12][56-20], concat[12][56-13], concat[12][56-2],
							concat[12][56-41], concat[12][56-52], concat[12][56-31], concat[12][56-37], concat[12][56-47], concat[12][56-55],
							concat[12][56-30], concat[12][56-40], concat[12][56-51], concat[12][56-45], concat[12][56-33], concat[12][56-48],
							concat[12][56-44], concat[12][56-49], concat[12][56-39], concat[12][56-56], concat[12][56-34], concat[12][56-53],
							concat[12][56-46], concat[12][56-42], concat[12][56-50], concat[12][56-36], concat[12][56-29], concat[12][56-32]};
						 
		permutes[4] = {concat[13][56-14], concat[13][56-17], concat[13][56-11], concat[13][56-24], concat[13][56-1],  concat[13][56-5],
							concat[13][56-3],  concat[13][56-28], concat[13][56-15], concat[13][56-6],  concat[13][56-21], concat[13][56-10],
							concat[13][56-23], concat[13][56-19], concat[13][56-12], concat[13][56-4],  concat[13][56-26], concat[13][56-8],
							concat[13][56-16], concat[13][56-7],  concat[13][56-27], concat[13][56-20], concat[13][56-13], concat[13][56-2],
							concat[13][56-41], concat[13][56-52], concat[13][56-31], concat[13][56-37], concat[13][56-47], concat[13][56-55],
							concat[13][56-30], concat[13][56-40], concat[13][56-51], concat[13][56-45], concat[13][56-33], concat[13][56-48],
							concat[13][56-44], concat[13][56-49], concat[13][56-39], concat[13][56-56], concat[13][56-34], concat[13][56-53],
							concat[13][56-46], concat[13][56-42], concat[13][56-50], concat[13][56-36], concat[13][56-29], concat[13][56-32]};
						 
		permutes[3] = {concat[14][56-14], concat[14][56-17], concat[14][56-11], concat[14][56-24], concat[14][56-1],  concat[14][56-5],
							concat[14][56-3],  concat[14][56-28], concat[14][56-15], concat[14][56-6],  concat[14][56-21], concat[14][56-10],
							concat[14][56-23], concat[14][56-19], concat[14][56-12], concat[14][56-4],  concat[14][56-26], concat[14][56-8],
							concat[14][56-16], concat[14][56-7],  concat[14][56-27], concat[14][56-20], concat[14][56-13], concat[14][56-2],
							concat[14][56-41], concat[14][56-52], concat[14][56-31], concat[14][56-37], concat[14][56-47], concat[14][56-55],
							concat[14][56-30], concat[14][56-40], concat[14][56-51], concat[14][56-45], concat[14][56-33], concat[14][56-48],
							concat[14][56-44], concat[14][56-49], concat[14][56-39], concat[14][56-56], concat[14][56-34], concat[14][56-53],
							concat[14][56-46], concat[14][56-42], concat[14][56-50], concat[14][56-36], concat[14][56-29], concat[14][56-32]};
						 
		permutes[2] = {concat[15][56-14], concat[15][56-17], concat[15][56-11], concat[15][56-24], concat[15][56-1],  concat[15][56-5],
							concat[15][56-3],  concat[15][56-28], concat[15][56-15], concat[15][56-6],  concat[15][56-21], concat[15][56-10],
							concat[15][56-23], concat[15][56-19], concat[15][56-12], concat[15][56-4],  concat[15][56-26], concat[15][56-8],
							concat[15][56-16], concat[15][56-7],  concat[15][56-27], concat[15][56-20], concat[15][56-13], concat[15][56-2],
							concat[15][56-41], concat[15][56-52], concat[15][56-31], concat[15][56-37], concat[15][56-47], concat[15][56-55],
							concat[15][56-30], concat[15][56-40], concat[15][56-51], concat[15][56-45], concat[15][56-33], concat[15][56-48],
							concat[15][56-44], concat[15][56-49], concat[15][56-39], concat[15][56-56], concat[15][56-34], concat[15][56-53],
							concat[15][56-46], concat[15][56-42], concat[15][56-50], concat[15][56-36], concat[15][56-29], concat[15][56-32]};
						 
		permutes[1] = {concat[16][56-14], concat[16][56-17], concat[16][56-11], concat[16][56-24], concat[16][56-1],  concat[16][56-5],
							concat[16][56-3],  concat[16][56-28], concat[16][56-15], concat[16][56-6],  concat[16][56-21], concat[16][56-10],
							concat[16][56-23], concat[16][56-19], concat[16][56-12], concat[16][56-4],  concat[16][56-26], concat[16][56-8],
							concat[16][56-16], concat[16][56-7],  concat[16][56-27], concat[16][56-20], concat[16][56-13], concat[16][56-2],
							concat[16][56-41], concat[16][56-52], concat[16][56-31], concat[16][56-37], concat[16][56-47], concat[16][56-55],
							concat[16][56-30], concat[16][56-40], concat[16][56-51], concat[16][56-45], concat[16][56-33], concat[16][56-48],
							concat[16][56-44], concat[16][56-49], concat[16][56-39], concat[16][56-56], concat[16][56-34], concat[16][56-53],
							concat[16][56-46], concat[16][56-42], concat[16][56-50], concat[16][56-36], concat[16][56-29], concat[16][56-32]};
		
	end
						 
	// *********************************************************************************************************************************
	// Creating the S-boxes
	 
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
	s_box[2][1] = {4'd13, 4'd7, 4'd0, 4'd9, 4'd3, 4'd4, 4'd6, 4'd10, 4'd2, 4'd8, 4'd5, 4'd14, 4'd12, 4'd11, 4'd15, 4'd1};
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

	// *********************************************************************************************************************************
	// 64-bit permutation of value
	
	value_plus={value[64-58], value[64-50], value[64-42], value[64-34], value[64-26], value[64-18], value[64-10], value[64-2],
               value[64-60], value[64-52], value[64-44], value[64-36], value[64-28], value[64-20], value[64-12], value[64-4],
               value[64-62], value[64-54], value[64-46], value[64-38], value[64-30], value[64-22], value[64-14], value[64-6],
               value[64-64], value[64-56], value[64-48], value[64-40], value[64-32], value[64-24], value[64-16], value[64-8],
               value[64-57], value[64-49], value[64-41], value[64-33], value[64-25], value[64-17], value[64-9],  value[64-1],
               value[64-59], value[64-51], value[64-43], value[64-35], value[64-27], value[64-19], value[64-11], value[64-3],
               value[64-61], value[64-53], value[64-45], value[64-37], value[64-29], value[64-21], value[64-13], value[64-5],
               value[64-63], value[64-55], value[64-47], value[64-39], value[64-31], value[64-23], value[64-15], value[64-7]};

	// left and right half of value_plus
	L0 = value_plus[63:32];
   R0 = value_plus[31:0];
	
	// setting up for final function calculation:
   left_boxed[0] = L0;
   right_boxed[0] = R0;
	 
	// ************************************************************************************************************************************************************************
	// Calculating the function f and additional values needed
	 
	// Iteration 1:
	left_boxed[1] = right_boxed[0];
	 
	e_transform[1] = {right_boxed[0][32-32], right_boxed[0][32-1],  right_boxed[0][32-2],  right_boxed[0][32-3],  right_boxed[0][32-4],  right_boxed[0][32-5],
                     right_boxed[0][32-4],  right_boxed[0][32-5],  right_boxed[0][32-6],  right_boxed[0][32-7],  right_boxed[0][32-8],  right_boxed[0][32-9],
                     right_boxed[0][32-8],  right_boxed[0][32-9],  right_boxed[0][32-10], right_boxed[0][32-11], right_boxed[0][32-12], right_boxed[0][32-13],
                     right_boxed[0][32-12], right_boxed[0][32-13], right_boxed[0][32-14], right_boxed[0][32-15], right_boxed[0][32-16], right_boxed[0][32-17],
                     right_boxed[0][32-16], right_boxed[0][32-17], right_boxed[0][32-18], right_boxed[0][32-19], right_boxed[0][32-20], right_boxed[0][32-21],
                     right_boxed[0][32-20], right_boxed[0][32-21], right_boxed[0][32-22], right_boxed[0][32-23], right_boxed[0][32-24], right_boxed[0][32-25],
                     right_boxed[0][32-24], right_boxed[0][32-25], right_boxed[0][32-26], right_boxed[0][32-27], right_boxed[0][32-28], right_boxed[0][32-29],
                     right_boxed[0][32-28], right_boxed[0][32-29], right_boxed[0][32-30], right_boxed[0][32-31], right_boxed[0][32-32], right_boxed[0][32-1]};
	  
	keyXetran[1] = e_transform[1]^permutes[1];
	 
	// s-box-1
	row[0] = {keyXetran[1][47], keyXetran[1][42]};
	column[0] = keyXetran[1][46:43];
	sbox_outs[1][31:28] = s_box[0][row[0]][63 - column[0] * 4'd4 -: 4];
			
	// s-box-2
	row[1] = {keyXetran[1][41], keyXetran[1][36]};
	column[1] = keyXetran[1][40:37];
	sbox_outs[1][27:24] = s_box[1][row[1]][63 - column[1] * 4 -: 4];
			
	// s-box-3
	row[2] = {keyXetran[1][35], keyXetran[1][30]};
	column[2] = keyXetran[1][34:31];
	sbox_outs[1][23:20] = s_box[2][row[2]][63 - column[2] * 4 -: 4];
			
	// s-box-4
	row[3] = {keyXetran[1][29], keyXetran[1][24]};
	column[3] = keyXetran[1][28:25];
	sbox_outs[1][19:16] = s_box[3][row[3]][63 - column[3] * 4 -: 4];
			
	// s-box-5
	row[4] = {keyXetran[1][23], keyXetran[1][18]};
	column[4] = keyXetran[1][22:19];
	sbox_outs[1][15:12] = s_box[4][row[4]][63 - column[4] * 4 -: 4];
			
	// s-box-6
	row[5] = {keyXetran[1][17], keyXetran[1][12]};
	column[5] = keyXetran[1][16:13];
	sbox_outs[1][11:8] = s_box[5][row[5]][63 - column[5] * 4 -: 4];
			
	// s-box-7
	row[6] = {keyXetran[1][11], keyXetran[1][6]};
	column[6] = keyXetran[1][10:7];
	sbox_outs[1][7:4] = s_box[6][row[6]][63 - column[6] * 4 -: 4];
			
	// s-box-8
	row[7] = {keyXetran[1][5], keyXetran[1][0]};
	column[7] = keyXetran[1][4:1];
	sbox_outs[1][3:0] = s_box[7][row[7]][63 - column[7] * 4 -: 4];
	 
	f[1] = {sbox_outs[1][32-16], sbox_outs[1][32-7], sbox_outs[1][32-20], sbox_outs[1][32-21],
			  sbox_outs[1][32-29], sbox_outs[1][32-12], sbox_outs[1][32-28], sbox_outs[1][32-17],
			  sbox_outs[1][32-1], sbox_outs[1][32-15], sbox_outs[1][32-23], sbox_outs[1][32-26],
			  sbox_outs[1][32-5], sbox_outs[1][32-18], sbox_outs[1][32-31], sbox_outs[1][32-10],
			  sbox_outs[1][32-2], sbox_outs[1][32-8], sbox_outs[1][32-24], sbox_outs[1][32-14],
			  sbox_outs[1][32-32], sbox_outs[1][32-27], sbox_outs[1][32-3], sbox_outs[1][32-9],
			  sbox_outs[1][32-19], sbox_outs[1][32-13], sbox_outs[1][32-30], sbox_outs[1][32-6],
			  sbox_outs[1][32-22], sbox_outs[1][32-11], sbox_outs[1][32-4], sbox_outs[1][32-25]};
				
	right_boxed[1] = left_boxed[0]^f[1];
	 
	// ***********************************************
	// Iteration 2:
	
	left_boxed[2] = right_boxed[1];
	 
	e_transform[2] = {right_boxed[1][32-32], right_boxed[1][32-1],  right_boxed[1][32-2],  right_boxed[1][32-3],  right_boxed[1][32-4],  right_boxed[1][32-5],
                     right_boxed[1][32-4],  right_boxed[1][32-5],  right_boxed[1][32-6],  right_boxed[1][32-7],  right_boxed[1][32-8],  right_boxed[1][32-9],
                     right_boxed[1][32-8],  right_boxed[1][32-9],  right_boxed[1][32-10], right_boxed[1][32-11], right_boxed[1][32-12], right_boxed[1][32-13],
                     right_boxed[1][32-12], right_boxed[1][32-13], right_boxed[1][32-14], right_boxed[1][32-15], right_boxed[1][32-16], right_boxed[1][32-17],
                     right_boxed[1][32-16], right_boxed[1][32-17], right_boxed[1][32-18], right_boxed[1][32-19], right_boxed[1][32-20], right_boxed[1][32-21],
                     right_boxed[1][32-20], right_boxed[1][32-21], right_boxed[1][32-22], right_boxed[1][32-23], right_boxed[1][32-24], right_boxed[1][32-25],
                     right_boxed[1][32-24], right_boxed[1][32-25], right_boxed[1][32-26], right_boxed[1][32-27], right_boxed[1][32-28], right_boxed[1][32-29],
                     right_boxed[1][32-28], right_boxed[1][32-29], right_boxed[1][32-30], right_boxed[1][32-31], right_boxed[1][32-32], right_boxed[1][32-1]};
	  
	keyXetran[2] = e_transform[2]^permutes[2];
	 
	// s-box-1
	row[0] = {keyXetran[2][47], keyXetran[2][42]};
	column[0] = keyXetran[2][46:43];
	sbox_outs[2][31:28] = s_box[0][row[0]][63 - column[0] * 4'd4 -: 4];
		
	// s-box-2
	row[1] = {keyXetran[2][41], keyXetran[2][36]};
	column[1] = keyXetran[2][40:37];
	sbox_outs[2][27:24] = s_box[1][row[1]][63 - column[1] * 4 -: 4];
		
	// s-box-3
	row[2] = {keyXetran[2][35], keyXetran[2][30]};
	column[2] = keyXetran[2][34:31];
	sbox_outs[2][23:20] = s_box[2][row[2]][63 - column[2] * 4 -: 4];
		
	// s-box-4
	row[3] = {keyXetran[2][29], keyXetran[2][24]};
	column[3] = keyXetran[2][28:25];
	sbox_outs[2][19:16] = s_box[3][row[3]][63 - column[3] * 4 -: 4];
		
	// s-box-5
	row[4] = {keyXetran[2][23], keyXetran[2][18]};
	column[4] = keyXetran[2][22:19];
	sbox_outs[2][15:12] = s_box[4][row[4]][63 - column[4] * 4 -: 4];
		
	// s-box-6
	row[5] = {keyXetran[2][17], keyXetran[2][12]};
	column[5] = keyXetran[2][16:13];
	sbox_outs[2][11:8] = s_box[5][row[5]][63 - column[5] * 4 -: 4];
		
	// s-box-7
	row[6] = {keyXetran[2][11], keyXetran[2][6]};
	column[6] = keyXetran[2][10:7];
	sbox_outs[2][7:4] = s_box[6][row[6]][63 - column[6] * 4 -: 4];
		
	// s-box-8
	row[7] = {keyXetran[2][5], keyXetran[2][0]};
	column[7] = keyXetran[2][4:1];
	sbox_outs[2][3:0] = s_box[7][row[7]][63 - column[7] * 4 -: 4];
	
	f[2] = {sbox_outs[2][32-16], sbox_outs[2][32-7], sbox_outs[2][32-20], sbox_outs[2][32-21],
			  sbox_outs[2][32-29], sbox_outs[2][32-12], sbox_outs[2][32-28], sbox_outs[2][32-17],
			  sbox_outs[2][32-1], sbox_outs[2][32-15], sbox_outs[2][32-23], sbox_outs[2][32-26],
			  sbox_outs[2][32-5], sbox_outs[2][32-18], sbox_outs[2][32-31], sbox_outs[2][32-10],
			  sbox_outs[2][32-2], sbox_outs[2][32-8], sbox_outs[2][32-24], sbox_outs[2][32-14],
			  sbox_outs[2][32-32], sbox_outs[2][32-27], sbox_outs[2][32-3], sbox_outs[2][32-9],
			  sbox_outs[2][32-19], sbox_outs[2][32-13], sbox_outs[2][32-30], sbox_outs[2][32-6],
			  sbox_outs[2][32-22], sbox_outs[2][32-11], sbox_outs[2][32-4], sbox_outs[2][32-25]};
				
	right_boxed[2] = left_boxed[1]^f[2];
	 
	// ***********************************************
	// Iteration 3:
	 
	left_boxed[3] = right_boxed[2];
	 
	e_transform[3] = {right_boxed[2][32-32], right_boxed[2][32-1],  right_boxed[2][32-2],  right_boxed[2][32-3],  right_boxed[2][32-4],  right_boxed[2][32-5],
                     right_boxed[2][32-4],  right_boxed[2][32-5],  right_boxed[2][32-6],  right_boxed[2][32-7],  right_boxed[2][32-8],  right_boxed[2][32-9],
                     right_boxed[2][32-8],  right_boxed[2][32-9],  right_boxed[2][32-10], right_boxed[2][32-11], right_boxed[2][32-12], right_boxed[2][32-13],
                     right_boxed[2][32-12], right_boxed[2][32-13], right_boxed[2][32-14], right_boxed[2][32-15], right_boxed[2][32-16], right_boxed[2][32-17],
                     right_boxed[2][32-16], right_boxed[2][32-17], right_boxed[2][32-18], right_boxed[2][32-19], right_boxed[2][32-20], right_boxed[2][32-21],
                     right_boxed[2][32-20], right_boxed[2][32-21], right_boxed[2][32-22], right_boxed[2][32-23], right_boxed[2][32-24], right_boxed[2][32-25],
                     right_boxed[2][32-24], right_boxed[2][32-25], right_boxed[2][32-26], right_boxed[2][32-27], right_boxed[2][32-28], right_boxed[2][32-29],
                     right_boxed[2][32-28], right_boxed[2][32-29], right_boxed[2][32-30], right_boxed[2][32-31], right_boxed[2][32-32], right_boxed[2][32-1]};
	  
	keyXetran[3] = e_transform[3]^permutes[3];
	
	// s-box-1
	row[0] = {keyXetran[3][47], keyXetran[3][42]};
	column[0] = keyXetran[3][46:43];
	sbox_outs[3][31:28] = s_box[0][row[0]][63 - column[0] * 4'd4 -: 4];
		
	// s-box-2
	row[1] = {keyXetran[3][41], keyXetran[3][36]};
	column[1] = keyXetran[3][40:37];
	sbox_outs[3][27:24] = s_box[1][row[1]][63 - column[1] * 4 -: 4];
		
	// s-box-3
	row[2] = {keyXetran[3][35], keyXetran[3][30]};
	column[2] = keyXetran[3][34:31];
	sbox_outs[3][23:20] = s_box[2][row[2]][63 - column[2] * 4 -: 4];
		
	// s-box-4
	row[3] = {keyXetran[3][29], keyXetran[3][24]};
	column[3] = keyXetran[3][28:25];
	sbox_outs[3][19:16] = s_box[3][row[3]][63 - column[3] * 4 -: 4];
		
	// s-box-5
	row[4] = {keyXetran[3][23], keyXetran[3][18]};
	column[4] = keyXetran[3][22:19];
	sbox_outs[3][15:12] = s_box[4][row[4]][63 - column[4] * 4 -: 4];
		
	// s-box-6
	row[5] = {keyXetran[3][17], keyXetran[3][12]};
	column[5] = keyXetran[3][16:13];
	sbox_outs[3][11:8] = s_box[5][row[5]][63 - column[5] * 4 -: 4];
		
	// s-box-7
	row[6] = {keyXetran[3][11], keyXetran[3][6]};
	column[6] = keyXetran[3][10:7];
	sbox_outs[3][7:4] = s_box[6][row[6]][63 - column[6] * 4 -: 4];
		
	// s-box-8
	row[7] = {keyXetran[3][5], keyXetran[3][0]};
	column[7] = keyXetran[3][4:1];
	sbox_outs[3][3:0] = s_box[7][row[7]][63 - column[7] * 4 -: 4];
	 
	f[3] = {sbox_outs[3][32-16], sbox_outs[3][32-7], sbox_outs[3][32-20], sbox_outs[3][32-21],
			  sbox_outs[3][32-29], sbox_outs[3][32-12], sbox_outs[3][32-28], sbox_outs[3][32-17],
			  sbox_outs[3][32-1], sbox_outs[3][32-15], sbox_outs[3][32-23], sbox_outs[3][32-26],
			  sbox_outs[3][32-5], sbox_outs[3][32-18], sbox_outs[3][32-31], sbox_outs[3][32-10],
			  sbox_outs[3][32-2], sbox_outs[3][32-8], sbox_outs[3][32-24], sbox_outs[3][32-14],
			  sbox_outs[3][32-32], sbox_outs[3][32-27], sbox_outs[3][32-3], sbox_outs[3][32-9],
			  sbox_outs[3][32-19], sbox_outs[3][32-13], sbox_outs[3][32-30], sbox_outs[3][32-6],
			  sbox_outs[3][32-22], sbox_outs[3][32-11], sbox_outs[3][32-4], sbox_outs[3][32-25]};
				
	right_boxed[3] = left_boxed[2]^f[3];
	 
	// ***********************************************
	// Iteration 4:
	
	left_boxed[4] = right_boxed[3];
	 
	e_transform[4] = {right_boxed[3][32-32], right_boxed[3][32-1],  right_boxed[3][32-2],  right_boxed[3][32-3],  right_boxed[3][32-4],  right_boxed[3][32-5],
                     right_boxed[3][32-4],  right_boxed[3][32-5],  right_boxed[3][32-6],  right_boxed[3][32-7],  right_boxed[3][32-8],  right_boxed[3][32-9],
                     right_boxed[3][32-8],  right_boxed[3][32-9],  right_boxed[3][32-10], right_boxed[3][32-11], right_boxed[3][32-12], right_boxed[3][32-13],
                     right_boxed[3][32-12], right_boxed[3][32-13], right_boxed[3][32-14], right_boxed[3][32-15], right_boxed[3][32-16], right_boxed[3][32-17],
                     right_boxed[3][32-16], right_boxed[3][32-17], right_boxed[3][32-18], right_boxed[3][32-19], right_boxed[3][32-20], right_boxed[3][32-21],
                     right_boxed[3][32-20], right_boxed[3][32-21], right_boxed[3][32-22], right_boxed[3][32-23], right_boxed[3][32-24], right_boxed[3][32-25],
                     right_boxed[3][32-24], right_boxed[3][32-25], right_boxed[3][32-26], right_boxed[3][32-27], right_boxed[3][32-28], right_boxed[3][32-29],
                     right_boxed[3][32-28], right_boxed[3][32-29], right_boxed[3][32-30], right_boxed[3][32-31], right_boxed[3][32-32], right_boxed[3][32-1]};
	  
	keyXetran[4] = e_transform[4]^permutes[4];
	 
	// s-box-1
	row[0] = {keyXetran[4][47], keyXetran[4][42]};
	column[0] = keyXetran[4][46:43];
	sbox_outs[4][31:28] = s_box[0][row[0]][63 - column[0] * 4'd4 -: 4];
		
	// s-box-2
	row[1] = {keyXetran[4][41], keyXetran[4][36]};
	column[1] = keyXetran[4][40:37];
	sbox_outs[4][27:24] = s_box[1][row[1]][63 - column[1] * 4 -: 4];
		
	// s-box-3
	row[2] = {keyXetran[4][35], keyXetran[4][30]};
	column[2] = keyXetran[4][34:31];
	sbox_outs[4][23:20] = s_box[2][row[2]][63 - column[2] * 4 -: 4];
		
	// s-box-4
	row[3] = {keyXetran[4][29], keyXetran[4][24]};
	column[3] = keyXetran[4][28:25];
	sbox_outs[4][19:16] = s_box[3][row[3]][63 - column[3] * 4 -: 4];
		
	// s-box-5
	row[4] = {keyXetran[4][23], keyXetran[4][18]};
	column[4] = keyXetran[4][22:19];
	sbox_outs[4][15:12] = s_box[4][row[4]][63 - column[4] * 4 -: 4];
		
	// s-box-6
	row[5] = {keyXetran[4][17], keyXetran[4][12]};
	column[5] = keyXetran[4][16:13];
	sbox_outs[4][11:8] = s_box[5][row[5]][63 - column[5] * 4 -: 4];
		
	// s-box-7
	row[6] = {keyXetran[4][11], keyXetran[4][6]};
	column[6] = keyXetran[4][10:7];
	sbox_outs[4][7:4] = s_box[6][row[6]][63 - column[6] * 4 -: 4];
		
	// s-box-8
	row[7] = {keyXetran[4][5], keyXetran[4][0]};
	column[7] = keyXetran[4][4:1];
	sbox_outs[4][3:0] = s_box[7][row[7]][63 - column[7] * 4 -: 4];
	
	f[4] = {sbox_outs[4][32-16], sbox_outs[4][32-7], sbox_outs[4][32-20], sbox_outs[4][32-21],
			  sbox_outs[4][32-29], sbox_outs[4][32-12], sbox_outs[4][32-28], sbox_outs[4][32-17],
			  sbox_outs[4][32-1], sbox_outs[4][32-15], sbox_outs[4][32-23], sbox_outs[4][32-26],
			  sbox_outs[4][32-5], sbox_outs[4][32-18], sbox_outs[4][32-31], sbox_outs[4][32-10],
			  sbox_outs[4][32-2], sbox_outs[4][32-8], sbox_outs[4][32-24], sbox_outs[4][32-14],
			  sbox_outs[4][32-32], sbox_outs[4][32-27], sbox_outs[4][32-3], sbox_outs[4][32-9],
			  sbox_outs[4][32-19], sbox_outs[4][32-13], sbox_outs[4][32-30], sbox_outs[4][32-6],
			  sbox_outs[4][32-22], sbox_outs[4][32-11], sbox_outs[4][32-4], sbox_outs[4][32-25]};
				
	right_boxed[4] = left_boxed[3]^f[4];
	 
	// ***********************************************
	// Iteration 5:
	
	left_boxed[5] = right_boxed[4];
	 
	e_transform[5] = {right_boxed[4][32-32], right_boxed[4][32-1],  right_boxed[4][32-2],  right_boxed[4][32-3],  right_boxed[4][32-4],  right_boxed[4][32-5],
                     right_boxed[4][32-4],  right_boxed[4][32-5],  right_boxed[4][32-6],  right_boxed[4][32-7],  right_boxed[4][32-8],  right_boxed[4][32-9],
                     right_boxed[4][32-8],  right_boxed[4][32-9],  right_boxed[4][32-10], right_boxed[4][32-11], right_boxed[4][32-12], right_boxed[4][32-13],
                     right_boxed[4][32-12], right_boxed[4][32-13], right_boxed[4][32-14], right_boxed[4][32-15], right_boxed[4][32-16], right_boxed[4][32-17],
                     right_boxed[4][32-16], right_boxed[4][32-17], right_boxed[4][32-18], right_boxed[4][32-19], right_boxed[4][32-20], right_boxed[4][32-21],
                     right_boxed[4][32-20], right_boxed[4][32-21], right_boxed[4][32-22], right_boxed[4][32-23], right_boxed[4][32-24], right_boxed[4][32-25],
                     right_boxed[4][32-24], right_boxed[4][32-25], right_boxed[4][32-26], right_boxed[4][32-27], right_boxed[4][32-28], right_boxed[4][32-29],
                     right_boxed[4][32-28], right_boxed[4][32-29], right_boxed[4][32-30], right_boxed[4][32-31], right_boxed[4][32-32], right_boxed[4][32-1]};
	  
	keyXetran[5] = e_transform[5]^permutes[5];
	 
	// s-box-1
	row[0] = {keyXetran[5][47], keyXetran[5][42]};
	column[0] = keyXetran[5][46:43];
	sbox_outs[5][31:28] = s_box[0][row[0]][8'd63 - column[0] * 4'd4 -: 4];
		
	// s-box-2
	row[1] = {keyXetran[5][41], keyXetran[5][36]};
	column[1] = keyXetran[5][40:37];
	sbox_outs[5][27:24] = s_box[1][row[1]][63 - column[1] * 4 -: 4];
		
	// s-box-3
	row[2] = {keyXetran[5][35], keyXetran[5][30]};
	column[2] = keyXetran[5][34:31];
	sbox_outs[5][23:20] = s_box[2][row[2]][63 - column[2] * 4 -: 4];
		
	// s-box-4
	row[3] = {keyXetran[5][29], keyXetran[5][24]};
	column[3] = keyXetran[5][28:25];
	sbox_outs[5][19:16] = s_box[3][row[3]][63 - column[3] * 4 -: 4];
		
	// s-box-5
	row[4] = {keyXetran[5][23], keyXetran[5][18]};
	column[4] = keyXetran[5][22:19];
	sbox_outs[5][15:12] = s_box[4][row[4]][63 - column[4] * 4 -: 4];
		
	// s-box-6
	row[5] = {keyXetran[5][17], keyXetran[5][12]};
	column[5] = keyXetran[5][16:13];
	sbox_outs[5][11:8] = s_box[5][row[5]][63 - column[5] * 4 -: 4];
		
	// s-box-7
	row[6] = {keyXetran[5][11], keyXetran[5][6]};
	column[6] = keyXetran[5][10:7];
	sbox_outs[5][7:4] = s_box[6][row[6]][63 - column[6] * 4 -: 4];
		
	// s-box-8
	row[7] = {keyXetran[5][5], keyXetran[5][0]};
	column[7] = keyXetran[5][4:1];
	sbox_outs[5][3:0] = s_box[7][row[7]][63 - column[7] * 4 -: 4];
	 
	f[5] = {sbox_outs[5][32-16], sbox_outs[5][32-7], sbox_outs[5][32-20], sbox_outs[5][32-21],
			  sbox_outs[5][32-29], sbox_outs[5][32-12], sbox_outs[5][32-28], sbox_outs[5][32-17],
			  sbox_outs[5][32-1], sbox_outs[5][32-15], sbox_outs[5][32-23], sbox_outs[5][32-26],
			  sbox_outs[5][32-5], sbox_outs[5][32-18], sbox_outs[5][32-31], sbox_outs[5][32-10],
			  sbox_outs[5][32-2], sbox_outs[5][32-8], sbox_outs[5][32-24], sbox_outs[5][32-14],
			  sbox_outs[5][32-32], sbox_outs[5][32-27], sbox_outs[5][32-3], sbox_outs[5][32-9],
			  sbox_outs[5][32-19], sbox_outs[5][32-13], sbox_outs[5][32-30], sbox_outs[5][32-6],
			  sbox_outs[5][32-22], sbox_outs[5][32-11], sbox_outs[5][32-4], sbox_outs[5][32-25]};
				
	right_boxed[5] = left_boxed[4]^f[5];
	 
	// ***********************************************
	// Iteration 6:
	
	left_boxed[6] = right_boxed[5];
	 
	e_transform[6] = {right_boxed[5][32-32], right_boxed[5][32-1],  right_boxed[5][32-2],  right_boxed[5][32-3],  right_boxed[5][32-4],  right_boxed[5][32-5],
                     right_boxed[5][32-4],  right_boxed[5][32-5],  right_boxed[5][32-6],  right_boxed[5][32-7],  right_boxed[5][32-8],  right_boxed[5][32-9],
                     right_boxed[5][32-8],  right_boxed[5][32-9],  right_boxed[5][32-10], right_boxed[5][32-11], right_boxed[5][32-12], right_boxed[5][32-13],
                     right_boxed[5][32-12], right_boxed[5][32-13], right_boxed[5][32-14], right_boxed[5][32-15], right_boxed[5][32-16], right_boxed[5][32-17],
                     right_boxed[5][32-16], right_boxed[5][32-17], right_boxed[5][32-18], right_boxed[5][32-19], right_boxed[5][32-20], right_boxed[5][32-21],
                     right_boxed[5][32-20], right_boxed[5][32-21], right_boxed[5][32-22], right_boxed[5][32-23], right_boxed[5][32-24], right_boxed[5][32-25],
                     right_boxed[5][32-24], right_boxed[5][32-25], right_boxed[5][32-26], right_boxed[5][32-27], right_boxed[5][32-28], right_boxed[5][32-29],
                     right_boxed[5][32-28], right_boxed[5][32-29], right_boxed[5][32-30], right_boxed[5][32-31], right_boxed[5][32-32], right_boxed[5][32-1]};
	  
	keyXetran[6] = e_transform[6]^permutes[6];
	 
	// s-box-1
	row[0] = {keyXetran[6][47], keyXetran[6][42]};
	column[0] = keyXetran[6][46:43];
	sbox_outs[6][31:28] = s_box[0][row[0]][8'd63 - column[0] * 4'd4 -: 4];
	
	// s-box-2
	row[1] = {keyXetran[6][41], keyXetran[6][36]};
	column[1] = keyXetran[6][40:37];
	sbox_outs[6][27:24] = s_box[1][row[1]][63 - column[1] * 4 -: 4];
		
	// s-box-3
	row[2] = {keyXetran[6][35], keyXetran[6][30]};
	column[2] = keyXetran[6][34:31];
	sbox_outs[6][23:20] = s_box[2][row[2]][63 - column[2] * 4 -: 4];
		
	// s-box-4
	row[3] = {keyXetran[6][29], keyXetran[6][24]};
	column[3] = keyXetran[6][28:25];
	sbox_outs[6][19:16] = s_box[3][row[3]][63 - column[3] * 4 -: 4];
		
	// s-box-5
	row[4] = {keyXetran[6][23], keyXetran[6][18]};
	column[4] = keyXetran[6][22:19];
	sbox_outs[6][15:12] = s_box[4][row[4]][63 - column[4] * 4 -: 4];
		
	// s-box-6
	row[5] = {keyXetran[6][17], keyXetran[6][12]};
	column[5] = keyXetran[6][16:13];
	sbox_outs[6][11:8] = s_box[5][row[5]][63 - column[5] * 4 -: 4];
		
	// s-box-7
	row[6] = {keyXetran[6][11], keyXetran[6][6]};
	column[6] = keyXetran[6][10:7];
	sbox_outs[6][7:4] = s_box[6][row[6]][63 - column[6] * 4 -: 4];
		
	// s-box-8
	row[7] = {keyXetran[6][5], keyXetran[6][0]};
	column[7] = keyXetran[6][4:1];
	sbox_outs[6][3:0] = s_box[7][row[7]][63 - column[7] * 4 -: 4];
	 
	f[6] = {sbox_outs[6][32-16], sbox_outs[6][32-7], sbox_outs[6][32-20], sbox_outs[6][32-21],
			  sbox_outs[6][32-29], sbox_outs[6][32-12], sbox_outs[6][32-28], sbox_outs[6][32-17],
			  sbox_outs[6][32-1], sbox_outs[6][32-15], sbox_outs[6][32-23], sbox_outs[6][32-26],
			  sbox_outs[6][32-5], sbox_outs[6][32-18], sbox_outs[6][32-31], sbox_outs[6][32-10],
			  sbox_outs[6][32-2], sbox_outs[6][32-8], sbox_outs[6][32-24], sbox_outs[6][32-14],
			  sbox_outs[6][32-32], sbox_outs[6][32-27], sbox_outs[6][32-3], sbox_outs[6][32-9],
			  sbox_outs[6][32-19], sbox_outs[6][32-13], sbox_outs[6][32-30], sbox_outs[6][32-6],
			  sbox_outs[6][32-22], sbox_outs[6][32-11], sbox_outs[6][32-4], sbox_outs[6][32-25]};
				
	right_boxed[6] = left_boxed[5]^f[6];
	 
	// ***********************************************
	// Iteration 7:
	
	left_boxed[7] = right_boxed[6];
	 
	e_transform[7] = {right_boxed[6][32-32], right_boxed[6][32-1],  right_boxed[6][32-2],  right_boxed[6][32-3],  right_boxed[6][32-4],  right_boxed[6][32-5],
                     right_boxed[6][32-4],  right_boxed[6][32-5],  right_boxed[6][32-6],  right_boxed[6][32-7],  right_boxed[6][32-8],  right_boxed[6][32-9],
                     right_boxed[6][32-8],  right_boxed[6][32-9],  right_boxed[6][32-10], right_boxed[6][32-11], right_boxed[6][32-12], right_boxed[6][32-13],
                     right_boxed[6][32-12], right_boxed[6][32-13], right_boxed[6][32-14], right_boxed[6][32-15], right_boxed[6][32-16], right_boxed[6][32-17],
                     right_boxed[6][32-16], right_boxed[6][32-17], right_boxed[6][32-18], right_boxed[6][32-19], right_boxed[6][32-20], right_boxed[6][32-21],
                     right_boxed[6][32-20], right_boxed[6][32-21], right_boxed[6][32-22], right_boxed[6][32-23], right_boxed[6][32-24], right_boxed[6][32-25],
                     right_boxed[6][32-24], right_boxed[6][32-25], right_boxed[6][32-26], right_boxed[6][32-27], right_boxed[6][32-28], right_boxed[6][32-29],
                     right_boxed[6][32-28], right_boxed[6][32-29], right_boxed[6][32-30], right_boxed[6][32-31], right_boxed[6][32-32], right_boxed[6][32-1]};
	 
	keyXetran[7] = e_transform[7]^permutes[7];
	 
	// s-box-1
	row[0] = {keyXetran[7][47], keyXetran[7][42]};
	column[0] = keyXetran[7][46:43];
	sbox_outs[7][31:28] = s_box[0][row[0]][8'd63 - column[0] * 4'd4 -: 4];
		
	// s-box-2
	row[1] = {keyXetran[7][41], keyXetran[7][36]};
	column[1] = keyXetran[7][40:37];
	sbox_outs[7][27:24] = s_box[1][row[1]][63 - column[1] * 4 -: 4];
		
	// s-box-3
	row[2] = {keyXetran[7][35], keyXetran[7][30]};
	column[2] = keyXetran[7][34:31];
	sbox_outs[7][23:20] = s_box[2][row[2]][63 - column[2] * 4 -: 4];
		
	// s-box-4
	row[3] = {keyXetran[7][29], keyXetran[7][24]};
	column[3] = keyXetran[7][28:25];
	sbox_outs[7][19:16] = s_box[3][row[3]][63 - column[3] * 4 -: 4];
		
	// s-box-5
	row[4] = {keyXetran[7][23], keyXetran[7][18]};
	column[4] = keyXetran[7][22:19];
	sbox_outs[7][15:12] = s_box[4][row[4]][63 - column[4] * 4 -: 4];
		
	// s-box-6
	row[5] = {keyXetran[7][17], keyXetran[7][12]};
	column[5] = keyXetran[7][16:13];
	sbox_outs[7][11:8] = s_box[5][row[5]][63 - column[5] * 4 -: 4];
		
	// s-box-7
	row[6] = {keyXetran[7][11], keyXetran[7][6]};
	column[6] = keyXetran[7][10:7];
	sbox_outs[7][7:4] = s_box[6][row[6]][63 - column[6] * 4 -: 4];
		
	// s-box-8
	row[7] = {keyXetran[7][5], keyXetran[7][0]};
	column[7] = keyXetran[7][4:1];
	sbox_outs[7][3:0] = s_box[7][row[7]][63 - column[7] * 4 -: 4];
	 
	f[7] = {sbox_outs[7][32-16], sbox_outs[7][32-7], sbox_outs[7][32-20], sbox_outs[7][32-21],
			  sbox_outs[7][32-29], sbox_outs[7][32-12], sbox_outs[7][32-28], sbox_outs[7][32-17],
			  sbox_outs[7][32-1], sbox_outs[7][32-15], sbox_outs[7][32-23], sbox_outs[7][32-26],
			  sbox_outs[7][32-5], sbox_outs[7][32-18], sbox_outs[7][32-31], sbox_outs[7][32-10],
			  sbox_outs[7][32-2], sbox_outs[7][32-8], sbox_outs[7][32-24], sbox_outs[7][32-14],
			  sbox_outs[7][32-32], sbox_outs[7][32-27], sbox_outs[7][32-3], sbox_outs[7][32-9],
			  sbox_outs[7][32-19], sbox_outs[7][32-13], sbox_outs[7][32-30], sbox_outs[7][32-6],
			  sbox_outs[7][32-22], sbox_outs[7][32-11], sbox_outs[7][32-4], sbox_outs[7][32-25]};
				
	right_boxed[7] = left_boxed[6]^f[7];
	 
	// ***********************************************
	// Iteration 8:
	
	left_boxed[8] = right_boxed[7];
	 
	e_transform[8] = {right_boxed[7][32-32], right_boxed[7][32-1],  right_boxed[7][32-2],  right_boxed[7][32-3],  right_boxed[7][32-4],  right_boxed[7][32-5],
                     right_boxed[7][32-4],  right_boxed[7][32-5],  right_boxed[7][32-6],  right_boxed[7][32-7],  right_boxed[7][32-8],  right_boxed[7][32-9],
                     right_boxed[7][32-8],  right_boxed[7][32-9],  right_boxed[7][32-10], right_boxed[7][32-11], right_boxed[7][32-12], right_boxed[7][32-13],
                     right_boxed[7][32-12], right_boxed[7][32-13], right_boxed[7][32-14], right_boxed[7][32-15], right_boxed[7][32-16], right_boxed[7][32-17],
                     right_boxed[7][32-16], right_boxed[7][32-17], right_boxed[7][32-18], right_boxed[7][32-19], right_boxed[7][32-20], right_boxed[7][32-21],
                     right_boxed[7][32-20], right_boxed[7][32-21], right_boxed[7][32-22], right_boxed[7][32-23], right_boxed[7][32-24], right_boxed[7][32-25],
                     right_boxed[7][32-24], right_boxed[7][32-25], right_boxed[7][32-26], right_boxed[7][32-27], right_boxed[7][32-28], right_boxed[7][32-29],
                     right_boxed[7][32-28], right_boxed[7][32-29], right_boxed[7][32-30], right_boxed[7][32-31], right_boxed[7][32-32], right_boxed[7][32-1]};
	  
	keyXetran[8] = e_transform[8]^permutes[8];
	 
	// s-box-1
	row[0] = {keyXetran[8][47], keyXetran[8][42]};
	column[0] = keyXetran[8][46:43];
	sbox_outs[8][31:28] = s_box[0][row[0]][8'd63 - column[0] * 4'd4 -: 4];
		
	// s-box-2
	row[1] = {keyXetran[8][41], keyXetran[8][36]};
	column[1] = keyXetran[8][40:37];
	sbox_outs[8][27:24] = s_box[1][row[1]][63 - column[1] * 4 -: 4];
		
	// s-box-3
	row[2] = {keyXetran[8][35], keyXetran[8][30]};
	column[2] = keyXetran[8][34:31];
	sbox_outs[8][23:20] = s_box[2][row[2]][63 - column[2] * 4 -: 4];
		
	// s-box-4
	row[3] = {keyXetran[8][29], keyXetran[8][24]};
	column[3] = keyXetran[8][28:25];
	sbox_outs[8][19:16] = s_box[3][row[3]][63 - column[3] * 4 -: 4];
		
	// s-box-5
	row[4] = {keyXetran[8][23], keyXetran[8][18]};
	column[4] = keyXetran[8][22:19];
	sbox_outs[8][15:12] = s_box[4][row[4]][63 - column[4] * 4 -: 4];
		
	// s-box-6
	row[5] = {keyXetran[8][17], keyXetran[8][12]};
	column[5] = keyXetran[8][16:13];
	sbox_outs[8][11:8] = s_box[5][row[5]][63 - column[5] * 4 -: 4];
		
	// s-box-7
	row[6] = {keyXetran[8][11], keyXetran[8][6]};
	column[6] = keyXetran[8][10:7];
	sbox_outs[8][7:4] = s_box[6][row[6]][63 - column[6] * 4 -: 4];
		
	// s-box-8
	row[7] = {keyXetran[8][5], keyXetran[8][0]};
	column[7] = keyXetran[8][4:1];
	sbox_outs[8][3:0] = s_box[7][row[7]][63 - column[7] * 4 -: 4];
	 
	f[8] = {sbox_outs[8][32-16], sbox_outs[8][32-7], sbox_outs[8][32-20], sbox_outs[8][32-21],
			  sbox_outs[8][32-29], sbox_outs[8][32-12], sbox_outs[8][32-28], sbox_outs[8][32-17],
			  sbox_outs[8][32-1], sbox_outs[8][32-15], sbox_outs[8][32-23], sbox_outs[8][32-26],
			  sbox_outs[8][32-5], sbox_outs[8][32-18], sbox_outs[8][32-31], sbox_outs[8][32-10],
			  sbox_outs[8][32-2], sbox_outs[8][32-8], sbox_outs[8][32-24], sbox_outs[8][32-14],
			  sbox_outs[8][32-32], sbox_outs[8][32-27], sbox_outs[8][32-3], sbox_outs[8][32-9],
			  sbox_outs[8][32-19], sbox_outs[8][32-13], sbox_outs[8][32-30], sbox_outs[8][32-6],
			  sbox_outs[8][32-22], sbox_outs[8][32-11], sbox_outs[8][32-4], sbox_outs[8][32-25]};
				
	right_boxed[8] = left_boxed[7]^f[8];
	 
	// ***********************************************
	// Iteration 9:
	
	left_boxed[9] = right_boxed[8];
	 
	e_transform[9] = {right_boxed[8][32-32], right_boxed[8][32-1],  right_boxed[8][32-2],  right_boxed[8][32-3],  right_boxed[8][32-4],  right_boxed[8][32-5],
                     right_boxed[8][32-4],  right_boxed[8][32-5],  right_boxed[8][32-6],  right_boxed[8][32-7],  right_boxed[8][32-8],  right_boxed[8][32-9],
                     right_boxed[8][32-8],  right_boxed[8][32-9],  right_boxed[8][32-10], right_boxed[8][32-11], right_boxed[8][32-12], right_boxed[8][32-13],
                     right_boxed[8][32-12], right_boxed[8][32-13], right_boxed[8][32-14], right_boxed[8][32-15], right_boxed[8][32-16], right_boxed[8][32-17],
                     right_boxed[8][32-16], right_boxed[8][32-17], right_boxed[8][32-18], right_boxed[8][32-19], right_boxed[8][32-20], right_boxed[8][32-21],
                     right_boxed[8][32-20], right_boxed[8][32-21], right_boxed[8][32-22], right_boxed[8][32-23], right_boxed[8][32-24], right_boxed[8][32-25],
                     right_boxed[8][32-24], right_boxed[8][32-25], right_boxed[8][32-26], right_boxed[8][32-27], right_boxed[8][32-28], right_boxed[8][32-29],
                     right_boxed[8][32-28], right_boxed[8][32-29], right_boxed[8][32-30], right_boxed[8][32-31], right_boxed[8][32-32], right_boxed[8][32-1]};
	  
	keyXetran[9] = e_transform[9]^permutes[9];
	 
	// s-box-1
	row[0] = {keyXetran[9][47], keyXetran[9][42]};
	column[0] = keyXetran[9][46:43];
	sbox_outs[9][31:28] = s_box[0][row[0]][8'd63 - column[0] * 4'd4 -: 4];
		
	// s-box-2
	row[1] = {keyXetran[9][41], keyXetran[9][36]};
	column[1] = keyXetran[9][40:37];
	sbox_outs[9][27:24] = s_box[1][row[1]][63 - column[1] * 4 -: 4];
		
	// s-box-3
	row[2] = {keyXetran[9][35], keyXetran[9][30]};
	column[2] = keyXetran[9][34:31];
	sbox_outs[9][23:20] = s_box[2][row[2]][63 - column[2] * 4 -: 4];
		
	// s-box-4
	row[3] = {keyXetran[9][29], keyXetran[9][24]};
	column[3] = keyXetran[9][28:25];
	sbox_outs[9][19:16] = s_box[3][row[3]][63 - column[3] * 4 -: 4];
		
	// s-box-5
	row[4] = {keyXetran[9][23], keyXetran[9][18]};
	column[4] = keyXetran[9][22:19];
	sbox_outs[9][15:12] = s_box[4][row[4]][63 - column[4] * 4 -: 4];
		
	// s-box-6
	row[5] = {keyXetran[9][17], keyXetran[9][12]};
	column[5] = keyXetran[9][16:13];
	sbox_outs[9][11:8] = s_box[5][row[5]][63 - column[5] * 4 -: 4];
		
	// s-box-7
	row[6] = {keyXetran[9][11], keyXetran[9][6]};
	column[6] = keyXetran[9][10:7];
	sbox_outs[9][7:4] = s_box[6][row[6]][63 - column[6] * 4 -: 4];
		
	// s-box-8
	row[7] = {keyXetran[9][5], keyXetran[9][0]};
	column[7] = keyXetran[9][4:1];
	sbox_outs[9][3:0] = s_box[7][row[7]][63 - column[7] * 4 -: 4];
	
	f[9] = {sbox_outs[9][32-16], sbox_outs[9][32-7], sbox_outs[9][32-20], sbox_outs[9][32-21],
			  sbox_outs[9][32-29], sbox_outs[9][32-12], sbox_outs[9][32-28], sbox_outs[9][32-17],
			  sbox_outs[9][32-1], sbox_outs[9][32-15], sbox_outs[9][32-23], sbox_outs[9][32-26],
			  sbox_outs[9][32-5], sbox_outs[9][32-18], sbox_outs[9][32-31], sbox_outs[9][32-10],
			  sbox_outs[9][32-2], sbox_outs[9][32-8], sbox_outs[9][32-24], sbox_outs[9][32-14],
			  sbox_outs[9][32-32], sbox_outs[9][32-27], sbox_outs[9][32-3], sbox_outs[9][32-9],
			  sbox_outs[9][32-19], sbox_outs[9][32-13], sbox_outs[9][32-30], sbox_outs[9][32-6],
			  sbox_outs[9][32-22], sbox_outs[9][32-11], sbox_outs[9][32-4], sbox_outs[9][32-25]};
				
	right_boxed[9] = left_boxed[8]^f[9];
	 
	// ***********************************************
	// Iteration 10:
	
	left_boxed[10] = right_boxed[9];
	 
	e_transform[10] = {right_boxed[9][32-32], right_boxed[9][32-1],  right_boxed[9][32-2],  right_boxed[9][32-3],  right_boxed[9][32-4],  right_boxed[9][32-5],
                      right_boxed[9][32-4],  right_boxed[9][32-5],  right_boxed[9][32-6],  right_boxed[9][32-7],  right_boxed[9][32-8],  right_boxed[9][32-9],
                      right_boxed[9][32-8],  right_boxed[9][32-9],  right_boxed[9][32-10], right_boxed[9][32-11], right_boxed[9][32-12], right_boxed[9][32-13],
                      right_boxed[9][32-12], right_boxed[9][32-13], right_boxed[9][32-14], right_boxed[9][32-15], right_boxed[9][32-16], right_boxed[9][32-17],
                      right_boxed[9][32-16], right_boxed[9][32-17], right_boxed[9][32-18], right_boxed[9][32-19], right_boxed[9][32-20], right_boxed[9][32-21],
                      right_boxed[9][32-20], right_boxed[9][32-21], right_boxed[9][32-22], right_boxed[9][32-23], right_boxed[9][32-24], right_boxed[9][32-25],
                      right_boxed[9][32-24], right_boxed[9][32-25], right_boxed[9][32-26], right_boxed[9][32-27], right_boxed[9][32-28], right_boxed[9][32-29],
                      right_boxed[9][32-28], right_boxed[9][32-29], right_boxed[9][32-30], right_boxed[9][32-31], right_boxed[9][32-32], right_boxed[9][32-1]};
	  
	keyXetran[10] = e_transform[10]^permutes[10];
	 
	// s-box-1
	row[0] = {keyXetran[10][47], keyXetran[10][42]};
	column[0] = keyXetran[10][46:43];
	sbox_outs[10][31:28] = s_box[0][row[0]][8'd63 - column[0] * 4'd4 -: 4];
		
	// s-box-2
	row[1] = {keyXetran[10][41], keyXetran[10][36]};
	column[1] = keyXetran[10][40:37];
	sbox_outs[10][27:24] = s_box[1][row[1]][63 - column[1] * 4 -: 4];
		
	// s-box-3
	row[2] = {keyXetran[10][35], keyXetran[10][30]};
	column[2] = keyXetran[10][34:31];
	sbox_outs[10][23:20] = s_box[2][row[2]][63 - column[2] * 4 -: 4];
		
	// s-box-4
	row[3] = {keyXetran[10][29], keyXetran[10][24]};
	column[3] = keyXetran[10][28:25];
	sbox_outs[10][19:16] = s_box[3][row[3]][63 - column[3] * 4 -: 4];
		
	// s-box-5
	row[4] = {keyXetran[10][23], keyXetran[10][18]};
	column[4] = keyXetran[10][22:19];
	sbox_outs[10][15:12] = s_box[4][row[4]][63 - column[4] * 4 -: 4];
		
	// s-box-6
	row[5] = {keyXetran[10][17], keyXetran[10][12]};
	column[5] = keyXetran[10][16:13];
	sbox_outs[10][11:8] = s_box[5][row[5]][63 - column[5] * 4 -: 4];
		
	// s-box-7
	row[6] = {keyXetran[10][11], keyXetran[10][6]};
	column[6] = keyXetran[10][10:7];
	sbox_outs[10][7:4] = s_box[6][row[6]][63 - column[6] * 4 -: 4];
		
	// s-box-8
	row[7] = {keyXetran[10][5], keyXetran[10][0]};
	column[7] = keyXetran[10][4:1];
	sbox_outs[10][3:0] = s_box[7][row[7]][63 - column[7] * 4 -: 4];
	 
	f[10] = {sbox_outs[10][32-16], sbox_outs[10][32-7], sbox_outs[10][32-20], sbox_outs[10][32-21],
			   sbox_outs[10][32-29], sbox_outs[10][32-12], sbox_outs[10][32-28], sbox_outs[10][32-17],
				sbox_outs[10][32-1], sbox_outs[10][32-15], sbox_outs[10][32-23], sbox_outs[10][32-26],
				sbox_outs[10][32-5], sbox_outs[10][32-18], sbox_outs[10][32-31], sbox_outs[10][32-10],
				sbox_outs[10][32-2], sbox_outs[10][32-8], sbox_outs[10][32-24], sbox_outs[10][32-14],
				sbox_outs[10][32-32], sbox_outs[10][32-27], sbox_outs[10][32-3], sbox_outs[10][32-9],
				sbox_outs[10][32-19], sbox_outs[10][32-13], sbox_outs[10][32-30], sbox_outs[10][32-6],
				sbox_outs[10][32-22], sbox_outs[10][32-11], sbox_outs[10][32-4], sbox_outs[10][32-25]};
				
	right_boxed[10] = left_boxed[9]^f[10];
	 
	// ***********************************************
	// Iteration 11:
	
	left_boxed[11] = right_boxed[10];
	 
	e_transform[11] = {right_boxed[10][32-32], right_boxed[10][32-1],  right_boxed[10][32-2],  right_boxed[10][32-3],  right_boxed[10][32-4],  right_boxed[10][32-5],
                      right_boxed[10][32-4],  right_boxed[10][32-5],  right_boxed[10][32-6],  right_boxed[10][32-7],  right_boxed[10][32-8],  right_boxed[10][32-9],
                      right_boxed[10][32-8],  right_boxed[10][32-9],  right_boxed[10][32-10], right_boxed[10][32-11], right_boxed[10][32-12], right_boxed[10][32-13],
                      right_boxed[10][32-12], right_boxed[10][32-13], right_boxed[10][32-14], right_boxed[10][32-15], right_boxed[10][32-16], right_boxed[10][32-17],
                      right_boxed[10][32-16], right_boxed[10][32-17], right_boxed[10][32-18], right_boxed[10][32-19], right_boxed[10][32-20], right_boxed[10][32-21],
                      right_boxed[10][32-20], right_boxed[10][32-21], right_boxed[10][32-22], right_boxed[10][32-23], right_boxed[10][32-24], right_boxed[10][32-25],
                      right_boxed[10][32-24], right_boxed[10][32-25], right_boxed[10][32-26], right_boxed[10][32-27], right_boxed[10][32-28], right_boxed[10][32-29],
                      right_boxed[10][32-28], right_boxed[10][32-29], right_boxed[10][32-30], right_boxed[10][32-31], right_boxed[10][32-32], right_boxed[10][32-1]};
	  
	keyXetran[11] = e_transform[11]^permutes[11];
	 
	// s-box-1
	row[0] = {keyXetran[11][47], keyXetran[11][42]};
	column[0] = keyXetran[11][46:43];
	sbox_outs[11][31:28] = s_box[0][row[0]][8'd63 - column[0] * 4'd4 -: 4];
		
	// s-box-2
	row[1] = {keyXetran[11][41], keyXetran[11][36]};
	column[1] = keyXetran[11][40:37];
	sbox_outs[11][27:24] = s_box[1][row[1]][63 - column[1] * 4 -: 4];
		
	// s-box-3
	row[2] = {keyXetran[11][35], keyXetran[11][30]};
	column[2] = keyXetran[11][34:31];
	sbox_outs[11][23:20] = s_box[2][row[2]][63 - column[2] * 4 -: 4];
		
	// s-box-4
	row[3] = {keyXetran[11][29], keyXetran[11][24]};
	column[3] = keyXetran[11][28:25];
	sbox_outs[11][19:16] = s_box[3][row[3]][63 - column[3] * 4 -: 4];
		
	// s-box-5
	row[4] = {keyXetran[11][23], keyXetran[11][18]};
	column[4] = keyXetran[11][22:19];
	sbox_outs[11][15:12] = s_box[4][row[4]][63 - column[4] * 4 -: 4];
		
	// s-box-6
	row[5] = {keyXetran[11][17], keyXetran[11][12]};
	column[5] = keyXetran[11][16:13];
	sbox_outs[11][11:8] = s_box[5][row[5]][63 - column[5] * 4 -: 4];
		
	// s-box-7
	row[6] = {keyXetran[11][11], keyXetran[11][6]};
	column[6] = keyXetran[11][10:7];
	sbox_outs[11][7:4] = s_box[6][row[6]][63 - column[6] * 4 -: 4];
		
	// s-box-8
	row[7] = {keyXetran[11][5], keyXetran[11][0]};
	column[7] = keyXetran[11][4:1];
	sbox_outs[11][3:0] = s_box[7][row[7]][63 - column[7] * 4 -: 4];
	
	f[11] = {sbox_outs[11][32-16], sbox_outs[11][32-7], sbox_outs[11][32-20], sbox_outs[11][32-21],
			   sbox_outs[11][32-29], sbox_outs[11][32-12], sbox_outs[11][32-28], sbox_outs[11][32-17],
			   sbox_outs[11][32-1], sbox_outs[11][32-15], sbox_outs[11][32-23], sbox_outs[11][32-26],
				sbox_outs[11][32-5], sbox_outs[11][32-18], sbox_outs[11][32-31], sbox_outs[11][32-10],
				sbox_outs[11][32-2], sbox_outs[11][32-8], sbox_outs[11][32-24], sbox_outs[11][32-14],
				sbox_outs[11][32-32], sbox_outs[11][32-27], sbox_outs[11][32-3], sbox_outs[11][32-9],
				sbox_outs[11][32-19], sbox_outs[11][32-13], sbox_outs[11][32-30], sbox_outs[11][32-6],
				sbox_outs[11][32-22], sbox_outs[11][32-11], sbox_outs[11][32-4], sbox_outs[11][32-25]};
				
	right_boxed[11] = left_boxed[10]^f[11];
	 
	// ***********************************************
	// Iteration 12:
	
	left_boxed[12] = right_boxed[11];
	 
	e_transform[12] = {right_boxed[11][32-32], right_boxed[11][32-1],  right_boxed[11][32-2],  right_boxed[11][32-3],  right_boxed[11][32-4],  right_boxed[11][32-5],
                      right_boxed[11][32-4],  right_boxed[11][32-5],  right_boxed[11][32-6],  right_boxed[11][32-7],  right_boxed[11][32-8],  right_boxed[11][32-9],
                      right_boxed[11][32-8],  right_boxed[11][32-9],  right_boxed[11][32-10], right_boxed[11][32-11], right_boxed[11][32-12], right_boxed[11][32-13],
                      right_boxed[11][32-12], right_boxed[11][32-13], right_boxed[11][32-14], right_boxed[11][32-15], right_boxed[11][32-16], right_boxed[11][32-17],
                      right_boxed[11][32-16], right_boxed[11][32-17], right_boxed[11][32-18], right_boxed[11][32-19], right_boxed[11][32-20], right_boxed[11][32-21],
                      right_boxed[11][32-20], right_boxed[11][32-21], right_boxed[11][32-22], right_boxed[11][32-23], right_boxed[11][32-24], right_boxed[11][32-25],
                      right_boxed[11][32-24], right_boxed[11][32-25], right_boxed[11][32-26], right_boxed[11][32-27], right_boxed[11][32-28], right_boxed[11][32-29],
                      right_boxed[11][32-28], right_boxed[11][32-29], right_boxed[11][32-30], right_boxed[11][32-31], right_boxed[11][32-32], right_boxed[11][32-1]};
	  
	keyXetran[12] = e_transform[12]^permutes[12];
	
	// s-box-1
	row[0] = {keyXetran[12][47], keyXetran[12][42]};
	column[0] = keyXetran[12][46:43];
	sbox_outs[12][31:28] = s_box[0][row[0]][8'd63 - column[0] * 4'd4 -: 4];
		
	// s-box-2
	row[1] = {keyXetran[12][41], keyXetran[12][36]};
	column[1] = keyXetran[12][40:37];
	sbox_outs[12][27:24] = s_box[1][row[1]][63 - column[1] * 4 -: 4];
		
	// s-box-3
	row[2] = {keyXetran[12][35], keyXetran[12][30]};
	column[2] = keyXetran[12][34:31];
	sbox_outs[12][23:20] = s_box[2][row[2]][63 - column[2] * 4 -: 4];
		
	// s-box-4
	row[3] = {keyXetran[12][29], keyXetran[12][24]};
	column[3] = keyXetran[12][28:25];
	sbox_outs[12][19:16] = s_box[3][row[3]][63 - column[3] * 4 -: 4];
		
	// s-box-5
	row[4] = {keyXetran[12][23], keyXetran[12][18]};
	column[4] = keyXetran[12][22:19];
	sbox_outs[12][15:12] = s_box[4][row[4]][63 - column[4] * 4 -: 4];
		
	// s-box-6
	row[5] = {keyXetran[12][17], keyXetran[12][12]};
	column[5] = keyXetran[12][16:13];
	sbox_outs[12][11:8] = s_box[5][row[5]][63 - column[5] * 4 -: 4];
		
	// s-box-7
	row[6] = {keyXetran[12][11], keyXetran[12][6]};
	column[6] = keyXetran[12][10:7];
	sbox_outs[12][7:4] = s_box[6][row[6]][63 - column[6] * 4 -: 4];
		
	// s-box-8
	row[7] = {keyXetran[12][5], keyXetran[12][0]};
	column[7] = keyXetran[12][4:1];
	sbox_outs[12][3:0] = s_box[7][row[7]][63 - column[7] * 4 -: 4];
	 
	f[12] = {sbox_outs[12][32-16], sbox_outs[12][32-7], sbox_outs[12][32-20], sbox_outs[12][32-21],
				sbox_outs[12][32-29], sbox_outs[12][32-12], sbox_outs[12][32-28], sbox_outs[12][32-17],
				sbox_outs[12][32-1], sbox_outs[12][32-15], sbox_outs[12][32-23], sbox_outs[12][32-26],
				sbox_outs[12][32-5], sbox_outs[12][32-18], sbox_outs[12][32-31], sbox_outs[12][32-10],
				sbox_outs[12][32-2], sbox_outs[12][32-8], sbox_outs[12][32-24], sbox_outs[12][32-14],
				sbox_outs[12][32-32], sbox_outs[12][32-27], sbox_outs[12][32-3], sbox_outs[12][32-9],
				sbox_outs[12][32-19], sbox_outs[12][32-13], sbox_outs[12][32-30], sbox_outs[12][32-6],
				sbox_outs[12][32-22], sbox_outs[12][32-11], sbox_outs[12][32-4], sbox_outs[12][32-25]};
				
	right_boxed[12] = left_boxed[11]^f[12];
	 
	// ***********************************************
	// Iteration 13:
	
	left_boxed[13] = right_boxed[12];
	 
	e_transform[13] = {right_boxed[12][32-32], right_boxed[12][32-1],  right_boxed[12][32-2],  right_boxed[12][32-3],  right_boxed[12][32-4],  right_boxed[12][32-5],
                      right_boxed[12][32-4],  right_boxed[12][32-5],  right_boxed[12][32-6],  right_boxed[12][32-7],  right_boxed[12][32-8],  right_boxed[12][32-9],
                      right_boxed[12][32-8],  right_boxed[12][32-9],  right_boxed[12][32-10], right_boxed[12][32-11], right_boxed[12][32-12], right_boxed[12][32-13],
                      right_boxed[12][32-12], right_boxed[12][32-13], right_boxed[12][32-14], right_boxed[12][32-15], right_boxed[12][32-16], right_boxed[12][32-17],
                      right_boxed[12][32-16], right_boxed[12][32-17], right_boxed[12][32-18], right_boxed[12][32-19], right_boxed[12][32-20], right_boxed[12][32-21],
                      right_boxed[12][32-20], right_boxed[12][32-21], right_boxed[12][32-22], right_boxed[12][32-23], right_boxed[12][32-24], right_boxed[12][32-25],
                      right_boxed[12][32-24], right_boxed[12][32-25], right_boxed[12][32-26], right_boxed[12][32-27], right_boxed[12][32-28], right_boxed[12][32-29],
                      right_boxed[12][32-28], right_boxed[12][32-29], right_boxed[12][32-30], right_boxed[12][32-31], right_boxed[12][32-32], right_boxed[12][32-1]};
	  
	keyXetran[13] = e_transform[13]^permutes[13];
	 
	// s-box-1
	row[0] = {keyXetran[13][47], keyXetran[13][42]};
	column[0] = keyXetran[13][46:43];
	sbox_outs[13][31:28] = s_box[0][row[0]][8'd63 - column[0] * 4'd4 -: 4];
		
	// s-box-2
	row[1] = {keyXetran[13][41], keyXetran[13][36]};
	column[1] = keyXetran[13][40:37];
	sbox_outs[13][27:24] = s_box[1][row[1]][63 - column[1] * 4 -: 4];
		
	// s-box-3
	row[2] = {keyXetran[13][35], keyXetran[13][30]};
	column[2] = keyXetran[13][34:31];
	sbox_outs[13][23:20] = s_box[2][row[2]][63 - column[2] * 4 -: 4];
		
	// s-box-4
	row[3] = {keyXetran[13][29], keyXetran[13][24]};
	column[3] = keyXetran[13][28:25];
	sbox_outs[13][19:16] = s_box[3][row[3]][63 - column[3] * 4 -: 4];
		
	// s-box-5
	row[4] = {keyXetran[13][23], keyXetran[13][18]};
	column[4] = keyXetran[13][22:19];
	sbox_outs[13][15:12] = s_box[4][row[4]][63 - column[4] * 4 -: 4];
		
	// s-box-6
	row[5] = {keyXetran[13][17], keyXetran[13][12]};
	column[5] = keyXetran[13][16:13];
	sbox_outs[13][11:8] = s_box[5][row[5]][63 - column[5] * 4 -: 4];
		
	// s-box-7
	row[6] = {keyXetran[13][11], keyXetran[13][6]};
	column[6] = keyXetran[13][10:7];
	sbox_outs[13][7:4] = s_box[6][row[6]][63 - column[6] * 4 -: 4];
		
	// s-box-8
	row[7] = {keyXetran[13][5], keyXetran[13][0]};
	column[7] = keyXetran[13][4:1];
	sbox_outs[13][3:0] = s_box[7][row[7]][63 - column[7] * 4 -: 4];
	 
	f[13] = {sbox_outs[13][32-16], sbox_outs[13][32-7], sbox_outs[13][32-20], sbox_outs[13][32-21],
				sbox_outs[13][32-29], sbox_outs[13][32-12], sbox_outs[13][32-28], sbox_outs[13][32-17],
				sbox_outs[13][32-1], sbox_outs[13][32-15], sbox_outs[13][32-23], sbox_outs[13][32-26],
				sbox_outs[13][32-5], sbox_outs[13][32-18], sbox_outs[13][32-31], sbox_outs[13][32-10],
				sbox_outs[13][32-2], sbox_outs[13][32-8], sbox_outs[13][32-24], sbox_outs[13][32-14],
				sbox_outs[13][32-32], sbox_outs[13][32-27], sbox_outs[13][32-3], sbox_outs[13][32-9],
				sbox_outs[13][32-19], sbox_outs[13][32-13], sbox_outs[13][32-30], sbox_outs[13][32-6],
				sbox_outs[13][32-22], sbox_outs[13][32-11], sbox_outs[13][32-4], sbox_outs[13][32-25]};
				
	right_boxed[13] = left_boxed[12]^f[13];
	 
	// ***********************************************
	// Iteration 14:
	
	left_boxed[14] = right_boxed[13];
	
	e_transform[14] = {right_boxed[13][32-32], right_boxed[13][32-1],  right_boxed[13][32-2],  right_boxed[13][32-3],  right_boxed[13][32-4],  right_boxed[13][32-5],
                      right_boxed[13][32-4],  right_boxed[13][32-5],  right_boxed[13][32-6],  right_boxed[13][32-7],  right_boxed[13][32-8],  right_boxed[13][32-9],
                      right_boxed[13][32-8],  right_boxed[13][32-9],  right_boxed[13][32-10], right_boxed[13][32-11], right_boxed[13][32-12], right_boxed[13][32-13],
                      right_boxed[13][32-12], right_boxed[13][32-13], right_boxed[13][32-14], right_boxed[13][32-15], right_boxed[13][32-16], right_boxed[13][32-17],
                      right_boxed[13][32-16], right_boxed[13][32-17], right_boxed[13][32-18], right_boxed[13][32-19], right_boxed[13][32-20], right_boxed[13][32-21],
                      right_boxed[13][32-20], right_boxed[13][32-21], right_boxed[13][32-22], right_boxed[13][32-23], right_boxed[13][32-24], right_boxed[13][32-25],
                      right_boxed[13][32-24], right_boxed[13][32-25], right_boxed[13][32-26], right_boxed[13][32-27], right_boxed[13][32-28], right_boxed[13][32-29],
                      right_boxed[13][32-28], right_boxed[13][32-29], right_boxed[13][32-30], right_boxed[13][32-31], right_boxed[13][32-32], right_boxed[13][32-1]};
	  
	keyXetran[14] = e_transform[14]^permutes[14];
	 
	// s-box-1
	row[0] = {keyXetran[14][47], keyXetran[14][42]};
	column[0] = keyXetran[14][46:43];
	sbox_outs[14][31:28] = s_box[0][row[0]][8'd63 - column[0] * 4'd4 -: 4];
		
	// s-box-2
	row[1] = {keyXetran[14][41], keyXetran[14][36]};
	column[1] = keyXetran[14][40:37];
	sbox_outs[14][27:24] = s_box[1][row[1]][63 - column[1] * 4 -: 4];
		
	// s-box-3
	row[2] = {keyXetran[14][35], keyXetran[14][30]};
	column[2] = keyXetran[14][34:31];
	sbox_outs[14][23:20] = s_box[2][row[2]][63 - column[2] * 4 -: 4];
		
	// s-box-4
	row[3] = {keyXetran[14][29], keyXetran[14][24]};
	column[3] = keyXetran[14][28:25];
	sbox_outs[14][19:16] = s_box[3][row[3]][63 - column[3] * 4 -: 4];
			
	// s-box-5
	row[4] = {keyXetran[14][23], keyXetran[14][18]};
	column[4] = keyXetran[14][22:19];
	sbox_outs[14][15:12] = s_box[4][row[4]][63 - column[4] * 4 -: 4];
		
	// s-box-6
	row[5] = {keyXetran[14][17], keyXetran[14][12]};
	column[5] = keyXetran[14][16:13];
	sbox_outs[14][11:8] = s_box[5][row[5]][63 - column[5] * 4 -: 4];
		
	// s-box-7
	row[6] = {keyXetran[14][11], keyXetran[14][6]};
	column[6] = keyXetran[14][10:7];
	sbox_outs[14][7:4] = s_box[6][row[6]][63 - column[6] * 4 -: 4];
		
	// s-box-8
	row[7] = {keyXetran[14][5], keyXetran[14][0]};
	column[7] = keyXetran[14][4:1];
	sbox_outs[14][3:0] = s_box[7][row[7]][63 - column[7] * 4 -: 4];
	 
	f[14] = {sbox_outs[14][32-16], sbox_outs[14][32-7], sbox_outs[14][32-20], sbox_outs[14][32-21],
				sbox_outs[14][32-29], sbox_outs[14][32-12], sbox_outs[14][32-28], sbox_outs[14][32-17],
				sbox_outs[14][32-1], sbox_outs[14][32-15], sbox_outs[14][32-23], sbox_outs[14][32-26],
				sbox_outs[14][32-5], sbox_outs[14][32-18], sbox_outs[14][32-31], sbox_outs[14][32-10],
				sbox_outs[14][32-2], sbox_outs[14][32-8], sbox_outs[14][32-24], sbox_outs[14][32-14],
				sbox_outs[14][32-32], sbox_outs[14][32-27], sbox_outs[14][32-3], sbox_outs[14][32-9],
				sbox_outs[14][32-19], sbox_outs[14][32-13], sbox_outs[14][32-30], sbox_outs[14][32-6],
				sbox_outs[14][32-22], sbox_outs[14][32-11], sbox_outs[14][32-4], sbox_outs[14][32-25]};
				
	right_boxed[14] = left_boxed[13]^f[14];
	 
	// ***********************************************
	// Iteration 15:
	
	left_boxed[15] = right_boxed[14];
	 
	e_transform[15] = {right_boxed[14][32-32], right_boxed[14][32-1],  right_boxed[14][32-2],  right_boxed[14][32-3],  right_boxed[14][32-4],  right_boxed[14][32-5],
                      right_boxed[14][32-4],  right_boxed[14][32-5],  right_boxed[14][32-6],  right_boxed[14][32-7],  right_boxed[14][32-8],  right_boxed[14][32-9],
                      right_boxed[14][32-8],  right_boxed[14][32-9],  right_boxed[14][32-10], right_boxed[14][32-11], right_boxed[14][32-12], right_boxed[14][32-13],
                      right_boxed[14][32-12], right_boxed[14][32-13], right_boxed[14][32-14], right_boxed[14][32-15], right_boxed[14][32-16], right_boxed[14][32-17],
                      right_boxed[14][32-16], right_boxed[14][32-17], right_boxed[14][32-18], right_boxed[14][32-19], right_boxed[14][32-20], right_boxed[14][32-21],
                      right_boxed[14][32-20], right_boxed[14][32-21], right_boxed[14][32-22], right_boxed[14][32-23], right_boxed[14][32-24], right_boxed[14][32-25],
                      right_boxed[14][32-24], right_boxed[14][32-25], right_boxed[14][32-26], right_boxed[14][32-27], right_boxed[14][32-28], right_boxed[14][32-29],
                      right_boxed[14][32-28], right_boxed[14][32-29], right_boxed[14][32-30], right_boxed[14][32-31], right_boxed[14][32-32], right_boxed[14][32-1]};
	  
	keyXetran[15] = e_transform[15]^permutes[15];
	
	// s-box-1
	row[0] = {keyXetran[15][47], keyXetran[15][42]};
	column[0] = keyXetran[15][46:43];
	sbox_outs[15][31:28] = s_box[0][row[0]][63 - column[0] * 4'd4 -: 4];
		
	// s-box-2
	row[1] = {keyXetran[15][41], keyXetran[15][36]};
	column[1] = keyXetran[15][40:37];
	sbox_outs[15][27:24] = s_box[1][row[1]][63 - column[1] * 4 -: 4];
		
	// s-box-3
	row[2] = {keyXetran[15][35], keyXetran[15][30]};
	column[2] = keyXetran[15][34:31];
	sbox_outs[15][23:20] = s_box[2][row[2]][63 - column[2] * 4 -: 4];
		
	// s-box-4
	row[3] = {keyXetran[15][29], keyXetran[15][24]};
	column[3] = keyXetran[15][28:25];
	sbox_outs[15][19:16] = s_box[3][row[3]][63 - column[3] * 4 -: 4];
		
	// s-box-5
	row[4] = {keyXetran[15][23], keyXetran[15][18]};
	column[4] = keyXetran[15][22:19];
	sbox_outs[15][15:12] = s_box[4][row[4]][63 - column[4] * 4 -: 4];
		
	// s-box-6
	row[5] = {keyXetran[15][17], keyXetran[15][12]};
	column[5] = keyXetran[15][16:13];
	sbox_outs[15][11:8] = s_box[5][row[5]][63 - column[5] * 4 -: 4];
		
	// s-box-7
	row[6] = {keyXetran[15][11], keyXetran[15][6]};
	column[6] = keyXetran[15][10:7];
	sbox_outs[15][7:4] = s_box[6][row[6]][63 - column[6] * 4 -: 4];
		
	// s-box-8
	row[7] = {keyXetran[15][5], keyXetran[15][0]};
	column[7] = keyXetran[15][4:1];
	sbox_outs[15][3:0] = s_box[7][row[7]][63 - column[7] * 4 -: 4];
	 
	f[15] = {sbox_outs[15][32-16], sbox_outs[15][32-7], sbox_outs[15][32-20], sbox_outs[15][32-21],
				sbox_outs[15][32-29], sbox_outs[15][32-12], sbox_outs[15][32-28], sbox_outs[15][32-17],
				sbox_outs[15][32-1], sbox_outs[15][32-15], sbox_outs[15][32-23], sbox_outs[15][32-26],
				sbox_outs[15][32-5], sbox_outs[15][32-18], sbox_outs[15][32-31], sbox_outs[15][32-10],
				sbox_outs[15][32-2], sbox_outs[15][32-8], sbox_outs[15][32-24], sbox_outs[15][32-14],
				sbox_outs[15][32-32], sbox_outs[15][32-27], sbox_outs[15][32-3], sbox_outs[15][32-9],
				sbox_outs[15][32-19], sbox_outs[15][32-13], sbox_outs[15][32-30], sbox_outs[15][32-6],
				sbox_outs[15][32-22], sbox_outs[15][32-11], sbox_outs[15][32-4], sbox_outs[15][32-25]};
				
	right_boxed[15] = left_boxed[14]^f[15];
	 
	// ***********************************************
	// Iteration 16:
	
	left_boxed[16] = right_boxed[15];
	 
	e_transform[16] = {right_boxed[15][32-32], right_boxed[15][32-1],  right_boxed[15][32-2],  right_boxed[15][32-3],  right_boxed[15][32-4],  right_boxed[15][32-5],
                      right_boxed[15][32-4],  right_boxed[15][32-5],  right_boxed[15][32-6],  right_boxed[15][32-7],  right_boxed[15][32-8],  right_boxed[15][32-9],
                      right_boxed[15][32-8],  right_boxed[15][32-9],  right_boxed[15][32-10], right_boxed[15][32-11], right_boxed[15][32-12], right_boxed[15][32-13],
                      right_boxed[15][32-12], right_boxed[15][32-13], right_boxed[15][32-14], right_boxed[15][32-15], right_boxed[15][32-16], right_boxed[15][32-17],
                      right_boxed[15][32-16], right_boxed[15][32-17], right_boxed[15][32-18], right_boxed[15][32-19], right_boxed[15][32-20], right_boxed[15][32-21],
                      right_boxed[15][32-20], right_boxed[15][32-21], right_boxed[15][32-22], right_boxed[15][32-23], right_boxed[15][32-24], right_boxed[15][32-25],
                      right_boxed[15][32-24], right_boxed[15][32-25], right_boxed[15][32-26], right_boxed[15][32-27], right_boxed[15][32-28], right_boxed[15][32-29],
                      right_boxed[15][32-28], right_boxed[15][32-29], right_boxed[15][32-30], right_boxed[15][32-31], right_boxed[15][32-32], right_boxed[15][32-1]};
	  
	keyXetran[16] = e_transform[16]^permutes[16];
	 
	// s-box-1
	row[0] = {keyXetran[16][47], keyXetran[16][42]};
	column[0] = keyXetran[16][46:43];
	sbox_outs[16][31:28] = s_box[0][row[0]][8'd63 - column[0] * 4'd4 -: 4];
		
	// s-box-2
	row[1] = {keyXetran[16][41], keyXetran[16][36]};
	column[1] = keyXetran[16][40:37];
	sbox_outs[16][27:24] = s_box[1][row[1]][63 - column[1] * 4 -: 4];
		
	// s-box-3
	row[2] = {keyXetran[16][35], keyXetran[16][30]};
	column[2] = keyXetran[16][34:31];
	sbox_outs[16][23:20] = s_box[2][row[2]][63 - column[2] * 4 -: 4];
		
	// s-box-4
	row[3] = {keyXetran[16][29], keyXetran[16][24]};
	column[3] = keyXetran[16][28:25];
	sbox_outs[16][19:16] = s_box[3][row[3]][63 - column[3] * 4 -: 4];
		
	// s-box-5
	row[4] = {keyXetran[16][23], keyXetran[16][18]};
	column[4] = keyXetran[16][22:19];
	sbox_outs[16][15:12] = s_box[4][row[4]][63 - column[4] * 4 -: 4];
		
	// s-box-6
	row[5] = {keyXetran[16][17], keyXetran[16][12]};
	column[5] = keyXetran[16][16:13];
	sbox_outs[16][11:8] = s_box[5][row[5]][63 - column[5] * 4 -: 4];
		
	// s-box-7
	row[6] = {keyXetran[16][11], keyXetran[16][6]};
	column[6] = keyXetran[16][10:7];
	sbox_outs[16][7:4] = s_box[6][row[6]][63 - column[6] * 4 -: 4];
		
	// s-box-8
	row[7] = {keyXetran[16][5], keyXetran[16][0]};
	column[7] = keyXetran[16][4:1];
	sbox_outs[16][3:0] = s_box[7][row[7]][63 - column[7] * 4 -: 4];
	
	f[16] = {sbox_outs[16][32-16], sbox_outs[16][32-7], sbox_outs[16][32-20], sbox_outs[16][32-21],
				sbox_outs[16][32-29], sbox_outs[16][32-12], sbox_outs[16][32-28], sbox_outs[16][32-17],
				sbox_outs[16][32-1], sbox_outs[16][32-15], sbox_outs[16][32-23], sbox_outs[16][32-26],
				sbox_outs[16][32-5], sbox_outs[16][32-18], sbox_outs[16][32-31], sbox_outs[16][32-10],
				sbox_outs[16][32-2], sbox_outs[16][32-8], sbox_outs[16][32-24], sbox_outs[16][32-14],
				sbox_outs[16][32-32], sbox_outs[16][32-27], sbox_outs[16][32-3], sbox_outs[16][32-9],
				sbox_outs[16][32-19], sbox_outs[16][32-13], sbox_outs[16][32-30], sbox_outs[16][32-6],
				sbox_outs[16][32-22], sbox_outs[16][32-11], sbox_outs[16][32-4], sbox_outs[16][32-25]};
				
	right_boxed[16] = left_boxed[15]^f[16];

	// *********************************************************************************************************************************
	// concact R16 and L16
	
	reversal = {right_boxed[16], left_boxed[16]};
	
	// *********************************************************************************************************************************
	// Store the final output in msg:
	
	msg = {reversal[64-40], reversal[64-8], reversal[64-48], reversal[64-16], reversal[64-56], reversal[64-24], reversal[64-64], reversal[64-32],
		    reversal[64-39], reversal[64-7], reversal[64-47], reversal[64-15], reversal[64-55], reversal[64-23], reversal[64-63], reversal[64-31],
			 reversal[64-38], reversal[64-6], reversal[64-46], reversal[64-14], reversal[64-54], reversal[64-22], reversal[64-62], reversal[64-30],
			 reversal[64-37], reversal[64-5], reversal[64-45], reversal[64-13], reversal[64-53], reversal[64-21], reversal[64-61], reversal[64-29],
			 reversal[64-36], reversal[64-4], reversal[64-44], reversal[64-12], reversal[64-52], reversal[64-20], reversal[64-60], reversal[64-28],
			 reversal[64-35], reversal[64-3], reversal[64-43], reversal[64-11], reversal[64-51], reversal[64-19], reversal[64-59], reversal[64-27],
			 reversal[64-34], reversal[64-2], reversal[64-42], reversal[64-10], reversal[64-50], reversal[64-18], reversal[64-58], reversal[64-26],
			 reversal[64-33], reversal[64-1], reversal[64-41], reversal[64-9], reversal[64-49], reversal[64-17], reversal[64-57], reversal[64-25]};

end

endmodule
