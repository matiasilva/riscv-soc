module soc (
	input clk,
	output LED_G
);

	reg [19:0] count = 0;
	reg state = 0;

	always @(posedge clk) begin 
		count <= count + 1;
		if(&count == 1) begin
			state = ~state;
		end
	end

	assign LED_G = state;

endmodule