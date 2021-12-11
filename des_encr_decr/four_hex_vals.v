// Calls seven-segment four times to display a 16-bit value.

module four_hex_vals(
input [15:0]val,
output [6:0]seg7_dig0,
output [6:0]seg7_dig1,
output [6:0]seg7_dig2,
output [6:0]seg7_dig3
);

seven_segment leftmost(val[15:12], seg7_dig0);
seven_segment left_2(val[11:8], seg7_dig1);
seven_segment right_2(val[7:4], seg7_dig2);
seven_segment rightmost(val[3:0], seg7_dig3);

endmodule
