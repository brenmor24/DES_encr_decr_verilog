module test_encryption(input clk);
reg [63:0] key;
reg [55:0] key_plus;
reg [27:0] C0;
reg [27:0] D0;

reg [27:0] c_blocks [15:0];
reg [27:0] d_blocks [15:0];

reg [55:0] concat [15:0];
reg [47:0] permutes [15:0];

reg [63:0] value;
reg [63:0] value_plus;

reg [31:0] L0;
reg [31:0] R0;

reg [31:0] lefts [15:0];
reg [31:0] rights [15:0];

reg ebits[47:0];
reg function0[47:0];

reg [2047:0] box_unrolled

reg [31:0] right_boxed [16:0];
reg [31:0] left_boxed [16:0];

reg [47:0] e_transform [15:0];
reg [47:0] keyXetran [15:0];

reg []

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

    c_blocks[0] = {C0[26:0], C0[27]};
    d_blocks[0] = {D0[26:0], D0[27]};

    c_blocks[1] = {C0[25:0], C0[27:26]};
    d_blocks[1] = {D0[25:0], D0[27:26]};

    c_blocks[2] = {C0[23:0], C0[27:24]};
    d_blocks[2] = {D0[23:0], D0[27:24]};

    c_blocks[3] = {C0[21:0], C0[27:22]};
    d_blocks[3] = {D0[21:0], D0[27:22]};

    c_blocks[4] = {C0[19:0], C0[27:20]};
    d_blocks[4] = {D0[19:0], D0[27:20]};

    c_blocks[5] = {C0[17:0], C0[27:18]};
    d_blocks[5] = {D0[17:0], D0[27:18]};

    c_blocks[6] = {C0[15:0], C0[27:16]};
    d_blocks[6] = {D0[15:0], D0[27:16]};

    c_blocks[7] = {C0[13:0], C0[27:14]};
    d_blocks[7] = {D0[13:0], D0[27:14]};

    c_blocks[8] = {C0[12:0], C0[27:13]};
    d_blocks[8] = {D0[12:0], D0[27:13]};

    c_blocks[9] = {C0[10:0], C0[27:11]};
    d_blocks[9] = {D0[10:0], D0[27:11]};

    c_blocks[10] = {C0[8:0], C0[27:9]};
    d_blocks[10] = {D0[8:0], D0[27:9]};

    c_blocks[11] = {C0[6:0], C0[27:7]};
    d_blocks[11] = {D0[6:0], D0[27:7]};

    c_blocks[12] = {C0[4:0], C0[27:5]};
    d_blocks[12] = {D0[4:0], D0[27:5]};

    c_blocks[13] = {C0[2:0], C0[27:3]};
    d_blocks[13] = {D0[2:0], D0[27:3]};

    c_blocks[14] = {C0[0], C0[27:1]};
    d_blocks[14] = {D0[0], D0[27:1]};

    c_blocks[15] = C0;
    d_blocks[15] = D0;

    // fourth state
    for (i = 0; i < 16; i = i + 1)
    begin
        concat[i] = {c_block, d_block};
    end

    // fifth state
    for (i = 0; i < 16; i = i + 1)
    begin
        permutes[i] = { concat[i][14], concat[i][17], concat[i][11], concat[i][24], concat[i][1],  concat[i][5],
                        concat[i][3],  concat[i][28], concat[i][15], concat[i][6],  concat[i][21], concat[i][10],
                        concat[i][23], concat[i][19], concat[i][12], concat[i][4],  concat[i][26], concat[i][8],
                        concat[i][16], concat[i][7],  concat[i][27], concat[i][20], concat[i][13], concat[i][2],
                        concat[i][41], concat[i][52], concat[i][31], concat[i][37], concat[i][47], concat[i][55],
                        concat[i][30], concat[i][40], concat[i][51], concat[i][45], concat[i][33], concat[i][48],
                        concat[i][44], concat[i][49], concat[i][39], concat[i][56], concat[i][34], concat[i][53],
                        concat[i][46], concat[i][42], concat[i][50], concat[i][36], concat[i][29], concat[i][32]};
    end
    // fill sbox structure
    box_unrolled = {4'd14, 4'd4, 4'd13, 4'd1, 4'd2, 4'd15, 4'd11, 4'd8, 4'd3, 4'd10, 4'd6, 4'd12, 4'd5, 4'd9, 4'd0, 4'd7,
                    4'd0, 4'd15, 4'd7, 4'd4, 4'd14, 4'd2, 4'd13, 4'd1, 4'd10, 4'd6, 4'd12, 4'd11, 4'd9, 4'd5, 4'd3, 4'd8,
                    4'd4, 4'd1, 4'd14, 4'd8, 4'd13, 4'd6, 4'd2, 4'd11, 4'd15, 4'd12, 4'd9, 4'd7, 4'd3, 4'd10, 4'd5, 4'd0,
                    4'd15, 4'd12, 4'd8, 4'd2, 4'd4, 4'd9, 4'd1, 4'd7, 4'd5, 4'd11, 4'd3, 4'd14, 4'd10, 4'd0, 4'd6, 4'd13,
                    4'd15, 4'd1, 4'd8, 4'd14, 4'd6, 4'd11, 4'd3, 4'd4, 4'd9, 4'd7, 4'd2, 4'd13, 4'd12, 4'd0, 4'd5, 4'd10, 
                    4'd3, 4'd13, 4'd4, 4'd7, 4'd15, 4'd2, 4'd8, 4'd14, 4'd12, 4'd0, 4'd1, 4'd10, 4'd6, 4'd9, 4'd11, 4'd5,
                    4'd0, 4'd14, 4'd7, 4'd11, 4'd10, 4'd4, 4'd13, 4'd1, 4'd5, 4'd8, 4'd12, 4'd6, 4'd9, 4'd3, 4'd2, 4'd15,
                    4'd13, 4'd8, 4'd10, 4'd1, 4'd3, 4'd15, 4'd4, 4'd2, 4'd11, 4'd6, 4'd7, 4'd12, 4'd0, 4'd5, 4'd14, 4'd9,
                    4'd10, 4'd0, 4'd9, 4'd14, 4'd6, 4'd3, 4'd15, 4'd5, 4'd1, 4'd13, 4'd12, 4'd7, 4'd11, 4'd4, 4'd2, 4'd8,
                    4'd3, 4'd13, 4'd4, 4'd7, 4'd15, 4'd2, 4'd8, 4'd14, 4'd12, 4'd0, 4'd1, 4'd10, 4'd6, 4'd9, 4'd11, 4'd5,
                    4'd13, 4'd6, 4'd4, 4'd9, 4'd8, 4'd15, 4'd3, 4'd0, 4'd11, 4'd1, 4'd2, 4'd12, 4'd5, 4'd10, 4'd14, 4'd7,
                    4'd1, 4'd10, 4'd13, 4'd0, 4'd6, 4'd9, 4'd8, 4'd7, 4'd4, 4'd15, 4'd14, 4'd3, 4'd11, 4'd5, 4'd2, 4'd12,
                    4'd7, 4'd13, 4'd14, 4'd3, 4'd0, 4'd6, 4'd9, 4'd10, 4'd1, 4'd2, 4'd8, 4'd5, 4'd11, 4'd12, 4'd4, 4'd15,
                    4'd13, 4'd8, 4'd11, 4'd5, 4'd6, 4'd15, 4'd0, 4'd3, 4'd4, 4'd7, 4'd2, 4'd12, 4'd1, 4'd10, 4'd14, 4'd9,
                    4'd10, 4'd6, 4'd9, 4'd0, 4'd12, 4'd11, 4'd7, 4'd13, 4'd15, 4'd1, 4'd3, 4'd14, 4'd5, 4'd2, 4'd8, 4'd4,
                    4'd3, 4'd15, 4'd0, 4'd6, 4'd10, 4'd1, 4'd13, 4'd8, 4'd9, 4'd4, 4'd5, 4'd11, 4'd12, 4'd7, 4'd2, 4'd14,
                    4'd2, 4'd12, 4'd4, 4'd1, 4'd7, 4'd10, 4'd11, 4'd6, 4'd8, 4'd5, 4'd3, 4'd15, 4'd13, 4'd0, 4'd14, 4'd9,
                    4'd14, 4'd11, 4'd2, 4'd12, 4'd4, 4'd7, 4'd13, 4'd1, 4'd5, 4'd0, 4'd15, 4'd10, 4'd3, 4'd9, 4'd8, 4'd6,
                    4'd4, 4'd2, 4'd1, 4'd11, 4'd10, 4'd13, 4'd7, 4'd8, 4'd15, 4'd9, 4'd12, 4'd5, 4'd6, 4'd3, 4'd0, 4'd14,
                    4'd11, 4'd8, 4'd12, 4'd7, 4'd1, 4'd14, 4'd2, 4'd13, 4'd6, 4'd15, 4'd0, 4'd9, 4'd10, 4'd4, 4'd5, 4'd3, 
                    4'd12, 4'd1, 4'd10, 4'd15, 4'd9, 4'd2, 4'd6, 4'd8, 4'd0, 4'd13, 4'd3, 4'd4, 4'd14, 4'd7, 4'd5, 4'd11,
                    4'd10, 4'd15, 4'd4, 4'd2, 4'd7, 4'd12, 4'd9, 4'd5, 4'd6, 4'd1, 4'd13, 4'd14, 4'd0, 4'd11, 4'd3, 4'd8,
                    4'd9, 4'd14, 4'd15, 4'd5, 4'd2, 4'd8, 4'd12, 4'd3, 4'd7, 4'd0, 4'd4, 4'd10, 4'd1, 4'd13, 4'd11, 4'd6,
                    4'd4, 4'd3, 4'd2, 4'd12, 4'd9, 4'd5, 4'd15, 4'd10, 4'd11, 4'd14, 4'd1, 4'd7, 4'd6, 4'd0, 4'd8, 4'd13,
                    4'd4, 4'd11, 4'd2, 4'd14, 4'd15, 4'd0, 4'd8, 4'd13, 4'd3, 4'd12, 4'd9, 4'd7, 4'd5, 4'd10, 4'd6, 4'd1,
                    4'd13, 4'd0, 4'd11, 4'd7, 4'd4, 4'd9, 4'd1, 4'd10, 4'd14, 4'd3, 4'd5, 4'd12, 4'd2, 4'd15, 4'd8, 4'd6,
                    4'd1, 4'd4, 4'd11, 4'd13, 4'd12, 4'd3, 4'd7, 4'd14, 4'd10, 4'd15, 4'd6, 4'd8, 4'd0, 4'd5, 4'd9, 4'd2,
                    4'd6, 4'd11, 4'd13, 4'd8, 4'd1, 4'd4, 4'd10, 4'd7, 4'd9, 4'd5, 4'd0, 4'd15, 4'd14, 4'd2, 4'd3, 4'd12,
                    4'd13, 4'd2, 4'd8, 4'd4, 4'd6, 4'd15, 4'd11, 4'd1, 4'd10, 4'd9, 4'd3, 4'd14, 4'd5, 4'd0, 4'd12, 4'd7,
                    4'd1, 4'd15, 4'd13, 4'd8, 4'd10, 4'd3, 4'd7, 4'd4, 4'd12, 4'd5, 4'd6, 4'd11, 4'd0, 4'd14, 4'd9, 4'd2,
                    4'd7, 4'd11, 4'd4, 4'd1, 4'd9, 4'd12, 4'd14, 4'd2, 4'd0, 4'd6, 4'd10, 4'd13, 4'd15, 4'd3, 4'd5, 4'd8,
                    4'd2, 4'd1, 4'd14, 4'd7, 4'd4, 4'd10, 4'd8, 4'd13, 4'd15, 4'd12, 4'd9, 4'd0, 4'd3, 4'd5, 4'd6, 4'd11};

    // value section

    // sixth state
    value_plus={value[58], value[50], value[42], value[34], value[26], value[18], value[10], value[2],
                value[60], value[52], value[44], value[36], value[28], value[20], value[12], value[4],
                value[62], value[54], value[46], value[38], value[30], value[22], value[14], value[6],
                value[64], value[56], value[48], value[40], value[32], value[24], value[16], value[8],
                value[57], value[49], value[41], value[33], value[25], value[17], value[9],  value[1],
                value[59], value[51], value[43], value[35], value[27], value[19], value[11], value[3],
                value[61], value[53], value[45], value[37], value[29], value[21], value[13], value[5],
                value[63], value[55], value[47], value[39], value[31], value[23], value[15], value[7]};

    L0 = value_plus[63:32];
    R0 = value_plus[31:0];

    left_boxed[0] = L0;
    right_boxed[0] = R0;

    for (i = 1; i < 17; i = i + 1)
    begin
        left_boxed[i] = right_boxed[i - 1];
        e_transform[i-1] = {R[i-1][58], R[i-1][50], R[i-1][42], R[i-1][34], R[i-1][26], R[i-1][18],
                            R[i-1][60], R[i-1][52], R[i-1][44], R[i-1][36], R[i-1][28], R[i-1][20],
                            R[i-1][62], R[i-1][54], R[i-1][46], R[i-1][38], R[i-1][30], R[i-1][22],
                            R[i-1][64], R[i-1][56], R[i-1][48], R[i-1][40], R[i-1][32], R[i-1][24],
                            R[i-1][57], R[i-1][49], R[i-1][41], R[i-1][33], R[i-1][25], R[i-1][17],
                            R[i-1][59], R[i-1][51], R[i-1][43], R[i-1][35], R[i-1][27], R[i-1][19],
                            R[i-1][61], R[i-1][53], R[i-1][45], R[i-1][37], R[i-1][29], R[i-1][21],
                            R[i-1][63], R[i-1][55], R[i-1][47], R[i-1][39], R[i-1][31], R[i-1][23]};

        keyXetran[i-1] = e_transform[i-1]^permutes[i-1];
        right_boxed[i] = left_boxed[i - 1]^();
    end
    {keyXetran[i-1][47], keyXetran[i-1][42]} * 64 + {keyXetran[i-1][46], keyXetran[i-1][45], keyXetran[i-1][44], keyXetran[i-1][43]} * 4

    box_unrolled[({})]

    /*
    ebits ={R0[58], R0[50], R0[42], R0[34], R0[26], R0[18],
            R0[60], R0[52], R0[44], R0[36], R0[28], R0[20],
            R0[62], R0[54], R0[46], R0[38], R0[30], R0[22],
            R0[64], R0[56], R0[48], R0[40], R0[32], R0[24],
            R0[57], R0[49], R0[41], R0[33], R0[25], R0[17],
            R0[59], R0[51], R0[43], R0[35], R0[27], R0[19],
            R0[61], R0[53], R0[45], R0[37], R0[29], R0[21],
            R0[63], R0[55], R0[47], R0[39], R0[31], R0[23]};

    lefts[0] = R0;
    function0 = ebit0^permutes[0];
    */


end

endmodule