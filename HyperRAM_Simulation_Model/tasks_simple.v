
//this file contains all the tasks for Read/Write operation

task init;
begin
	BurstLength[0] = 8'd64;
	BurstLength[1] = 8'd32;
	BurstLength[2] = 8'd8;
	BurstLength[3] = 8'd16;
	
	Latency[5] = 4'h0;
	Latency[6] = 4'h1;
	Latency[7] = 4'h2;
	Latency[3] = 4'hE;
	Latency[4] = 4'hF;
end
endtask

task check_write;
input [31:0] address;
input integer count;
input wrap;
input integer wrap_length;
input hybrid;
begin:m
	reg [31:0] start_addr;
	addr = 0;
	fail = 0;
	start_addr = address;
	while(addr < count)begin
		if({ctrl.buffer[4+ctrl.latency+addr],ctrl.buffer[4+ctrl.latency+addr+1]} != ctrl.dut.Mem[address])begin
			$display("failed @ %x for data %x (%x)",address,{ctrl.buffer[4+ctrl.latency+addr],ctrl.buffer[4+ctrl.latency+addr+1]},ctrl.dut.Mem[address]);
			fail = fail+1;
		end
		address = address+1;
		if((address%wrap_length) == 0 && address != 0 && wrap)begin
			address = address - wrap_length;
			if(hybrid)begin
				wrap = 0;
			end
		end else if(address == start_addr && hybrid) begin
			address = address - (address%wrap_length) + wrap_length;
		end
		addr = addr+2;
	end
	if(fail>0)begin
		total_fail = total_fail+1;
	end else begin
		total_pass = total_pass+1;
	end
		total_count = total_count+1;
	
	$display("\tPASS = %d (%d p)\n\tFAIL = %d (%d p)",count/2-fail,(count/2-fail)*200/count,fail,fail*200/count);
end
endtask

