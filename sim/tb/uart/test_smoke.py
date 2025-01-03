# Smoke test for UART module

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer, ClockCycles


@cocotb.test()
async def smoke_test(dut):
    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    dut.rst.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst.value = 1
    await Timer(1, units="us")  # wait a bit
    await FallingEdge(dut.clk)  # wait for falling edge/"negedge"
    dut._log.info("test finished")


import os
from pathlib import Path
from cocotb_tools import runner


def test_lcd_runner():
    sim = runner.Icarus()
    root = Path(os.getenv("ROOT")) / "hdl"

    sources = [
        "lcd_st7789v3.v",
        "serdes.v",
        "fifo.v",
        "decoder.v",
        "stall.v",
        "ram_writer.v",
    ]
    sources = [root / s for s in sources]

    sim.build(
        sources=sources,
        includes=[root],
        hdl_toplevel="lcd_st7789v3",
        timescale=("1ns", "1ps"),
        build_dir=f"build/build_lcd",
        waves=True,
    )

    test_opts = {"waves": True, "test_module": "tb", "timescale": ("1ns", "1ps")}
    sim.test(hdl_toplevel="lcd_st7789v3", **test_opts)


if __name__ == "__main__":
    test_lcd_runner()
