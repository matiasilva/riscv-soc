`timescale 1us / 1ns

`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value, expected %b, got %b", value, signal); \
            wavetext <= "FAILED"; \
            #(HCLK) $finish; \
        end

module demo_tb ();

	reg clk;
	reg rst_n;

	// module specific inputs and outputs here


	reg [1023:0] wavetext;
	integer scratch1;

	localparam CLK = 1;
	localparam HCLK = CLK * 0.5;
	localparam PDELAY = CLK * 0.001;
	localparam N_TESTS = 1000;


	// include duts here

	always #CLK clk = ~clk;

	initial begin
      	$dumpfile("demo_tb.vcd");
      	$dumpvars(0, demo_tb);

	end

	// include tasks here

	initial begin
      	clk <= 0;
      	rst_n <= 1;
      	wavetext <= "start of test";
      	$display("start of test");


      	$display("end of test");
		$finish;
	end

endmodule