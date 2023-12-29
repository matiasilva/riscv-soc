// register file

module reg_file (
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
);

reg [31:0] x [31:0]
reg [31:0] pc;

int i;

always @(posedge clk or negedge rst_n) begin :
	if(~rst_n) begin
		for (i = 0; i < 32; i++) begin
			x[i] <= 32'b0;
		end
	end else begin

	end
end

endmodule