`timescale 1ps/1ps

module hbram_ctrl(
);

`define hram	1
//`define opi		1

localparam CA_Bits		= 0;
localparam LA_Bits	    = 1;
localparam DQ_Bits		= 2;

reg [1:0] state = 2'h0;
integer count = 0;
reg start = 1'b0;
reg start_clk = 1'b0;
reg CSNeg_tmp = 1'b1;
reg sys_clk = 1'b0;
reg hb_clk_tmp = 1'b0;
reg [7:0] buffer [0:1023];
reg [7:0] read_buffer [0:1023];
localparam td	= 10;
integer end_count = 7'd36;
reg data_strb_p_tmp;
reg data_strb_n_tmp;
reg [7:0] Dout_zd_p;
reg [7:0] Dout_tmp;
reg [7:0] Dout_zd_n;
reg data_strb_n;
reg data_strb_p;
reg pause = 1'b0;
reg [5:0] pause_count = 0;
reg rwds_sel = 1'b0;
reg rwds_tmp = 1'bz;
reg [5:0] latency = 6'd14;
reg reset_neg = 1'b1;
reg rwds_in = 1'bz;

`ifdef opi
reg reg_write = 1'b0;
reg mem_write = 1'b0;
`endif

integer read_count = 0;
integer sys_clk_period = 500; 
integer sys_count;
integer period_cnt;

integer freq = 2500;
integer tdsv = 12000;
integer tdsz = 7000;
integer tIS = 600;
integer tCSH = 10000;
integer tCSS = 3000;

wire [7:0] Dout;
wire rwds,CSNeg,hb_clk;

assign Dout = Dout_tmp;
assign rwds = rwds_tmp;
assign hb_clk = hb_clk_tmp;
assign CSNeg = CSNeg_tmp;

`ifdef hram
s27kl0642 dut(
    .DQ7(Dout[7])      ,
    .DQ6(Dout[6])      ,
    .DQ5(Dout[5])      ,
    .DQ4(Dout[4])      ,
    .DQ3(Dout[3])      ,
    .DQ2(Dout[2])      ,
    .DQ1(Dout[1])      ,
    .DQ0(Dout[0])      ,
    .RWDS(rwds)     ,

    .CSNeg(CSNeg)    ,
    .CK(hb_clk)       ,
	.CKn(1'b0)		,
    .RESETNeg(reset_neg)
    );
`elsif opi
s27kl0643 dut(
    .DQ7(Dout[7])      ,
    .DQ6(Dout[6])      ,
    .DQ5(Dout[5])      ,
    .DQ4(Dout[4])      ,
    .DQ3(Dout[3])      ,
    .DQ2(Dout[2])      ,
    .DQ1(Dout[1])      ,
    .DQ0(Dout[0])      ,
    .RWDS(rwds)     ,

    .CSNeg(CSNeg)    ,
    .CK(hb_clk)       ,
    .RESET(1'b1)
    );
`endif
	
always @(posedge start)
begin
	period_cnt = freq/sys_clk_period;
end

always 
begin
	#sys_clk_period sys_clk <= ~sys_clk;
end

always @(CSNeg_tmp || hb_clk_tmp)
begin
	if(!start_clk) begin
		count <= 0;
	end else if(pause) begin
		count <= count;
	end else begin
		count <= count + 1;
	end
end

always @(start_clk)//sys_clk)
begin
	if(count == end_count)begin
		start <= 1'b0;
	end
end

always @(start or count)//sys_clk)
begin
	if(!start) begin
		start_clk <= 1'b0;
	end else if(count == end_count) begin
		start_clk <= 1'b0;
	end else if(count == 0)begin
		start_clk <= #(tCSS) 1'b1;
	end 
end

always @(sys_clk)
begin
	if(start_clk)begin
		sys_count = sys_count+1;
	end else begin
		sys_count = 0;
	end
end

always @(sys_clk)
begin
	if(start_clk) begin
		if(sys_count%period_cnt == 0)begin
			hb_clk_tmp <= ~hb_clk_tmp;
		end
	end else begin
		hb_clk_tmp <= 1'b0;
	end
end

always @(start)//sys_clk)
begin
	if(!start) begin
		CSNeg_tmp <= #tCSH 1'b1;
	end else begin
		CSNeg_tmp <= 1'b0;
	end
end

always @(negedge CSNeg_tmp or negedge hb_clk_tmp)
begin
	data_strb_p_tmp <= 1'b1;
	#5 data_strb_p_tmp <= 1'b0;
	
	//data_strb_p <= #(freq - tIS) data_strb_p_tmp;
end

always @(posedge hb_clk_tmp)
begin
	data_strb_n_tmp <= 1'b1;
	#5 data_strb_n_tmp <= 1'b0;
	
	//data_strb_n <= #(freq - tIS) data_strb_n_tmp;
end

always @(data_strb_p_tmp)
begin
	data_strb_p <= #(freq - tIS) data_strb_p_tmp;
end

always @(data_strb_n_tmp)
begin
	data_strb_n <= #(freq - tIS) data_strb_n_tmp;
end

always @(posedge data_strb_p or posedge data_strb_n or rwds_sel)
begin
	if(rwds_sel)begin	
		Dout_tmp <= 8'hz;
	end else if(data_strb_p)begin
		Dout_tmp <= Dout_zd_p;
	end else if(data_strb_n) begin
		Dout_tmp <= Dout_zd_n;
	end
end

always @(data_strb_p_tmp)
begin
	Dout_zd_p <= buffer[count];
end

always @(data_strb_n_tmp)
begin
	Dout_zd_n <= buffer[count];
end

always @(sys_clk)
begin
	if(CSNeg_tmp)begin
		rwds_sel <= 1'b0;
`ifdef hram
	end else if(buffer[0][7])begin
		rwds_sel <= dut.rwds_enable;
	end
`elsif opi
	end else if(count == 6'h20 && !mem_write)begin
		rwds_sel <= 1'b1;
	end
`endif
	
	if(CSNeg_tmp)begin
		rwds_tmp <= 1'bz;
`ifdef hram
	end else if(count == 6'h6 && !buffer[0][7] && buffer[0][6])begin
		rwds_tmp <= 1'b0;
	end else if(count == (latency+4) && !buffer[0][7] && !buffer[0][6])begin
		rwds_tmp <= 1'b0;
	end
`elsif opi
	end else if(count == 6'h6 && reg_write) begin
		rwds_tmp <= 1'b0;
	end else if(count == (latency+4) && mem_write)begin
		rwds_tmp <= 1'b0;
	end
`endif
end

always @(rwds)
begin
	rwds_in <= #2 rwds;
	
	if(CSNeg_tmp)begin
		read_count <= 0;
	end else if(rwds_sel) begin
		read_count <= #3 read_count + 1;
	end
end

always @(rwds_in)
begin
	if(rwds_sel)begin
		read_buffer[read_count] <= Dout;
	end
end

always @(sys_clk)
begin
	if(CSNeg_tmp)begin
		pause = 0;
	end else if(pause && (pause_count == latency))begin
		pause = 0;
	end else if(count == 6 && rwds_in && buffer[0][7])begin
		pause = 1;
	end else if(count == 6 && rwds_in && !buffer[0][6] && !buffer[0][7])begin
		pause = 1;
	end
end

always @(hb_clk_tmp)
begin
	if(count == 1)begin
		pause_count = 0;
	end else if(pause) begin
		pause_count = pause_count+1;
	end
end
endmodule

