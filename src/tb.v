`timescale 1ns / 1ps

module tb ();

   reg clk;
   wire out;

   always begin
     #5 clk = ~clk;  // Toggle the clock every 5 time units
   end

   soc dut (
      .clk(clk),
      .P3_1(out)
   );

   initial begin
       $dumpfile("tb.vcd");
       $dumpvars(0,tb);

       clk = 0;

      #1000 $finish;  // Stop simulation after 1000 time units
   end

endmodule

