// register file

module regfile (
	input clk, 
	input rst_n,
	input [4:0] rr1, // read register 1
	input [4:0] rr2, // read register 2
	input [4:0] wrr, // write register
	input [31:0] wrdata,
	input wr_en,
	output [31:0] rdata1,
	output [31:0] rdata2
);

// we don't care about the contents of x[0]
// as we hard wire this to 0 on a read
// but the register still exists for simplicity
reg [31:0] x [31:0];

reg [31:0] next_rdata1;
reg [31:0] next_rdata2;

wire isrr1zero = !(|rr1);
wire isrr2zero = !(|rr2);

integer i;

always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		for (i = 0; i < 32; i++) begin
			x[i] <= 32'b0;
		end
	end else begin
		if (wr_en) begin
			x[wrr] <= wrdata;
		end else begin
			next_rdata1 <= x[rr1];
			next_rdata2 <= x[rr2];
		end
	end
end

assign rdata1 = isrr1zero ? 32'b0 :  next_rdata1;
assign rdata2 = isrr2zero ? 32'b0 : next_rdata2;

endmodule