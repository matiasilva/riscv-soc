// register file

module regfile (
	input clk, 
	input rst_n,
	input [4:0] rr1, // read register 1
	input [4:0] rr2, // read register 2
	input [4:0] wrr, // write register
	input [31:0] wrdata,
	output [31:0] rdata1,
	output [31:0] rdata2
);

reg [31:0] x [31:0];

integer i;

always @(posedge clk or negedge rst_n) begin :
	if(~rst_n) begin
		for (i = 0; i < 32; i++) begin
			x[i] <= 32'b0;
		end
	end else begin

	end
end

endmodule