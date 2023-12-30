/*
	this can be implemented as BRAM on FPGA
*/

module memory (
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
	input [31: 0] pc,
	output [31:0] instr
);

localparam MEM_SIZE = 512;

// 512 bytes, 128 words
reg [7:0] mem [MEM_SIZE - 1:0];
reg [31:0] next_instr;

integer i;

always @(posedge clk or negedge rst_n) begin : proc_
	if(~rst_n) begin
		for (i = 0; i < MEM_SIZE; i++) begin
			mem[i] <= 0;
		end
		next_instr <= 0;
	end else begin
		next_instr <= mem[pc+:4];
	end
end

assign instr = next_instr;

endmodule