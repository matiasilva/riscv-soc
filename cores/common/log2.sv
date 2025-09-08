module log2 #(
   parameter WIDTH = 8,
   parameter LOG_WIDTH = $clog2(WIDTH)
) (
   input logic [WIDTH-1:0] i_din,
   output logic [LOG_WIDTH-1:0] o_dout
);

integer i;
always_comb begin : log2_and_or_mux
   o_dout = '0;
   for (i = 0; i < WIDTH; i = i + 1) begin
      o_dout |= {LOG_WIDTH{i_din[i]}} & i[LOG_WIDTH-1:0];
   end
end

endmodule

