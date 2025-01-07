`default_nettype none

module uart_tx_ser #(
   parameter WORD_WIDTH = 8,
   parameter OVERSAMPLING = 16
) (
   input wire clk,
   input wire rst_n,
   input wire tick,

   // data
   input wire [WORD_WIDTH-1:0] din,
   input wire tx_start,
   output reg dout,

   // config & flags
   input wire parity,
   output wire active
);

localparam DATA_WIDTH = WORD_WIDTH + 1; // parity

localparam [2:0]
   IDLE = 3'b000,
   START_BIT = 3'b001,
   DATA = 3'b010,
   STOP_BIT = 3'b011;

reg [2:0] state, state_nxt;
reg [DATA_WIDTH-1:0] d, d_nxt;
reg [$clog2(OVERSAMPLING)-1:0] tick_ctr, tick_ctr_nxt;
reg [$clog2(DATA_WIDTH+1)-1:0] bit_ctr, bit_ctr_nxt;

wire hamming = ~(^din);
wire [$clog2(DATA_WIDTH+1)-1:0] N = parity ? DATA_WIDTH : WORD_WIDTH;

always @(posedge clk or negedge rst_n) begin
   if (~rst_n) begin
      d <= 0;
      state <= IDLE;
   end else begin
      d <= d_nxt;
      state <= state_nxt;
      tick_ctr <= tick_ctr_nxt;
      bit_ctr <= bit_ctr_nxt;
   end
end

always @(*) begin
   state_nxt = state;
   d_nxt = d;
   tick_ctr_nxt = tick_ctr;
   bit_ctr_nxt = bit_ctr;

   dout = 1'b0;
   case (state)
      IDLE: begin
         if (tx_start) begin
            tick_ctr_nxt = OVERSAMPLING - 1;
            state_nxt = START_BIT;
            d_nxt = {hamming, din};
         end
      end
      START_BIT: begin
         dout = 1'b0;
         if (tick) begin
            if (tick_ctr == 0) begin
               state_nxt = DATA;
               tick_ctr_nxt = OVERSAMPLING -1;
               bit_ctr_nxt = N;
            end else
               tick_ctr_nxt = tick_ctr - 1;
         end
      end
      DATA: begin
         dout = d[0];
         if (tick) begin
            if (tick_ctr == 0) begin
               if (bit_ctr == 0) begin
                  state_nxt = STOP_BIT;
               end else begin
                  bit_ctr_nxt = bit_ctr - 1;
                  d_nxt = d >> 1;
               end
               tick_ctr_nxt = OVERSAMPLING -1;
            end else
               tick_ctr_nxt = tick_ctr - 1;
         end
      end
      STOP_BIT: begin
         dout = 1'b1;
         if (tick) begin
            if (tick_ctr == 0) begin
               state_nxt = IDLE;
            end else
               tick_ctr_nxt = tick_ctr - 1;
         end
      end
   endcase
end

assign active = state != IDLE;

endmodule
