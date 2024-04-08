// register file

module regfile (
	input         clk           ,
	input         rst_n         ,
	// read interface
	input  [ 4:0] reg_rd_r1_i   , // read register 1
	input  [ 4:0] reg_rd_r2_i   , // read register 2
	output [31:0] reg_rd_rdata1_o,
	output [31:0] reg_rd_rdata2_o,
	// write interface
	input  [31:0] reg_wr_data_i ,
	input  [ 4:0] reg_wr_reg_i , // write register
	input         ctrl_reg_we_i
);

// we don't care about the contents of x[0]
// as we hard wire this to 0 on a read
// but the register still exists for simplicity
	reg [31:0] x [31:0];

	reg [31:0] next_rdata1;
	reg [31:0] next_rdata2;

	wire isrd_r1zero = !(|reg_rd_r1_i);
	wire isrd_r2zero = !(|reg_rd_r2_i);

	integer i;

	always @(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			for (i = 0; i < 32; i++) begin
				x[i] <= 32'b0;
			end
		end else begin
			if (ctrl_reg_we_i) begin
				x[reg_wr_reg_i] <= reg_wr_data_i;
			end else begin
				next_rdata1 <= x[reg_rd_r1_i];
				next_rdata2 <= x[reg_rd_r2_i];
			end
		end
	end

	assign reg_rd_rdata1_o = isrd_r1zero ? 32'b0 :  next_rdata1;
	assign reg_rd_rdata2_o = isrd_r2zero ? 32'b0 : next_rdata2;

endmodule