`default_nettype none

module uart_rx_des #(
   parameter WORD_WIDTH = 8,
   parameter OVERSAMPLING = 16
) (
   input wire clk,
   input wire rst_n,
   input wire tick,
   input wire din,
   input wire parity,
   output wire [DATA_WIDTH-1:0] dout,
   output reg frame_err,
   output reg done,
   output reg active
);

localparam TICK_MID_VAL = OVERSAMPLING / 2 - 1;
localparam DATA_WIDTH = WORD_WIDTH + 1; // parity bit

localparam [2:0]
   IDLE       = 3'b000,
   START_BIT  = 3'b001,
   DATA       = 3'b010,
   STOP_BIT   = 3'b011;

reg [2:0] state, state_nxt;

// internal
reg [$clog2(OVERSAMPLING)-1:0] tick_ctr, tick_ctr_nxt;
reg [$clog2(DATA_WIDTH+1)-1:0  ] bit_ctr, bit_ctr_nxt;
wire [$clog2(DATA_WIDTH+1)-1:0] N = parity ? DATA_WIDTH : WORD_WIDTH;

// outputs
reg [DATA_WIDTH-1:0] d, d_nxt;

always @(posedge clk or negedge rst_n) begin
   if (~rst_n) begin
      state    <= IDLE;
      tick_ctr <= 0;
      bit_ctr  <= 0;
      d        <= 0;
   end else begin
      state    <= state_nxt;
      tick_ctr <= tick_ctr_nxt;
      bit_ctr  <= bit_ctr_nxt;
      d        <= d_nxt;
   end
end

always @(*) begin
   state_nxt    = state;
   tick_ctr_nxt = tick_ctr;
   bit_ctr_nxt  = bit_ctr;
   d_nxt        = d;
   done        = 1'b0;
   frame_err    = 1'b0;

   case (state)
      IDLE: begin
         if (~din) begin
            state_nxt = START_BIT;
            tick_ctr_nxt = TICK_MID_VAL;
         end
      end
      START_BIT: begin
         if (tick) begin
            tick_ctr_nxt = tick_ctr - 1;
            if (tick_ctr == 0) begin
               state_nxt = DATA;
               tick_ctr_nxt = OVERSAMPLING - 1;
            end
         end
      end
      DATA: begin
         if (tick) begin
            tick_ctr_nxt = tick_ctr - 1;
            if (tick_ctr == 0) begin
               if (bit_ctr == N) begin
                  state_nxt = STOP_BIT;
                  bit_ctr_nxt = 0;
               end else begin
                  bit_ctr_nxt = bit_ctr + 1;
                  d_nxt = {din, d[DATA_WIDTH - 1 : 1]};
               end
               tick_ctr_nxt = OVERSAMPLING - 1;
            end
         end
      end
      STOP_BIT: begin
         if (tick) begin
            if (tick_ctr == 0) begin
               state_nxt = IDLE;
               if (din) // check data line deasserted
                  done = 1'b1;
               else
                  frame_err = 1'b1;
            end else
               tick_ctr_nxt = tick_ctr - 1;
         end
      end
   endcase
end

assign dout = d;
assign active = state != IDLE;

endmodule
