/*
this can be implemented as BRAM on FPGA
*/

module memory #(
	parameter PRELOAD = 0,
	parameter PRELOAD_FILE = ""
) (
	input clk,
	input rst_n,
	input is_memread_i,
	input is_memwrite_i,
	input [31: 0] addr_i,
	input [31:0] wdata_i,
	output [31:0] rdata_o
);

	localparam MEM_SIZE = 512;

	// 512 bytes, 128 words
	reg [7:0] mem [MEM_SIZE - 1:0];
	reg [31:0] next_rdata;

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
			next_rdata <= 0;
		end else begin
			if (is_memread_i) begin
				next_rdata <= {mem[addr_i + 3], mem[addr_i + 2], mem[addr_i + 1], mem[addr_i]};
			end 
			if (is_memwrite_i) begin
				for (i = 0; i < 4; i++) begin
					mem[addr_i + i] <= wdata_i[i +: 8];
				end
			end
		end
	end

	assign rdata_o = next_rdata;

endmodule