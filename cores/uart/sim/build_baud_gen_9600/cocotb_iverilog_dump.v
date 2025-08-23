module cocotb_iverilog_dump();
initial begin
    $dumpfile("/Users/matias/projects/riscv-cpu/cores/uart/sim/build_baud_gen_9600/baud_gen.fst");
    $dumpvars(0, baud_gen);
end
endmodule
