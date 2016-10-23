module processor;
reg [31:0] pc; //32-bit prograom counter
reg clk; //clock
reg [7:0] datmem[0:31],mem[0:31]; //32-size data and instruction memory (8 bit(1 byte) for each location)
wire [31:0] 
dataa,	//Read data 1 output of Register File
datab,	//Read data 2 output of Register File
out2,		//Output of mux with ALUSrc control-mult2
out3,		//Output of mux with MemToReg control-mult3
out4,		//Output of mux with (Branch&ALUZero) control-mult4
out6,
out7,
sum,		//ALU result
extad,	//Output of sign-extend unit
zextad,
adder1out,	//Output of adder which adds PC and 4-add1
adder2out,	//Output of adder which adds PC+4 and 2 shifted sign-extend result-add2
test3,
test4,
test5,
test6,
test7,
test8,
shift_pc,
sextad;	//Output of shift left 2 unit

wire [27:0] shextad;
wire [25:0] inst25_0;
wire [5:0] inst31_26;	//31-26 bits of instruction
wire [4:0] 
inst25_21,	//25-21 bits of instruction
inst20_16,	//20-16 bits of instruction
inst15_11,	//15-11 bits of instruction
out1,		//Write data input of Register File
out5;

wire [4:0] inst10_6;	//10-6 bits of instruction for shift amount

wire [15:0] inst15_0;	//15-0 bits of instruction

wire [31:0] instruc,	//current instruction
dpack;	//Read data output of memory (data read from memory)

wire [2:0] gout;	//Output of ALU control unit

wire zout,	//Zero output of ALU
pcsrc,	//Output of AND gate with Branch and ZeroOut inputs
select_t,
select_mem,
//Control signals
regdest,alusrc,memtoreg,regwrite,memread,memwrite,branch,bmv,aluop3,aluop2,aluop1,aluop0,baln,baln_out,bneal_out,jalpc,select_ori,ori,blez,bneal,balrn,ne;

wire [2:0] selectmux;

//32-size register file (32 bit(1 word) for each register)
reg [31:0] registerfile[0:31];
wire [2:0] statusregister,stwire, st1_in, st1_st2, st2_out;
reg [2:0] st1=3'b000, st2=3'b000, st2_neg=3'b000, st1_neg=3'b000;
integer i;

reg statu;
// datamemory connections

always @(posedge clk)
//write data to memory
if (memwrite)
begin 
//sum stores address,datab stores the value to be written
datmem[sum[4:0]+3]=datab[7:0];
datmem[sum[4:0]+2]=datab[15:8];
datmem[sum[4:0]+1]=datab[23:16];
datmem[sum[4:0]]=datab[31:24];
end

//instruction memory
//4-byte instruction
 assign instruc={mem[pc[4:0]],mem[pc[4:0]+1],mem[pc[4:0]+2],mem[pc[4:0]+3]};
 assign inst25_0=instruc[25:0];
 assign inst31_26=instruc[31:26];
 assign inst25_21=instruc[25:21];
 assign inst20_16=instruc[20:16];
 assign inst15_11=instruc[15:11];
 assign inst15_0=instruc[15:0];
 assign inst10_6=instruc[10:6];


// registers

assign dataa=registerfile[inst25_21];//Read register 1
assign datab=registerfile[inst20_16];//Read register 2
always @(posedge clk)
 registerfile[out5]= regwrite ? out6:registerfile[out5];//Write data to register

//read data from memory, sum stores address
assign dpack={datmem[sum[5:0]],datmem[sum[5:0]+1],datmem[sum[5:0]+2],datmem[sum[5:0]+3]};

//always @ ( posedge clk)
// begin	
// statu=0;
// end
//multiplexers
//mux with RegDst control
mult2_to_1_5  mult1(out1, instruc[20:16],instruc[15:11],regdest);

