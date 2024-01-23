`timescale 1ns / 10ps

`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value, expected %b, got %b", value, signal); \
            wavetext <= "FAILED"; \
            #(HCLK) $finish; \
        end

module core_tb;

	reg clk;
	reg rst_n;


	reg [1023:0] wavetext;
	integer scratch1;

	localparam CLK = 1;
	localparam HCLK = CLK * 0.5;
	localparam PDELAY = CLK * 0.001;
	localparam N_TESTS = 1000;

	// include duts here
	core core_u (
		.clk(clk),
		.rst_n(rst_n)
	);
	
	integer idx;	

	always #CLK clk = ~clk;

	initial begin
      	$dumpfile("build/core_tb.fst");
      	$dumpvars(0, core_tb);
      	for (idx = 0; idx < 2; idx = idx + 1) $dumpvars(0, core_u.instrmem_u.mem[idx]);
	end

	// include tasks here

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
      	$display("start of test");

      	init();
      	@(posedge clk);
      	wavetext <= "start of test";
      	#100;
      	$display("end of test");
		$finish;
	end

endmodule