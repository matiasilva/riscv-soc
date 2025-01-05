# Smoke test for UART module

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

import os
from pathlib import Path
from cocotb_tools import runner
import pytest


@cocotb.test
async def simple_task(dut):
    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1

    M = dut.M.value.to_unsigned()
    for _ in range(5):
        await ClockCycles(dut.clk, M)
        assert dut.tick.value == 1

    dut._log.info("test finished")


@pytest.mark.parametrize("baud_rate", [9600, 19200, 115200])
def test_baud_gen_runner(baud_rate: int):
    sim = runner.Icarus()
    root = Path(str(os.getenv("ROOT"))) / "hdl"
    module = "baud_gen"

    sources = [f"uart/{module}.v"]
    sources = [root / s for s in sources]

    sim.build(
        sources=sources,
        includes=[root, root / "uart"],
        hdl_toplevel=module,
        timescale=("1ns", "1ps"),
        build_dir=f"build/build_{module}_{baud_rate}",
        parameters={
            "BAUD_RATE": baud_rate,
        },
        waves=True,
    )

    test_opts = {"test_module": "test_baud_gen,", "waves": False}
    sim.test(hdl_toplevel=module, **test_opts)


if __name__ == "__main__":
    test_baud_gen_runner()
