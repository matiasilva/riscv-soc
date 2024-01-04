// register file

module regfile (
	input         clk          ,
	input         rst_n        ,
	input  [ 4:0] rr1_i        , // read register 1
	input  [ 4:0] rr2_i        , // read register 2
	input  [ 4:0] wrr_i        , // write register
	input  [31:0] wrdata_i     ,
	input         is_regwrite_i,
	output [31:0] rdata1_o     ,
	output [31:0] rdata2_o
);

// we don't care about the contents of x[0]
// as we hard wire this to 0 on a read
// but the register still exists for simplicity
	reg [31:0] x [31:0];

	reg [31:0] next_rdata1;
	reg [31:0] next_rdata2;

	wire isrr1zero = !(|rr1_i);
	wire isrr2zero = !(|rr2_i);

	integer i;

	always @(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			for (i = 0; i < 32; i++) begin
				x[i] <= 32'b0;
			end
		end else begin
			if (is_writereg_i) begin
				x[wrr_i] <= wrdata_i;
			end else begin
				next_rdata1 <= x[rr1_i];
				next_rdata2 <= x[rr2_i];
			end
		end
	end

	assign rdata1_o = isrr1zero ? 32'b0 :  next_rdata1;
	assign rdata2_o = isrr2zero ? 32'b0 : next_rdata2;

endmodule