`timescale 1us / 1ns

`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value, expected %b, got %b", value, signal); \
            wavetext <= "FAILED"; \
            #(HCLK) $finish; \
        end

module alu_tb ();

	reg clk;
	reg rst_n;
	reg [31:0] a;
	reg [31:0] b;
	reg [3:0] op;

	wire [31:0] out;
	reg [31:0] result;

	reg [1023:0] wavetext;
	integer scratch1;

	localparam CLK = 1;
	localparam HCLK = CLK * 0.5;
	localparam PDELAY = CLK * 0.001;
	localparam N_TESTS = 1000;

	alu dut (
		.clk (clk),
		.a (a),
		.b (b),
		.op (op),
		.out (out)
	);

	always #CLK clk = ~clk;

	initial begin
      	$dumpfile("alu_tb.vcd");
      	$dumpvars(0, alu_tb);

	end

	task test_add();
		begin
			#(HCLK);
			wavetext <= "testing ADD operation";
			for (integer i = 0; i < N_TESTS; i++) begin
				a <= $urandom;
				b <= $urandom;
				op <= 4'b0000;

				#(PDELAY) result <= out;
				#(PDELAY) `assert(result, (a+b));
				#(CLK);
			end
		end		
	endtask 

	task test_sub();
		begin
			#(HCLK);
			wavetext <= "testing SUB operation";
			for (integer i = 0; i < N_TESTS; i++) begin
				a <= $urandom;
				b <= $urandom;
				op <= 4'b1000;

				#(PDELAY) result <= out;
				#(PDELAY) `assert(result, (a-b));
				#(CLK);
			end
		end		
	endtask 

	task test_slt();
		begin
			#(HCLK);
			wavetext <= "testing SLT operation";
			for (integer i = 0; i < N_TESTS; i++) begin
				a <= $urandom;
				b <= $urandom;
				op <= 4'b0010;

				#(PDELAY) result <= out;
				#(PDELAY) `assert(result, ($signed(a)<$signed(b)));
				#(CLK);
			end
		end		
	endtask 

	task test_sltu();
		begin
			#(HCLK);
			wavetext <= "testing SLTU operation";
			for (integer i = 0; i < N_TESTS; i++) begin
				a <= $urandom;
				b <= $urandom;
				op <= 4'b0011;

				#(PDELAY) result <= out;
				#(PDELAY) `assert(result, (a<b));
				#(CLK);
			end
		end		
	endtask 

	task test_and();
		begin
			#(HCLK);
			wavetext <= "testing AND operation";
			for (integer i = 0; i < N_TESTS; i++) begin
				a <= $urandom;
				b <= $urandom;
				op <= 4'b0111;

				#(PDELAY) result <= out;
				#(PDELAY) `assert(result, (a&b));
				#(CLK);
			end
		end		
	endtask 

	task test_or();
		begin
			#(HCLK);
			wavetext <= "testing OR operation";
			for (integer i = 0; i < N_TESTS; i++) begin
				a <= $urandom;
				b <= $urandom;
				op <= 4'b0110;

				#(PDELAY) result <= out;
				#(PDELAY) `assert(result, (a|b));
				#(CLK);
			end
		end		
	endtask 

	task test_xor();
		begin
			#(HCLK);
			wavetext <= "testing XOR operation";
			for (integer i = 0; i < N_TESTS; i++) begin
				a <= $urandom;
				b <= $urandom;
				op <= 4'b0100;

				#(PDELAY) result <= out;
				#(PDELAY) `assert(result, (a^b));
				#(CLK);
			end
		end		
	endtask 

	task test_sll();
		begin
			#(HCLK);
			wavetext <= "testing SLL operation";
			for (integer i = 0; i < N_TESTS; i++) begin
				a <= $urandom;
				b <= $urandom;
				op <= 4'b0001;

				#(PDELAY) result <= out;
				#(PDELAY) `assert(result, (a<<b[4:0]));
				#(CLK);
			end
		end		
	endtask 

	task test_srl();
		begin
			#(HCLK);
			wavetext <= "testing SRL operation";
			for (integer i = 0; i < N_TESTS; i++) begin
				a <= $urandom;
				b <= $urandom;
				op <= 4'b0101;

				#(PDELAY) result <= out;
				#(PDELAY) `assert(result, (a>>b[4:0]));
				#(CLK);
			end
		end		
	endtask 

	task test_sra();
		begin
			#(HCLK);
			wavetext <= "testing SRA operation";
			for (integer i = 0; i < N_TESTS; i++) begin
				a <= $urandom;
				b <= $urandom;
				op <= 4'b1101;

				#(PDELAY) result <= out;
				#(PDELAY) scratch1 = (($signed(a)) >>> (b[4:0]));
				#(PDELAY) `assert(result, scratch1);
				#(CLK);
			end
		end		
	endtask 

	initial begin
		a <= 0;
		b <= 0;
		op <= 0;
		result <= 0;
      	clk <= 0;
      	rst_n <= 1;
      	wavetext <= "start of test";

		test_add();
		test_sub();
		test_slt();
		test_sltu();
		test_and();
		test_or();
		test_xor();
		test_sll();
		test_srl();
		test_sra();

		$finish;
	end

endmodule