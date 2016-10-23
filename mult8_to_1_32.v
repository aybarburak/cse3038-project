module mult8_to_1_32(out, i0,i1,i2,i3,i4,i5,i6,i7,s0);
output [31:0] out;
input [31:0]i0,i1,i2,i3,i4,i5,i6,i7;
input [2:0]s0;
assign out = (s0 == 3'b000) ? i0 :
             (s0 == 3'b001) ? i1 :
             (s0 == 3'b010) ? i2 :
             (s0 == 3'b011) ? i3 :
             (s0 == 3'b100) ? i4 :
             (s0 == 3'b101) ? i5 :
             (s0 == 3'b110) ? i6 : i7;
endmodule
