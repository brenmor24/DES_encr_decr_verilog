module test_encryption(input clk);
reg [63:0]key;
reg [55:0]key_plus;
reg [27:0]C0;
reg [27:0]D0;

reg [27:0] c_blocks [15:0];
reg [27:0] d_blocks [15:0];

reg [55:0] concat [15:0];
reg [47:0] permutes [15:0];

reg 

always @(*)
begin
    // first state
    key_plus = {key[57], key[49], key[41], key[33], key[25], key[17], key[9],
                key[1],  key[58], key[50], key[42], key[34], key[26], key[18],
                key[10], key[2],  key[59], key[51], key[43], key[35], key[27],
                key[19], key[11], key[3],  key[60], key[52], key[44], key[36],
                key[63], key[55], key[47], key[39], key[31], key[23], key[15],
                key[7],  key[62], key[54], key[46], key[38], key[30], key[22],
                key[14], key[6],  key[61], key[53], key[45], key[37], key[29],
                key[21], key[13], key[5],  key[28], key[20], key[12], key[4]};
    
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
                        concat[i][16], concat[i][7],  concat[i][27], concat[i][20], concat[i][13], concat[i][44],
                        concat[i][41], concat[i][52], concat[i][31], concat[i][37], concat[i][47], concat[i][23],
                        concat[i][30], concat[i][40], concat[i][51], concat[i][45], concat[i][33], concat[i][30],
                        concat[i][44], concat[i][49], concat[i][39], concat[i][56], concat[i][34], concat[i][37],
                        concat[i][46], concat[i][42], concat[i][50], concat[i][36], concat[i][29], concat[i][12]};
    end

end

endmodule