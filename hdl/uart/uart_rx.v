`include "platform.vh"
`default_nettype none

module uart_rx #(
   parameter WORD_WIDTH = 8,
   parameter OVERSAMPLING = 16,
   parameter BAUD_RATE = 115200
)(
   input wire clk,
   input wire rst_n,
   input wire din,

   // read interface
   output reg rd_valid,
   output wire [WORD_WIDTH-1:0] rd_data,
   input wire rd_ready
);

localparam DATA_WIDTH = WORD_WIDTH + 1;

// configuration
wire parity_cfg = 1'b1;
reg parity;

// configuration update
always @(posedge clk or negedge rst_n) begin
   if (~rst_n) begin
      parity <= 1'b0;
   end else begin
      if (parity != parity_cfg && !des_active)
         parity <= parity_cfg;
   end
end


wire tick;
wire des_done;
wire des_active;
wire [DATA_WIDTH-1:0] data;

// errors
wire frame_err;
reg parity_err;
reg overflow_err;

baud_gen #( .OVERSAMPLING(OVERSAMPLING), .FREQ(`SYSFREQ), .BAUD_RATE(BAUD_RATE) )
   baud_gen0 (
   .clk  (clk),
   .rst_n(rst_n),
   .tick (tick)
);

uart_rx_des #( .OVERSAMPLING(OVERSAMPLING), .WORD_WIDTH(WORD_WIDTH) )
   uart_rx_des0 (
   .clk      (clk),
   .rst_n    (rst_n),
   .tick     (tick),
   .din      (din),
   .parity   (parity),
   .dout     (data),
   .frame_err(frame_err),
   .done     (des_done),
   .active   (des_active)
);

// UART interface
reg [WORD_WIDTH-1:0] dbuf;
wire [WORD_WIDTH-1:0] word = parity ? data [DATA_WIDTH-2:0] : data[DATA_WIDTH-1:1];

always @(posedge clk or negedge rst_n) begin
   if (~rst_n) begin
      dbuf <= 0;
      parity_err <= 1'b0;
      overflow_err <= 1'b0;
      rd_valid <= 1'b0;
   end else begin
      if (rd_valid && rd_ready)
         rd_valid <= 1'b0;
      // order matters here, fresh data added even if consumed in same cycle
      if (des_done) begin
         if (parity && (data[DATA_WIDTH-1] != ~(^word)))
            parity_err <= 1'b1;
         else begin
            dbuf <= word;
            if (rd_valid) // valid data but we write new data
               overflow_err <= 1'b1;
            rd_valid <= 1'b1;
         end
      end
   end
end

assign rd_data = dbuf;

endmodule