mult2_to_1_5  mult1_1(out5, out1,5'b11111,select_t);

//mux with ALUSrc control
mult2_to_1_32 mult2(out2, datab,extad,alusrc);

mult2_to_1_32 mult6(out7, out2,zextad,select_ori);

//mux with MemToReg control
mult2_to_1_32 mult3(out3, sum,dpack,memtoreg);

mult2_to_1_32 mult5(out6, out3,adder1out,select_mem);

//mux with (Branch&ALUZero) control
//mult2_to_1_32 mult4(out4, adder1out,adder2out,pcsrc);

mult8_to_1_32 mult4(out4, adder1out,adder2out,dpack,shift_pc,dataa,test6,test7,test8,selectmux);

// load pc
always @(negedge clk)
pc=out4;



always @(negedge clk)
begin
	 st2 = st1;
	assign st1 = statusregister;
end

//assign stwire[2:0]=st[2:0];
// alu, adder and control logic connections


//adder which adds PC and 4
adder add1(pc,32'h4,adder1out);

//adder which adds PC+4 and 2 shifted sign-extend result
adder add2(adder1out,sextad,adder2out);
assign ne=(|(dataa+1+(~datab)));
//Control unit
control cont(instruc[31:26],regdest,alusrc,memtoreg,regwrite,memread,memwrite,branch,bmv,baln,jalpc,blez,bneal,balrn,
aluop3,aluop2,aluop1,aluop0,ori,instruc[5:0],ne);
//ALU unit
alu32 alu1(sum,dataa,out7,inst10_6,zout,statusregister[2:0],gout);
//Sign extend unit
signext sext(instruc[15:0],extad);

zeroext zext(instruc[15:0],zextad);

//ALU control unit
alucont acont(aluop3,aluop2,aluop1,aluop0,instruc[3],instruc[2], instruc[1], instruc[0] ,gout);

//Shift-left 2 unit
shift shift2(sextad,extad);

shift_28 shift2_ex(shextad,instruc[25:0]);		
assign shift_pc[27:0] = shextad[27:0];
assign shift_pc[31:28] = adder1out[31:28];

j_b_control jb_control(branch,bmv,baln,jalpc,blez,bneal,balrn,dataa,datab,st2,baln_out,bneal_out,selectmux,st2_neg);
//AND gate
//assign pcsrc=branch && zout; 
//assign select_t=baln_out|bneal_out; 
//assign select_t=baln_out; 

assign select_t= (baln & st2[1]) ? 1 : 
		  (bneal) ? 1 : 0; 
//assign select_mem=baln_out; 
//assign select_mem=baln_out|jalpc|bneal_out|balrn; 
assign select_mem= (baln & st2[1]) ? 1 :
			(bneal) ? 1: 
			(jalpc) ? 1: 
			(balrn & st2 [1]) ? 1: 0; 

assign select_ori=ori;
//always @ ( negedge clk)
// begin	
// statu=1;
 //end
//initialize datamemory,instruction memory and registers
//read initial data from files given in hex
initial
begin
$readmemh("initdata.dat",datmem); // byte by byte
$readmemh("init.dat",mem);// byte by byte
$readmemh("initreg.dat",registerfile);// word by word

	for(i=0; i<31; i=i+1)
	$display("Instruction Memory[%0d]= %h  ",i,mem[i],"Data Memory[%0d]= %h   ",i,datmem[i],
	"Register[%0d]= %h",i,registerfile[i]);
end

initial
begin
pc=0;
#4000 $finish;
	
end
initial
begin
clk=0;
//40 time unit for each cycle
forever #100  clk=~clk;
end
initial 
begin
  $monitor($time,"mux %h",selectmux,",st %h%h%h",st2[2],st2[1],st2[0],"Pla %h%h%h",statusregister[2],statusregister[1],statusregister[0],"PC %h",pc,"  SUM %h",sum,"   INST %h",instruc[31:0],
"   REGISTER %h %h %h %h ",registerfile[31],registerfile[20], registerfile[2],registerfile[1] );
end
endmodule

