`timescale 1ns / 1ns
module PIPELINE_MIPS32(clk);
input clk; 
reg temp;
reg[31:0] PC,IF_ID_IR,IF_ID_NPC;
reg[31:0] ID_EX_IR,ID_EX_NPC,ID_EX_A,ID_EX_B,ID_EX_Imm;
reg[2:0] ID_EX_type,EX_MEM_type,MEM_WB_type;
reg[31:0] EX_MEM_IR,EX_MEM_ALUOut,EX_MEM_B;
reg EX_MEM_cond;
reg[31:0] MEM_WB_IR,MEM_WB_ALUOut,MEM_WB_LMD;

reg[31:0] NEW_PC,NEW_IF_ID_IR,NEW_IF_ID_NPC;
reg[31:0] NEW_ID_EX_IR,NEW_ID_EX_NPC,NEW_ID_EX_A,NEW_ID_EX_B,NEW_ID_EX_Imm;
reg[2:0] NEW_ID_EX_type,NEW_EX_MEM_type,NEW_MEM_WB_type;
reg[31:0] NEW_EX_MEM_IR,NEW_EX_MEM_ALUOut,NEW_EX_MEM_B;
reg NEW_EX_MEM_cond;
reg[31:0] NEW_MEM_WB_IR,NEW_MEM_WB_ALUOut,NEW_MEM_WB_LMD;
reg[31:0] R0,R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12,R13,R14,R15,R16,R17,R18,R19,R20,
          R21,R22,R23,R24,R25,R26,R27,R28,R29,R30,R31;
reg[31:0] Reg [0:31]; // register bank 32x32
reg[31:0] Mem [0:1023]; // 1024x32 memory
reg HALTED;
reg NEW_HALTED;
// Set after HLT instruction is completed (in WB stage)
reg TAKEN_BRANCH;
reg NEW_TAKEN_BRANCH;
// Required to disable instructions after branch

parameter 
ADD=6'b000000, SUB=6'b000001,  AND=6'b000010,  OR=6'b000011, 
SLT=6'b000100, MUL=6'b000101,  HLT=6'b111111,  LW=6'b001000, 
SW=6'b001001,  ADDI=6'b001010, SUBI=6'b001011, SLTI=6'b001100,
LS=6'b010000, RS=6'b010001, 
BNEQZ=6'b001101, BEQZ=6'b001110;

parameter 
RR_ALU=3'b000, RM_ALU=3'b001, LOAD=3'b010, 
STORE=3'b011, BRANCH=3'b100, HALT=3'b101;

always @ (posedge clk)
// IF Stage
if (HALTED == 0)
begin
    if(((EX_MEM_IR[31:26]==BEQZ)&& (EX_MEM_cond == 1)) ||((EX_MEM_IR[31:26]==BNEQZ) && (EX_MEM_cond == 0)))
        begin
        NEW_IF_ID_IR  <= Mem [EX_MEM_ALUOut];
        NEW_TAKEN_BRANCH  <= 1'b1;
        NEW_IF_ID_NPC  <= EX_MEM_ALUOut + 1;
        NEW_PC  <= EX_MEM_ALUOut + 1;
        end
    else
        begin
        NEW_IF_ID_IR  <= Mem [PC];
        NEW_IF_ID_NPC  <= PC + 1;
        NEW_PC  <= PC + 1;
        end
end

always@(posedge clk)
// ID stage
if (HALTED == 0)
begin
    if (IF_ID_IR[25:21]== 5'b00000) 
        NEW_ID_EX_A <= 0;
    else 
        NEW_ID_EX_A  <= Reg [IF_ID_IR[25:21]]; // "IS"
    if (IF_ID_IR [20:16] == 5'b00000)
        NEW_ID_EX_B <= 0;
    else 
        NEW_ID_EX_B  <= Reg[IF_ID_IR[20:16]]; // "xt"
    NEW_ID_EX_NPC  <= IF_ID_NPC;
    NEW_ID_EX_IR  <= IF_ID_IR;
    NEW_ID_EX_Imm  <= {{16{IF_ID_IR [15]}}, {IF_ID_IR [15:0]}};
    case (IF_ID_IR[31:26]) 
        ADD, SUB, AND, OR, SLT, MUL, LS, RS: NEW_ID_EX_type  <= RR_ALU;
        ADDI, SUBI, SLTI: NEW_ID_EX_type  <= RM_ALU;
        LW: NEW_ID_EX_type  <= LOAD;
        SW: NEW_ID_EX_type  <= STORE;
        BNEQZ, BEQZ: NEW_ID_EX_type  <= BRANCH;
        HLT:
        begin
        NEW_ID_EX_type  <= HALT;
        temp <= 1;
        end
        default:NEW_ID_EX_type  <= HALT;
        // Invalid opcode
    endcase
end

always @ (posedge clk)
// EX Stage
if (HALTED == 0)
begin
NEW_EX_MEM_type  <= ID_EX_type;
NEW_EX_MEM_IR  <= ID_EX_IR;
NEW_TAKEN_BRANCH  <= 0;
case (ID_EX_type)
        RR_ALU: begin
                case (ID_EX_IR [31:26]) // "opcode"
                        ADD: NEW_EX_MEM_ALUOut  <= ID_EX_A + ID_EX_B;
                        SUB: NEW_EX_MEM_ALUOut  <= ID_EX_A - ID_EX_B;
                        AND: NEW_EX_MEM_ALUOut  <= ID_EX_A & ID_EX_B;
                        OR: NEW_EX_MEM_ALUOut <= ID_EX_A | ID_EX_B;
                        SLT: NEW_EX_MEM_ALUOut <= ID_EX_A < ID_EX_B;
                        MUL: NEW_EX_MEM_ALUOut <= ID_EX_A * ID_EX_B;
                        LS: NEW_EX_MEM_ALUOut <= ID_EX_A << ID_EX_B;
                        RS: NEW_EX_MEM_ALUOut <= ID_EX_A >> ID_EX_B;
                        default: NEW_EX_MEM_ALUOut  <= 32'hxxxxxxxx;
                endcase
                end

        RM_ALU: begin
                case (ID_EX_IR[31:26]) // "opcode"
                ADDI:NEW_EX_MEM_ALUOut <= ID_EX_A + ID_EX_Imm;
                SUBI:NEW_EX_MEM_ALUOut <= ID_EX_A - ID_EX_Imm;
                SLTI :NEW_EX_MEM_ALUOut <= ID_EX_A < ID_EX_Imm;
                default : NEW_EX_MEM_ALUOut <= 32'hxxxxxxxx;
                endcase
                end
                
        LOAD,STORE: begin
                        NEW_EX_MEM_ALUOut <= ID_EX_A + ID_EX_Imm;
                        NEW_EX_MEM_B <= ID_EX_B;
                end

        BRANCH: begin
                NEW_EX_MEM_ALUOut <= ID_EX_NPC + ID_EX_Imm;
                NEW_EX_MEM_cond <= (ID_EX_A == 0);
                end
endcase
end

always @ (posedge clk)
// MEM stage
if (HALTED == 0)
begin
NEW_MEM_WB_type <= EX_MEM_type;
NEW_MEM_WB_IR <= EX_MEM_IR;
case (EX_MEM_type)
        RR_ALU, RM_ALU:
        NEW_MEM_WB_ALUOut <= EX_MEM_ALUOut;
        LOAD:
        NEW_MEM_WB_LMD <= Mem [EX_MEM_ALUOut];
        STORE: if (TAKEN_BRANCH==0) // Disable write
                Mem [EX_MEM_ALUOut] <= EX_MEM_B;
endcase
end

always @ (posedge clk)
begin
if (TAKEN_BRANCH == 0 ) // Disable write if branch taken
case (MEM_WB_type)
        RR_ALU: Reg [MEM_WB_IR[15:11]] <= MEM_WB_ALUOut; // "Rd"
        RM_ALU: Reg [MEM_WB_IR[20:16]] <= MEM_WB_ALUOut; // "Rt"
        LOAD: Reg [MEM_WB_IR[20:16]] <= MEM_WB_LMD; // "rt"
        HALT: NEW_HALTED <= 1'b1;
endcase
end

always @ (negedge clk)
begin
 R0=Reg[0]; R1=Reg[1]; R2=Reg[2]; R3=Reg[3]; R4=Reg[4]; R5=Reg[5]; R6=Reg[6]; R7=Reg[7]; 
 R8=Reg[8]; R9=Reg[9]; R10=Reg[10]; R11=Reg[11]; R12=Reg[12]; R13=Reg[13]; R14=Reg[14]; 
 R15=Reg[15]; R16=Reg[16]; R17=Reg[17]; R18=Reg[18]; R19=Reg[19]; R20=Reg[20]; R21=Reg[21]; 
 R22=Reg[22]; R23=Reg[23]; R24=Reg[24]; R25=Reg[25]; R26=Reg[26]; R27=Reg[27]; R28=Reg[28];
 R29=Reg[29]; R30=Reg[30]; R31=Reg[31];
PC <= NEW_PC;
IF_ID_IR <= NEW_IF_ID_IR;
IF_ID_NPC <= NEW_IF_ID_NPC;
ID_EX_IR <= NEW_ID_EX_IR;
ID_EX_NPC <= NEW_ID_EX_NPC;
ID_EX_A <= NEW_ID_EX_A;
ID_EX_B <= NEW_ID_EX_B;
ID_EX_Imm <= NEW_ID_EX_Imm;
ID_EX_type <= NEW_ID_EX_type;
EX_MEM_type <= NEW_EX_MEM_type;
MEM_WB_type <= NEW_MEM_WB_type;
EX_MEM_IR <= NEW_EX_MEM_IR;
EX_MEM_ALUOut <= NEW_EX_MEM_ALUOut;
EX_MEM_B <= NEW_EX_MEM_B;
EX_MEM_cond <= NEW_EX_MEM_cond;
MEM_WB_IR <= NEW_MEM_WB_IR;
MEM_WB_ALUOut <= NEW_MEM_WB_ALUOut;
MEM_WB_LMD <= NEW_MEM_WB_LMD;
HALTED <= NEW_HALTED;
TAKEN_BRANCH <= NEW_TAKEN_BRANCH;
if(temp==1)
   begin
   HALTED<=1;
   end
if(HALTED==1 && temp==0) HALTED<=0;
end
endmodule