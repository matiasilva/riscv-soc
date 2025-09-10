`timescale 1us / 1ns

`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value, expected %x, got %x", value, signal); \
            wavetext <= "FAILED"; \
            #(HCLK) $finish; \
        end

module insnmem_tb ();

	reg clk;
	reg rst_n;

	reg [31:0] pc;
	wire [31:0] instr;
	reg [31:0] loaded_instr;
	reg [7:0] check_mem [MEM_SIZE - 1:0];

	reg [1023:0] wavetext;
	integer scratch1;
	reg [31:0] scratch2;

	localparam CLK = 1;
	localparam HCLK = CLK * 0.5;
	localparam PDELAY = CLK * 0.001;
	localparam N_TESTS = 1000;

	localparam MEM_SIZE = 32;

	// include duts here
	memory #(.PRELOAD(1), .PRELOAD_FILE("dummy_mem.hex")) dut (
		.clk  (clk),
		.rst_n(rst_n),
		.pc   (pc),
		.instr(instr)
	);

	always #CLK clk = ~clk;

	initial begin
      	$dumpfile("memory_tb.vcd");
      	$dumpvars(0, memory_tb);
	end

	initial begin
		$readmemh("dummy_mem.hex", check_mem, 0, 31);
	end

	// include tasks here

	task check_data();
		begin
			for (scratch1 = 0; scratch1 < MEM_SIZE / 4; scratch1++) begin
				@(posedge clk);
				$display("pc: %d",pc);
				#PDELAY loaded_instr <= instr;
				scratch2 <= {check_mem[pc + 3], check_mem[pc + 2], check_mem[pc + 1], check_mem[pc]};
				#PDELAY `assert(loaded_instr, scratch2);
				pc <= pc + 4;
			end

		end
	endtask

	task init();
		begin
			#HCLK rst_n <= 0;
			#HCLK rst_n <= 1;
			#HCLK;
		end
	endtask

	initial begin
      	clk <= 0;
      	rst_n <= 1;
      	pc <= 0;
      	loaded_instr <= 0;
      	$display("start of test");


      	init();
      	@(posedge clk);
      	wavetext <= "start of test";
      	check_data();
      	@(posedge clk);
      	$display("end of test");
		$finish;
	end

endmodule