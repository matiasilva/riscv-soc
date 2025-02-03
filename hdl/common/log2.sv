module log2 #(
   parameter WIDTH = 8,
   parameter LOG_WIDTH = $clog2(WIDTH)
) (
   input logic [WIDTH-1:0] din,
   output logic [LOG_WIDTH-1:0] dout
);

integer i;
always_comb begin : log2_and_or_mux
   dout = '0;
   for (i = 0; i < WIDTH; i = i + 1) begin
      dout |= {LOG_WIDTH{din[i]}} & i[LOG_WIDTH-1:0];
   end
end

endmodule

