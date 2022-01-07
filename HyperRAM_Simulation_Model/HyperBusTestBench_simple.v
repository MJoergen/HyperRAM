`timescale 1ps/1ps
/*
********************************************************************************************************************************************************************************************************************************************************HyperRam Testbench**********************************************************************************************
************************************************************************************************************************************************************************************
*/
module test_bench;
integer start_time = 0;
reg latency = 6'hE;
reg [15:0] ID0_ADDR = 16'h0000;
reg [15:0] ID1_ADDR = 16'h0001;
reg [15:0] CR0_ADDR = 16'h0800;
reg [15:0] CR1_ADDR = 16'h0801;
reg wrap = 1'b1;//Linear = 1 wrapped = 0
integer addr = 0;
integer BurstLength[0:3];
integer Latency[0:15];
integer fail = 0;
integer total_fail = 0;
integer total_pass = 0;
integer total_count = 0;
hbram_ctrl ctrl();

`include "../tasks_simple.v"

initial
begin
$display("starting the Test");
#350e6;
init();
ctrl.freq = 3000;
#10000;

//Reading Device ID0
Read_reg("ID0",ID0_ADDR);
#100000;
//Reading Device ID1
Read_reg("ID1",ID1_ADDR);
#100000;
//Reading the CR0 and CR1 
Read_reg("CR0",CR0_ADDR);
#100000;
Read_reg("CR1",CR1_ADDR);
#100000;


//Linear Burst Write
//			address,	count,	wrap,	wrap_length,	hybrid)
BurstWrite(	0,			40,		0,		0,				0);

#50000;

//Wrapped Burst Write
//			address,	count,	wrap,	wrap_length,	hybrid)
BurstWrite(	5,			32,		1,		16,				0);

#50000;

//Hybrid Write
//enabling hybrid burst by writting CR0[2] = 0
//			name	reg address		value
Write_reg(	"CR0",	CR0_ADDR,		16'h8f2b);

#70000;
//			address,	count,	wrap,	wrap_length,	hybrid)
BurstWrite(	5,			128,	1,		16,				1);

#50000;

//disabling hybrid burst
//			name	reg address		value
Write_reg(	"CR0",	CR0_ADDR,		16'h8f2f);

#50000;

//Linear burst Read
//			address,	count,	wrap,	wrap_length,	hybrid)
BurstRead(	0,			40,		0,		0,				0);

#50000;

//Wrapped Burst Read
//			address,	count,	wrap,	wrap_length,	hybrid)
BurstRead(	5,			32,		1,		16,				0);

#50000;

//Hybrid burst Read
//enabling hybrid burst by writting CR0[2] = 0
//			name	reg address		value
Write_reg(	"CR0",	CR0_ADDR,		16'h8f2b);

#50000;

//			address,	count,	wrap,	wrap_length,	hybrid)
BurstRead(	5,			128,	1,		16,				1);

#50000;

$finish;
end

endmodule

