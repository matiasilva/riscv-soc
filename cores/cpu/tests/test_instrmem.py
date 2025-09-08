"""
cocotb testbench for instrmem.sv
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
PRELOAD_PATH = CPU_ROOT / "tests" / "test_instrmem_preload.hex"


def get_hex_instructions():
    """Reads the hex file and returns expected instructions"""

    instructions = []

    with open(PRELOAD_PATH, "r") as f:
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


PRELOAD_INSTRUCTIONS = get_hex_instructions()


async def reset_dut(dut) -> None:
    """Reset the DUT"""
    dut.i_rst_n.value = 1
    await ClockCycles(dut.i_clk, 3)
    dut.i_rst_n.value = 0
    await ClockCycles(dut.i_clk, 3)
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
    clock = setup_clock(dut)
    await reset_dut(dut)
    await init_inputs(dut)
    return clock


@cocotb.test()
async def test_instrmem_basic_read(dut) -> None:
    """Test basic instruction memory read operations"""
    _ = await tb_init(dut)

    await set_pc_and_wait(dut, 0)
    await RisingEdge(dut.i_clk)
    actual = dut.o_instr.value.to_unsigned()
    expected = PRELOAD_INSTRUCTIONS[0]
    assert actual == expected, (
        f"Basic read failed: got=0x{actual:08x}, expected=0x{expected:08x}"
    )


# @cocotb.test()
# @cocotb.parametrize(
#     addresses=[[0, 4, 8, 12, 16, 20, 100, 200, 400], [1, 2, 3, 5, 6, 7, 9, 10, 11]]
# )
# async def test_instrmem_read_varied(dut, addresses) -> None:
#     """Test reading from different memory addresses, aligned then non-aligned"""
#     _ = await tb_init(dut)
#
#     for addr in addresses:
#         await set_pc_and_wait(dut, addr)
#         await RisingEdge(dut.i_clk)
#         actual = dut.o_instr.value.to_unsigned()
#         expected = 0x00000000
#         assert actual == expected
#         dut._log.debug(f"Address {addr}: instruction = 0x{actual:08x}")
#

# @cocotb.test()
# async def test_instrmem_boundary_conditions(dut) -> None:
#     """Test memory boundary conditions"""
#     _ = await tb_init(dut)
#
#     # Test addresses near the memory size limit
#     # Default SIZE is 512 bytes, so valid addresses are 0-511
#     boundary_addresses = [0, 4, 508, 512, 1000]  # Some valid, some invalid
#
#     for addr in boundary_addresses:
#         await set_pc_and_wait(dut, addr)
#         await RisingEdge(dut.i_clk)
#         actual = dut.o_instr.value.to_unsigned()
#
#         if addr < 509:  # Valid address range (need 4 bytes)
#             dut._log.info(f"Valid boundary addr {addr}: instruction = 0x{actual:08x}")
#         else:
#             dut._log.info(f"Invalid boundary addr {addr}: instruction = 0x{actual:08x}")
#             # For out-of-bounds access, behavior may be undefined but should not crash
#
#
# @cocotb.test()
# async def test_instrmem_pc_sequence(dut) -> None:
#     """Test sequential PC increments (typical fetch pattern)"""
#     _ = await tb_init(dut)
#
#     # Simulate typical PC sequence: 0, 4, 8, 12, 16...
#     pc_sequence = [i * 4 for i in range(10)]
#     instructions = []
#
#     for pc in pc_sequence:
#         await set_pc_and_wait(dut, pc)
#         await RisingEdge(dut.i_clk)
#         instruction = dut.o_instr.value.to_unsigned()
#         instructions.append(instruction)
#         dut._log.info(f"PC={pc}: instruction=0x{instruction:08x}")
#
#     # Verify that we got different instructions for different addresses
#     # (or at least that the interface is working)
#     assert len(instructions) == len(pc_sequence), "Instruction fetch sequence failed"
#
#
# @cocotb.test()
# async def test_instrmem_rapid_pc_changes(dut) -> None:
#     """Test rapid PC changes to verify timing"""
#     _ = await tb_init(dut)
#
#     # Rapidly change PC and verify instruction updates
#     addresses = [0, 4, 8, 12, 16, 4, 0, 8]  # Include some repeats
#
#     for addr in addresses:
#         await set_pc_and_wait(dut, addr)
#         await RisingEdge(dut.i_clk)
#         instruction = dut.o_instr.value.to_unsigned()
#         dut._log.info(f"Rapid change to PC={addr}: instruction=0x{instruction:08x}")
#
#
# @cocotb.test()
# async def test_instrmem_random_access_pattern(dut) -> None:
#     """Test random access pattern to instruction memory"""
#     _ = await tb_init(dut)
#
#     # Generate random word-aligned addresses within valid range
#     random.seed(42)  # For reproducible tests
#     random_addresses = [random.randrange(0, 500, 4) for _ in range(20)]
#
#     for addr in random_addresses:
#         await set_pc_and_wait(dut, addr)
#         await RisingEdge(dut.i_clk)
#         instruction = dut.o_instr.value.to_unsigned()
#         dut._log.info(f"Random access PC={addr}: instruction=0x{instruction:08x}")
#
#
# def test_instrmem_with_preload_fixture(hex_instructions):
#     """Test that hex_instructions fixture works correctly"""
#     assert len(hex_instructions) > 0, "Hex instructions should not be empty"
#
#     # Verify the first few expected instructions match the hex file format
#     expected_first_instructions = [
#         0x00100013,  # addi x0, x0, 1
#         0x00200093,  # addi x1, x0, 2
#         0x00300113,  # addi x2, x0, 3
#         0x00400193,  # addi x3, x0, 4
#     ]
#
#     for i, expected in enumerate(expected_first_instructions):
#         if i < len(hex_instructions):
#             assert hex_instructions[i] == expected, (
#                 f"Instruction {i}: got=0x{hex_instructions[i]:08x}, expected=0x{expected:08x}"
#             )
#
#
# @cocotb.test()
# async def test_instrmem_with_preload(dut) -> None:
#     """Test instruction memory with actual preloaded data"""
#     _ = await tb_init(dut)
#
#     # Test reading each preloaded instruction
#     for i, expected in enumerate(PRELOAD_INSTRUCTIONS):
#         pc = i * 4  # Word-aligned addresses
#         await set_pc_and_wait(dut, pc)
#         await RisingEdge(dut.i_clk)
#         actual = dut.o_instr.value.to_unsigned()
#
#         dut._log.info(
#             f"Preload test PC={pc}: got=0x{actual:08x}, expected=0x{expected:08x}"
#         )
#
#         assert actual == expected, (
#             f"Preload mismatch at PC={pc}: got=0x{actual:08x}, expected=0x{expected:08x}"
#         )


# @pytest.mark.parametrize("size", [512, 1024, 2048])
@pytest.mark.parametrize("size", [512])
def test_instrmem_runner(size: int) -> None:
    """Test runner for instruction memory"""
    hdl_root = CPU_ROOT / "hdl"

    runner = get_runner("icarus")
    runner.build(
        sources=[hdl_root / "instrmem.sv"],
        hdl_toplevel="instrmem",
        always=True,
        waves=True,
        parameters={"SIZE": size},
        timescale=("1ns", "1ns"),
    )

    runner.test(
        hdl_toplevel="instrmem",
        test_module="test_instrmem",
        waves=True,
        plusargs=[f"+IMEM_PRELOAD_FILE={PRELOAD_PATH}"],
    )
