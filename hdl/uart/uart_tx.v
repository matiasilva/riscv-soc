module uart_tx #(
   parameter WORD_WIDTH = 8,
   parameter OVERSAMPLING = 16,
   parameter BAUD_RATE = 115200
) (
   input wire clk,
   input wire rst_n,
   input wire tick,

   // write interface
   input wire [WORD_WIDTH-1:0] wr_data,
   input wire wr_valid,
   output wire wr_ready,

   // config
   wire parity_cfg,

   output wire dout
);

wire [WORD_WIDTH-1:0] word;
wire ser_tx_start;
wire ser_active;
wire flag;
wire flag_set;
wire flag_clear;

wire overflow_err;

// configuration update
always @(posedge clk or negedge rst_n) begin
   if (~rst_n) begin
      parity <= 1'b0;
   end else begin
      if (parity != parity_cfg && !ser_active)
         parity <= parity_cfg;
   end
end

uart_tx_ser #( .WORD_WIDTH(WORD_WIDTH), .OVERSAMPLING(OVERSAMPLING) ) uart_tx_ser0 (
   .clk     (clk),
   .rst_n   (rst_n),
   .tick    (tick),
   .din     (word),
   .tx_start(flag),
   .parity  (parity),
   .dout    (dout),
   .active  (ser_active)
);


flag_buf #( .WORD_WIDTH(WORD_WIDTH) ) flag_buf0 (
   .clk         (clk),
   .rst_n       (rst_n),
   .flag_set    (flag_set),
   .flag_clear  (flag_clear),
   .din         (wr_data),
   .flag        (flag),
   .dout        (word),
   .overflow_err(overflow_err)
);

assign wr_ready = !flag;

endmodule
