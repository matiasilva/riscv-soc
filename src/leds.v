module soc (
	input clk,
	output P1_9
);

	reg [15:0] count = 0;
	reg state = 0;

	always @(posedge clk) begin 
		count <= count + 1;
		if(&count == 1) begin
			state = ~state;
		end
	end

	assign P1_9 = state;

endmodule