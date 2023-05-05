`timescale 1ns / 1ns
module TEST_MIPS32;
reg clk;
integer k;
PIPELINE_MIPS32 mips (clk);
initial
begin
clk = 0;
repeat (1000000)
begin
#50 clk = 1; 
#50 clk = 0;
end
end

initial
begin
for (k=0; k<31; k=k+1)
 mips.Reg [k] = k;

mips.Mem [0] = 32'h28010005;
mips.Mem [1] = 32'h2802000a;
mips.Mem [2] = 32'h28030014;
mips.Mem [3] = 32'h28040001;
mips.Mem [4] = 32'h00222800;
mips.Mem [5] = 32'h04623000;
mips.Mem [6] = 32'h2c270001;
mips.Mem [7] = 32'h14434000;
mips.Mem [8] = 32'h44244800;
mips.Mem [9] = 32'h40245000;
mips.Mem [10]= 32'hfc000000;

mips. HALTED = 0;
mips. NEW_HALTED = 0;
mips. PC=0; 
mips. NEW_PC=0; 
mips. TAKEN_BRANCH = 0;
mips. NEW_TAKEN_BRANCH = 0;
mips. temp=0;
#2500
for (k=0; k<11; k=k+1)
$display ("R%1d - %2d", k, mips.Reg[k]);
end
initial
begin
$dumpfile ("mips.vcd");
$dumpvars (0, TEST_MIPS32);
#3000 $finish;
end
endmodule