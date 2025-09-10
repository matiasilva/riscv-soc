"""
cocotb testbench for insnmem.sv
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
from cocotb_tools.runner import get_runner
import os
from pathlib import Path
import random
import pytest


def get_env_dir_safe(var: str) -> Path:
    envdir = Path(v) if (v := os.getenv(var)) else v
    assert envdir, f"env var {var} was not defined!"
    return envdir


CPU_ROOT = get_env_dir_safe("CPU_ROOT")

PRELOAD_PATH = str(CPU_ROOT) + "/tests/test_insnmem_preload_{size}.hex"


def get_hex_instructions(hex_path: str):
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


PRELOAD_INSTRUCTIONS = []


async def reset_dut(dut) -> None:
    """Reset the DUT"""
    dut.i_rst_n.value = 1
    await ClockCycles(dut.i_clk, 1)
    dut.i_rst_n.value = 0
    await ClockCycles(dut.i_clk, 2)
    dut.i_rst_n.value = 1


def setup_clock(dut) -> Clock:
    """Setup clock for the DUT"""
    clock = Clock(dut.i_clk, 10, unit="ns")
    clock.start(start_high=False)
    return clock


async def set_pc_and_wait(dut, pc: int) -> None:
    """Set PC and wait for next instruction to be fetched"""
    dut.i_pc.value = pc
    await RisingEdge(dut.i_clk)


async def init_inputs(dut) -> None:
    """Initialize all inputs to known state"""
    dut.i_pc.value = 0
    await RisingEdge(dut.i_clk)


async def tb_init(dut) -> Clock:
    """Initialize testbench: setup clock, reset, and init inputs"""

    global PRELOAD_INSTRUCTIONS
    PRELOAD_INSTRUCTIONS = get_hex_instructions(
        PRELOAD_PATH.format(size=dut.SIZE.value.to_unsigned())
    )

    clock = setup_clock(dut)
    await reset_dut(dut)
    await init_inputs(dut)
    return clock


@cocotb.test()
async def test_insnmem_basic_read(dut) -> None:
    """Test basic instruction memory read operations"""
    _ = await tb_init(dut)

    await set_pc_and_wait(dut, 0)
    await RisingEdge(dut.i_clk)
    actual = dut.o_insn.value.to_unsigned()
    expected = PRELOAD_INSTRUCTIONS[0]
    assert actual == expected, (
        f"Basic read failed: got=0x{actual:08x}, expected=0x{expected:08x}"
    )


@cocotb.test()
async def test_insnmem_nonaligned_exception(dut) -> None:
    """Test exception when reading from non-aligned address"""
    _ = await tb_init(dut)

    def aligned(x):
        return int(x % 4 != 0)

    targets = [i for i in range(100)]
    for addr in targets:
        expected = aligned(addr)
        await set_pc_and_wait(dut, addr)
        assert expected == dut.o_imem_exception.value


@cocotb.test()
async def test_insnmem_read_varied(dut) -> None:
    """Test reading from different memory addresses, aligned then non-aligned"""
    _ = await tb_init(dut)

    def get_rand_word():
        mem_word_max = dut.SIZE.value.to_unsigned() // 4
        return random.randint(0, mem_word_max - 1)

    addresses = [get_rand_word() for _ in range(100)]
    # launch first data
    word_addr = addresses.pop(0)
    expected = PRELOAD_INSTRUCTIONS[word_addr]
    await set_pc_and_wait(dut, word_addr << 2)

    for word_addr in addresses:
        await set_pc_and_wait(dut, word_addr << 2)
        actual = dut.o_insn.value.to_unsigned()
        assert actual == expected
        expected = PRELOAD_INSTRUCTIONS[word_addr]
        dut._log.debug(f"Address {word_addr}: instruction = 0x{actual:08x}")


@cocotb.test()
async def test_instrmem_pc_sequence(dut) -> None:
    """Test sequential PC increments (typical fetch pattern)"""
    _ = await tb_init(dut)

    # test 10 items with one dummy item to fully read out all data
    pc_sequence = [i * 4 for i in range(11)]
    expected = PRELOAD_INSTRUCTIONS[:10]
    instructions = []

    pc = pc_sequence.pop(0)
    await set_pc_and_wait(dut, pc)

    for pc in pc_sequence:
        await set_pc_and_wait(dut, pc)
        instruction = dut.o_insn.value.to_unsigned()
        instructions.append(instruction)
        dut._log.debug(f"PC={pc} next, last instruction=0x{instruction:08x}")

    assert instructions == expected, "Instruction fetch sequence failed"


@pytest.mark.parametrize("size", [512, 1024, 2048])
def test_insnmem_runner(size: int) -> None:
    """Test runner for instruction memory"""
    hdl_root = CPU_ROOT / "hdl"

    runner = get_runner("icarus")
    runner.build(
        sources=[hdl_root / "insnmem.sv"],
        hdl_toplevel="insnmem",
        always=True,
        waves=True,
        parameters={"SIZE": size},
        timescale=("1ns", "1ns"),
    )

    runner.test(
        hdl_toplevel="insnmem",
        test_module="test_insnmem",
        waves=True,
        plusargs=[f"+IMEM_PRELOAD_FILE={PRELOAD_PATH.format(size=size)}"],
    )