task check_read;
input [31:0] address;
input integer count;
input wrap;
input integer wrap_length;
input hybrid;
input valid;
begin:m
	reg [31:0] start_addr;
	addr = 0;
	fail = 0;
	start_addr = address;
	while(addr < count)begin
		if(valid && ({ctrl.buffer[4+ctrl.latency+addr],ctrl.buffer[4+ctrl.latency+addr+1]} != {ctrl.read_buffer[addr],ctrl.read_buffer[addr+1]}))begin
			$display("failed @ %x for data %x (%x)",address,{ctrl.buffer[4+ctrl.latency+addr],ctrl.buffer[4+ctrl.latency+addr+1]},{ctrl.read_buffer[addr],ctrl.read_buffer[addr+1]});
			fail = fail+1;
		end
		if(!valid && (32'hxx != {ctrl.read_buffer[addr],ctrl.read_buffer[addr+1]}))begin
			$display("failed @ %x for data %x (%x)",address,{ctrl.buffer[4+ctrl.latency+addr],ctrl.buffer[4+ctrl.latency+addr+1]},{ctrl.read_buffer[addr],ctrl.read_buffer[addr+1]});
			fail = fail+1;
		end
		address = address+1;
		if((address%wrap_length) == 0 && address != 0 && wrap)begin
			address = address - wrap_length;
			if(hybrid)begin
				wrap = 0;
			end
		end else if(address == start_addr && hybrid) begin
			address = address - (address%wrap_length) + wrap_length;
		end
		addr = addr+2;
	end
	if(fail>0)begin
		total_fail = total_fail+1;
	end else begin
		total_pass = total_pass+1;
	end
		total_count = total_count+1;
	$display("\tPASS = %d (%d p)\n\tFAIL = %d (%d p)",count/2-fail,(count/2-fail)*200/count,fail,fail*200/count);
end
endtask

/*
task write_reg: 
	reads the device registers using hyperBus interface and printout the read value. 
	arguments: 
		INPUT:
			name --> name of the register
			ADDR --> register Address 
			value --> 16 bit data for register
		OUTPUT:
			None
*/
task Write_reg;
input [8*3:1] name;
input [15:0] ADDR;
input [15:0] value;
begin
	fork: f
	begin
		ctrl.end_count = 8;
		ctrl.buffer[0] = 8'h60;
		ctrl.buffer[1] = 8'h00;
		ctrl.buffer[2] = {3'h0,ADDR[15:11]};
		ctrl.buffer[3] = ADDR[10:3];
		ctrl.buffer[4] = 8'h00;
		ctrl.buffer[5] = {6'h0,ADDR[1:0]};
		ctrl.buffer[6] = value[15:8];
		ctrl.buffer[7] = value[7:0];
		
		ctrl.start = 1'b1;
	end
	begin
		@(posedge ctrl.CSNeg_tmp);
		disable f;
	end join
		$display("%s updated",name);
end
endtask

/*
task Read_reg: 
	reads the device registers using hyperBus interface and printout the read value. 
	arguments: 
		INPUT:
			name --> name of the register
			ADDR --> register Address 
		OUTPUT:
			None
*/
task Read_reg;
input [8*3:1] name;
input [15:0] ADDR;
begin
	fork: f
	begin
		ctrl.end_count = 4+ctrl.latency+2;
		ctrl.buffer[0] = 8'hC0;
		ctrl.buffer[1] = 8'h00;
		ctrl.buffer[2] = {3'h0,ADDR[15:11]};
		ctrl.buffer[3] = ADDR[10:3];
		ctrl.buffer[4] = 8'h00;
		ctrl.buffer[5] = {6'h0,ADDR[1:0]};
		
		ctrl.start = 1'b1;
	end
	begin
		@(posedge ctrl.CSNeg_tmp);
		disable f;
	end join
		$display("%s = %x",name,{ctrl.read_buffer[0],ctrl.read_buffer[1]});
end
endtask

/*
task LinearBurstWrite:
	this task can be used to perform a Linear burst write into the memory array. 
	Arguments:
		INPUT:
			address			--> start address
			count			--> burst length (integer)
			wrap			--> 1=wrap 0=linear
			wrap_length		--> wrap length
			hybrid			--> 1= hybrid, 0=no hybrid
		OUTPUT:
*/
task BurstWrite;
input [31:0] address;
input integer count;
input wrap;
input integer wrap_length;
input hybrid;

begin:s
	reg [31:0] start_addr;
	reg wrap_tmp;
	fork:w
	begin
		//init_buffer();
		addr = 0;
		wrap_tmp = wrap;
		start_addr = address;
		ctrl.end_count = count + 4+ ctrl.latency;
		ctrl.buffer[0] = {2'h0,!wrap,address[31:27]};
		ctrl.buffer[1] = address[26:19];
		ctrl.buffer[2] = address[18:11];
		ctrl.buffer[3] = address[10:3];
		ctrl.buffer[4] = 8'h00;
		ctrl.buffer[5] = {5'h00,address[2:0]};
		//Filling the buffer with write data
		while(addr<count)begin
			ctrl.buffer[addr+4+ctrl.latency] = address[15:8];
			ctrl.buffer[addr+4+ctrl.latency+1] = address[7:0];
			address = address+1;
			if(address != 0 && address%wrap_length == 0 && wrap)begin
				address = address - wrap_length;
				if(hybrid)begin
					wrap = 1'b0;
				end
			end else if(address == start_addr && hybrid)begin
				address = (address - (address%wrap_length))+wrap_length;
			end
			addr = addr+2;
		end
		ctrl.start = 1'b1;
	end
	begin
		@(posedge ctrl.CSNeg_tmp);
		disable w;
	end
	join
		$display("Wrapped Burst Write complete: ");
		check_write(start_addr,count,wrap_tmp,wrap_length,hybrid);
end
endtask

/*
task LinearBurstWrite:
	this task can be used to perform a Linear burst write into the memory array. 
	Arguments:
		INPUT:
			address			--> start address
			count			--> burst length (integer)
			wrap			--> 1=wrap 0=linear
			wrap_length		--> wrap length
			hybrid			--> 1= hybrid, 0=no hybrid
		OUTPUT:
*/
task BurstRead;
input [31:0] address;
input integer count;
input wrap;
input integer wrap_length;
input hybrid;

begin:s
	reg [31:0] start_addr;
	reg wrap_tmp;
	fork:w
	begin
		//init_buffer();
		addr = 0;
		wrap_tmp = wrap;
		start_addr = address;
		ctrl.end_count = count + 4+ ctrl.latency;
		ctrl.buffer[0] = {1'h1,1'h0,!wrap,address[31:27]};
		ctrl.buffer[1] = address[26:19];
		ctrl.buffer[2] = address[18:11];
		ctrl.buffer[3] = address[10:3];
		ctrl.buffer[4] = 8'h00;
		ctrl.buffer[5] = {5'h00,address[2:0]};
		//Filling the buffer with write data
		while(addr<count)begin
			ctrl.buffer[addr+4+ctrl.latency] = address[15:8];
			ctrl.buffer[addr+4+ctrl.latency+1] = address[7:0];
			address = address+1;
			if(address != 0 && address%wrap_length == 0 && wrap)begin
				address = address - wrap_length;
				if(hybrid)begin
					wrap = 1'b0;
				end
			end else if(address == start_addr && hybrid)begin
				address = (address - (address%wrap_length))+wrap_length;
			end
			addr = addr+2;
		end
		ctrl.start = 1'b1;
	end
	begin
		@(posedge ctrl.CSNeg_tmp);
		disable w;
	end
	join
		$display("Burst Read complete: ");
		check_read(start_addr,count,wrap_tmp,wrap_length,hybrid,1);
end
endtask