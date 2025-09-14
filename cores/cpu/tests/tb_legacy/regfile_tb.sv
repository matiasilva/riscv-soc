`timescale 1us / 1ns

`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value, expected %x, got %x", value, signal); \
            wavetext <= "FAILED"; \
            #(HCLK) $finish; \
        end

module regfile_tb ();

  reg clk;
  reg rst_n;

  // module specific inputs and outputs here
  reg [4:0] rr1;  // read register 1
  reg [4:0] rr2;  // read register 2
  reg [4:0] wrr;  // write register
  reg [31:0] wrdata;
  reg wr_en;
  wire [31:0] rdata1;
  wire [31:0] rdata2;
  reg [31:0] rdata1_result;
  reg [31:0] rdata2_result;

  reg [1023:0] wavetext;
  integer scratch1;
  integer i;

  localparam CLK = 1;
  localparam HCLK = CLK * 0.5;
  localparam PDELAY = CLK * 0.001;
  localparam N_TESTS = 1000;


  // include duts here
  regfile dut (
      .clk   (clk),
      .rst_n (rst_n),
      .rr1   (rr1),
      .rr2   (rr2),
      .wrr   (wrr),
      .wr_en (wr_en),
      .wrdata(wrdata),
      .rdata1(rdata1),
      .rdata2(rdata2)
  );

  always #CLK clk = ~clk;

  initial begin
    $dumpfile("regfile_tb.vcd");
    $dumpvars(0, regfile_tb);

  end

  task init();
    begin
      #HCLK rst_n <= 0;
      #HCLK rst_n <= 1;
      #HCLK;
    end
  endtask

  // include tasks here
  task check_default();
    // check that all registers are correctly set to 0
    begin
      for (i = 0; i < 32; i = i + 2) begin
        rr1   <= i;
        rr2   <= i + 1;
        wr_en <= 1'b0;
        @(posedge clk);

        #PDELAY rdata1_result <= rdata1;
        rdata2_result <= rdata2;
        #PDELAY `assert(rdata1_result, 32'b0);
        `assert(rdata2_result, 32'b0);

      end
    end

  endtask

  task check_x0();
    // ensure that we always get 0 when reading x0
    begin
      wavetext <= "check x0";
      wr_en    <= 1'b1;
      wrr      <= 5'b0;
      wrdata   <= $urandom;

      @(posedge clk);
      wr_en <= 1'b0;
      rr1   <= 5'b0;
      rr2   <= 5'b0;

      @(posedge clk);
      #PDELAY rdata1_result <= rdata1;
      rdata2_result <= rdata2;
      #PDELAY `assert(rdata1_result, 32'b0);
      `assert(rdata2_result, 32'b0);
    end

  endtask

  task check_writeback();
    // ensure we can write to all registers
    begin
      wavetext <= "check writeback";
      for (i = 1; i < 32; i = i + 1) begin
        wr_en    <= 1'b1;
        wrr      <= i;
        scratch1 <= $urandom;
        #PDELAY wrdata <= scratch1;

        @(posedge clk);
        rr1   <= i;
        wr_en <= 1'b0;

        @(posedge clk);
        #PDELAY rdata1_result <= rdata1;
        #PDELAY `assert(rdata1_result, scratch1);
      end
    end

  endtask


  initial begin
    clk      <= 0;
    rst_n    <= 1;
    wavetext <= "start of test";
    $display("start of test");

    init();

    check_default();
    check_x0();
    check_writeback();

    $display("end of test");
    $finish;
  end

endmodule
