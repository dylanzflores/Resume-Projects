module datapath (input clk, reset,
input accwe,
input memtoacc, pcsrc,
input alusrc, regdst,
input regwrite, jump, regtoacc,
input [3:0] alucontrol,
output zero,
output [7:0] pc,
input [15:0] instr, output[7:0] acc,
output [7:0] aluout, writedata,
input [7:0] readdata,
output acc_reg_is_zero);

wire [3:0] writereg;
wire [7:0] pcnext, pcnextbr, pcplus1, pcbranch;
wire [7:0] signimm, signimmsh;
wire [7:0] srca, srcb, srcc;
wire [7:0] result, srcb_result, acc_result, acc_ld_result, acc_final;

wire accwedata;
assign accwedata = (instr[7:4] == 4'b0001) ? 1 : 0; // LDAC 

assign acc = srca;
mux2 #(8) regtoa(aluout, writedata, regtoacc, acc_result);
mux2 #(8) ldactoacc(aluout, readdata, accwedata, acc_ld_result);
assign acc_final = (accwedata == 0) ? acc_result : acc_ld_result;
accumulator accumulator(acc_final, clk, accwe, reset, srca);

assign acc_reg_is_zero = srca[7] | srca[6] | srca[5] | srca[4] | srca[3] | srca[2] | srca[1] | srca[0];
// next PC logic
flopr #(8) pcreg(clk, reset, pcnext, pc);
adder pcadd1 (pc, 8'b1, pcplus1);
sl2 immsh(signimm, signimmsh); 
adder pcadd2(pcplus1, signimmsh, pcbranch);
mux2 #(8) pcbrmux(pcplus1, pcbranch, pcsrc, pcnextbr);
mux2 #(8) pcmux(pcnextbr, {pcplus1[7:4], instr[3:0]},jump, pcnext);
// register file logic
regfile rf(clk, regwrite, instr[3:0],
instr[3:0], writereg, srca, writedata, srcc);
mux2 #(4) wrmux(instr[3:0], instr[3:0],regdst, writereg);
mux2 #(8) resmux(aluout, readdata, memtoacc, result);
signext se(instr, signimm);
// ALU logic
mux2 #(8) srcbmux(result, instr, alusrc, srcb_result);
alu alu(srca, writedata, alucontrol, aluout, zero);

endmodule

module dmem (input clk, we,
input [3:0] a, 
input [7:0] wd,
output [7:0] rd);

reg [7:0] RAM[15:0];
assign rd = RAM[a];

initial begin
	RAM[0] <= 0;
	RAM[1] <= 0;
	RAM[2] <= 0;
	RAM[3] <= 0;
	RAM[4] <= 0;
	RAM[5] <= 0;
	RAM[6] <= 0;
	RAM[7] <= 0;
	RAM[8] <= 0;
	RAM[9] <= 0;
	RAM[10] <= 0;
	RAM[11] <= 0;
	RAM[12] <= 0;
	RAM[13] <= 0;
	RAM[14] <= 0;
	RAM[15] <= 0;
end
always @ (posedge clk)
if (we)
	RAM[a] <= wd;
endmodule

module flopr # (parameter WIDTH = 8)
(input clk, reset,
input [WIDTH-1:0] d,
output reg [WIDTH-1:0] q);
always @ (posedge clk, posedge reset)
if (reset) q <= 0;
else q <= d;
endmodule

module controller (input [7:0] instr,
input zero,
output accwe, memtoacc, memwrite,
output pcsrc, alusrc,
output regdst, regwrite,
output jump, regtoacc,
output [3:0] alucontrol,
input acc_reg_is_zero);
wire [1:0] aluop;
wire branch;


maindec md(instr, accwe, memtoacc, memwrite, branch,
alusrc, regdst, regwrite, jump,
aluop, regtoacc, acc_reg_is_zero);
aludec ad (instr, aluop, alucontrol);

assign pcsrc = branch & zero;
endmodule

module aludec (input [7:0] instr,
input [1:0] aluop,
output reg [3:0] alucontrol);
always @ (*) begin
	casex(instr)
	8'b0: alucontrol <= 4'b0000; // NOP
	8'b1000xxxx: alucontrol <= 4'b1000; // ADD
	8'b1001xxxx: alucontrol <= 4'b1001; // SUB
	8'b1010xxxx: alucontrol <= 4'b1010; // INAC
	8'b1011xxxx: alucontrol <= 4'b1011; // CLAC
	8'b1100xxxx: alucontrol <= 4'b1100; // AND
	8'b1101xxxx: alucontrol <= 4'b1101; // OR
	8'b1110xxxx: alucontrol <= 4'b1110; // XOR
	8'b1111xxxx: alucontrol <= 4'b1111; // NOT
	default: alucontrol <= 4'bxxxx; // ???
	endcase
end
endmodule

module alu (a,b,sel, out, zero);
    input [7:0] a,b;
    input [3:0] sel; 
    output reg [7:0] out;
	output reg zero;
  
  initial
  begin
  out = 0;
  zero =1'b0;
  end
    always @ (*) 
		case(sel) 
			4'b0000: begin
				out = a; 
				if (out == 0)
					zero = 1;  
				else
					zero = 0;
			end 
			4'b1000: begin
				out = a + b; 
				if (out == 0)
					zero = 1;  
				else
					zero = 0;
			end 
			4'b1001: begin
				out = a - b; 
				if (out == 0)
					zero = 1;  
				else
					zero = 0;
			end 
		4'b1010: begin
			out = a + 1; 
			if (out == 0)
				zero = 1;  
			else
			zero = 0;
		end 
		4'b1011: begin
			out = 0; 
			zero = 1;
		end 
		4'b1100: begin
			out = a & b; 
			if (out == 0)
				zero = 1;  
			else
				zero = 0;
		end 
		4'b1101: begin
			out = a | b; 
			if (out == 0)
				zero = 1;  
			else
				zero = 0;
	end
		4'b1110: begin
			out = a ^ b; 
			if (out == 0)
				zero = 1;  
			else
				zero = 0;
		end 
		4'b1111: begin
			out = ~a; 
			if (out == 0)
				zero = 1;  
			else
				zero = 0;
		end 
	endcase
endmodule

module adder (input [7:0] a, b, output [7:0] y);
assign y = a + b;
endmodule

module accumulator(input [7:0] result, 
				   input clk, we, clr, 
				   output reg [7:0] accout);
				   
	always @(posedge clk) begin
		if(clr == 1)
			accout <= 8'b0;
		else if(we == 1)
			accout <= result;
	end
endmodule

module top (input clk, reset, output [7:0] writedata, dataadr, pc_display, instr_display, acc_display, output memwrite);
wire [7:0] pc, instr, readdata, acc;
assign pc_display = pc;
assign instr_display = instr;
assign acc_display = acc;

// instantiate processor and memories
mips mips_dut (clk, reset, pc, instr, acc, memwrite, dataadr,
writedata, readdata);
imem imem_dut (pc[5:0], instr);
dmem dmem_dut (clk, memwrite, instr[3:0], acc, readdata);
endmodule

module sl2 (input [7:0] a, output [7:0] y);
// shift left by 2
assign y = {a[5:0], 2'b00};
endmodule

module signext (input [7:0] a,
output [7:0] y);
assign y = a;
endmodule

module regfile (input clk, input we3,
input [3:0] ra1, ra2, wa3,
input [7:0] wd3,
output [7:0] rd1, rd2);
reg [7:0] rf;

always @ (posedge clk)
	if (we3) rf <= wd3;
assign rd1 = rf;
assign rd2 = rf;
endmodule

module mux2 # (parameter WIDTH = 8)
(input [WIDTH-1:0] d0, d1, input s,
output [WIDTH-1:0] y);
assign y = s ? d1 : d0;
endmodule

module mips (input clk, reset,
output [7:0] pc,
input [7:0] instr, output[7:0] acc,
output memwrite,
output [7:0] aluout, writedata,
input [7:0] readdata);
wire accwe, memtoacc, branch, alusrc, regdst, regwrite, jump, regtoacc;
wire [3:0] alucontrol;
wire acc_reg_is_zero;
controller c(instr, zero, accwe, memtoacc, memwrite, pcsrc,
alusrc, regdst, regwrite, jump, regtoacc, alucontrol, acc_reg_is_zero);
datapath dp(clk, reset, accwe, memtoacc, pcsrc,
alusrc, regdst, regwrite, jump, regtoacc,
alucontrol,
zero, pc, instr, acc,
aluout, writedata, readdata, acc_reg_is_zero);
endmodule

module maindec (input [7:0] instr, output accwe, memtoacc, memwrite, output branch, alusrc,
output regdst, regwrite, output jump, output [1:0] aluop, output regtoacc, input acc_reg_is_zero);

reg [10:0] controls;
reg Z;

assign {accwe, regwrite, regdst, alusrc, branch, memwrite, memtoacc, jump, aluop, regtoacc}  = controls;
always @ (*) begin
	Z = ~acc_reg_is_zero;
	casex(instr)
		8'b0: controls <= 11'b0; // NOP
		8'b0001xxxx: controls <= 11'b10010010_00_0; // AC = M[T]
		8'b0010xxxx: controls <= 11'b00010100_00_0; // M[T] = AC
		8'b0011xxxx: controls <= 11'b01000000_00_0; // R = AC
		8'b0100xxxx: controls <= 11'b10000000_00_1; // AC = R
		8'b0101xxxx: controls <= 11'b00000001_00_0; // J to memory addr
		8'b0110xxxx: if(Z == 1) controls <= 11'b00000001_00_0; // JMPZ z == 1, jump to addr
					 else controls <= 11'b0;
		8'b0111xxxx: if(Z == 0) controls <= 11'b00000001_00_0; // JPNZ z == 0 jump to addr
					 else controls <= 11'b0;
		8'b1000xxxx: controls <= 11'b10010000_00_0; // ADD
		8'b1001xxxx: controls <= 11'b10010000_00_0; // SUB
		8'b1010xxxx: controls <= 11'b10010000_00_0; // INAC
		8'b1011xxxx: controls <= 11'b10010000_00_0; // CLAC
		8'b1100xxxx: controls <= 11'b10010000_00_0; // AND
		8'b1101xxxx: controls <= 11'b10010000_00_0; // OR
		8'b1110xxxx: controls <= 11'b10010000_00_0; // XOR
		8'b1111xxxx: controls <= 11'b10010000_00_0; // NOT
		default: controls <= 11'bx;
	endcase

end

endmodule

module imem (input [5:0] a, output [7:0] rd);
reg [7:0] RAM[63:0]; // limited memory
initial
begin
$readmemh ("memfile.dat",RAM);
end
assign rd = RAM[a]; // word aligned
endmodule

module testbench();
reg clk;
reg reset;
wire [7:0] writedata, dataadr, pc_display, instr_display, acc_display;
wire memwrite;
// instantiate device to be tested
top dut (clk, reset, writedata, dataadr, pc_display, instr_display, acc_display, memwrite);
// generate clock to sequence tests
// initialize test
initial
begin
reset <= 1; # 22; reset <= 0;
end
always
begin
clk <= 1;
 # 5; 
 clk <= 0;
 # 5; // clock duration
end
// check results
always @ (negedge clk)
begin
if (acc_display == 255 && writedata == 1 && dataadr == 255) begin
$display ("Simulation succeeded");
$stop;
end 
end
endmodule

