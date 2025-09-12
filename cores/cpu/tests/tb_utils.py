# MIT License
#
# Copyright (c) 2025 Matias Wang Silva
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

"""
Shared cocotb testbench utilities for CPU core tests
"""

import os
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


def get_env_dir_safe(var: str) -> Path:
    """Safely get environment directory path"""
    envdir = Path(v) if (v := os.getenv(var)) else v
    assert envdir, f"env var {var} was not defined!"
    return envdir


def get_hdl_root() -> Path:
    """Get HDL root directory from environment"""
    return get_env_dir_safe("CPU_ROOT") / "hdl"


async def reset_dut(dut) -> None:
    """Standard reset sequence for DUTs"""
    dut.i_rst_n.value = 1
    await ClockCycles(dut.i_clk, 1)
    dut.i_rst_n.value = 0
    await ClockCycles(dut.i_clk, 2)
    dut.i_rst_n.value = 1


def setup_clock(dut, period_ns: int = 10) -> Clock:
    """Setup standard clock for DUT"""
    clock = Clock(dut.i_clk, period_ns, unit="ns")
    clock.start(start_high=False)
    return clock


async def tb_init_base(dut, init_func=None) -> Clock:
    """Standard testbench initialization sequence"""
    clock = setup_clock(dut)
    await reset_dut(dut)
    if init_func:
        await init_func(dut)
    return clock


def get_hex_instructions(hex_path: str) -> list[int]:
    """Reads the hex file and returns expected instructions"""

    instructions = []

    with open(hex_path, "r") as f:
        for line in f:
            line = line.strip()
            if line:
                hex_bytes = line.split()
                if len(hex_bytes) == 4:
                    instruction = (
                        (int(hex_bytes[3], 16) << 24)
                        | (int(hex_bytes[2], 16) << 16)
                        | (int(hex_bytes[1], 16) << 8)
                        | int(hex_bytes[0], 16)
                    )
                    instructions.append(instruction)

    return instructions
