/*
this can be implemented as BRAM on FPGA
*/

module instrmem #(
	parameter PRELOAD = 0,
	parameter PRELOAD_FILE = ""
) (
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
	input [31: 0] pc_i,
	output [31:0] instr_o
);

	localparam MEM_SIZE = 512;

	// 512 bytes, 128 words
	reg [7:0] mem [MEM_SIZE - 1:0];
	reg [31:0] next_instr;

	integer i;

	initial begin
		if (PRELOAD) begin
			@(posedge rst_n); // need two of these
			@(posedge rst_n);
			if (PRELOAD_FILE === "") begin
				$display("no preload file provided!");
				$finish;
			end
			$readmemh(PRELOAD_FILE,mem,0, 31);
		end
	end

	always @(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			for (i = 0; i < MEM_SIZE; i++) begin
				mem[i] <= 0;
			end
			next_instr <= 0;
		end else begin
			next_instr <= {mem[pc_i + 3], mem[pc_i + 2], mem[pc_i + 1], mem[pc_i]};
		end
	end

	assign instr_o = next_instr;

endmodule