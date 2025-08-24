"""
cocotb testbench for regfile.sv
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb_tools.runner import get_runner
import os
from pathlib import Path
import random


async def reset_dut(dut) -> None:
    """Reset the DUT"""
    dut.rst_n.value = 0
    await Timer(10, unit="ns")
    dut.rst_n.value = 1
    await Timer(10, unit="ns")


def setup_clock(dut) -> Clock:
    """Setup clock for the DUT"""
    clock = Clock(dut.clk, 10, unit="ns")
    clock.start()
    return clock


async def fill_regfile_random(dut) -> dict[int, int]:
    """Fill regfile with random data and return the test data"""
    test_data: dict[int, int] = {}

    # Fill registers 1-31 with random data
    for addr in range(1, 32):
        data = random.randint(0, 2**32 - 1)
        test_data[addr] = data
        await write_regfile(dut, addr, data)

    return test_data


async def write_regfile(dut, addr: int, data: int, enable: bool = True) -> None:
    """Write data to a register"""
    dut.wr_addr_ip.value = addr
    dut.wr_data_ip.value = data
    dut.wr_en_ip.value = int(enable)
    await RisingEdge(dut.clk)
    dut.wr_en_ip.value = 0


async def read_regfile(dut, addr: int, port: int = 1) -> int:
    """Read data from a register on specified port (1 or 2)"""
    if port == 1:
        dut.rd_addr1_ip.value = addr
        await RisingEdge(dut.clk)
        return dut.rd_data1_op.value.to_unsigned()
    else:
        dut.rd_addr2_ip.value = addr
        await RisingEdge(dut.clk)
        return dut.rd_data2_op.value.to_unsigned()


async def read_regfile_dual(dut, addr1: int, addr2: int) -> tuple[int, int]:
    """Read from both ports simultaneously"""
    dut.rd_addr1_ip.value = addr1
    dut.rd_addr2_ip.value = addr2
    await RisingEdge(dut.clk)
    return dut.rd_data1_op.value.to_unsigned(), dut.rd_data2_op.value.to_unsigned()


def init_inputs(dut) -> None:
    """Initialize all inputs to known state"""
    dut.rd_addr1_ip.value = 0
    dut.rd_addr2_ip.value = 0
    dut.wr_addr_ip.value = 0
    dut.wr_data_ip.value = 0
    dut.wr_en_ip.value = 0


@cocotb.test()
async def test_regfile_reads(dut) -> None:
    """Regfile read test: mixed single/dual port"""
    _ = setup_clock(dut)
    init_inputs(dut)
    await reset_dut(dut)
    await RisingEdge(dut.clk)

    test_data = await fill_regfile_random(dut)

    # Test single port reads
    for addr in range(32):
        expected = 0 if addr == 0 else test_data[addr]

        actual1 = await read_regfile(dut, addr, port=1)
        assert actual1 == expected, (
            f"Port 1: addr={addr}, got={actual1:0x}, expected={expected:0x}"
        )

        actual2 = await read_regfile(dut, addr, port=2)
        assert actual2 == expected, (
            f"Port 2: addr={addr}, got={actual2:0x}, expected={expected:0x}"
        )

    # Test simultaneous reads on both ports
    for i in range(10):
        addr1 = random.randint(0, 31)
        addr2 = random.randint(0, 31)

        actual1, actual2 = await read_regfile_dual(dut, addr1, addr2)

        expected1 = 0 if addr1 == 0 else test_data[addr1]
        expected2 = 0 if addr2 == 0 else test_data[addr2]
        assert actual1 == expected1
        assert actual2 == expected2


@cocotb.test()
async def test_regfile_writes(dut) -> None:
    """Regfile write test"""
    _ = setup_clock(dut)
    init_inputs(dut)
    await reset_dut(dut)
    await RisingEdge(dut.clk)

    # Test writes to different registers
    test_values = [0x12345678, 0xABCDEF00, 0xDEADBEEF]
    for i, val in enumerate(test_values, 1):
        await write_regfile(dut, i, val)
        actual = await read_regfile(dut, i)
        assert actual == val, (
            f"Write test failed: addr={i}, got={actual:08x}, expected={val:08x}"
        )


@cocotb.test()
async def test_regfile_read_during_write(dut) -> None:
    """Test that reads during writes return old data"""
    _ = setup_clock(dut)
    init_inputs(dut)
    await reset_dut(dut)
    await RisingEdge(dut.clk)

    # Write initial value to register 5
    await write_regfile(dut, 5, 0x11111111)

    # Read and write simultaneously - should get old data
    dut.rd_addr1_ip.value = 5
    dut.wr_addr_ip.value = 5
    dut.wr_data_ip.value = 0x22222222
    dut.wr_en_ip.value = 1
    await RisingEdge(dut.clk)

    # Should read old value (0x11111111)
    assert dut.rd_data1_op.value == 0x11111111, (
        f"Read during write failed: got={dut.rd_data1_op.value:08x}, expected=0x11111111"
    )

    # Next cycle should show new value
    actual = await read_regfile(dut, 5)
    assert actual == 0x22222222, (
        f"Post-write read failed: got={actual:08x}, expected=0x22222222"
    )


@cocotb.test()
async def test_regfile_write_enable(dut) -> None:
    """Test that writes don't happen when write enable is low"""
    _ = setup_clock(dut)
    init_inputs(dut)
    await reset_dut(dut)
    await RisingEdge(dut.clk)

    # Write initial value
    await write_regfile(dut, 10, 0x12345678)

    # Try to write with enable low
    await write_regfile(dut, 10, 0xDEADBEEF, enable=False)

    # Read back - should still have original value
    actual = await read_regfile(dut, 10)
    assert actual == 0x12345678, (
        f"Write enable test failed: got={actual:08x}, expected=0x12345678"
    )


@cocotb.test()
async def test_regfile_x0_hardwired(dut) -> None:
    """Test that x0 is hardwired to zero"""
    _ = setup_clock(dut)
    init_inputs(dut)
    await reset_dut(dut)
    await RisingEdge(dut.clk)

    # Try to write to x0
    await write_regfile(dut, 0, 0xDEADBEEF)

    # Read x0 - should always be 0
    actual = await read_regfile(dut, 0)
    assert actual == 0, f"x0 not hardwired to zero: got={actual}"


@cocotb.test()
async def test_regfile_boundary_values(dut) -> None:
    """Test boundary values for 32-bit registers"""
    _ = setup_clock(dut)
    init_inputs(dut)
    await reset_dut(dut)
    await RisingEdge(dut.clk)

    # Test boundary values
    boundary_values = [
        0x00000000,  # All zeros
        0xFFFFFFFF,  # All ones
        0x80000000,  # Most significant bit set
        0x7FFFFFFF,  # Largest positive signed
        0x55555555,  # Alternating bits
        0xAAAAAAAA,  # Opposite alternating bits
    ]

    for i, val in enumerate(boundary_values, 1):
        await write_regfile(dut, i, val)
        actual = await read_regfile(dut, i)
        assert actual == val, (
            f"Boundary test failed: addr={i}, got=0x{actual:08x}, expected=0x{val:08x}"
        )


@cocotb.test()
async def test_regfile_reset_behavior(dut) -> None:
    """Test that all registers are properly cleared on reset"""
    _ = setup_clock(dut)
    init_inputs(dut)
    await reset_dut(dut)
    await RisingEdge(dut.clk)

    # Fill some registers with non-zero data
    for addr in range(1, 5):
        await write_regfile(dut, addr, 0xDEADBEEF)

    # Apply reset
    await reset_dut(dut)

    # Check that all registers read as zero after reset
    for addr in range(32):
        actual = await read_regfile(dut, addr)
        assert actual == 0, (
            f"Register {addr} not cleared after reset: got=0x{actual:08x}"
        )


@cocotb.test()
async def test_regfile_stress(dut) -> None:
    """Stress test with rapid read/write operations"""
    _ = setup_clock(dut)
    init_inputs(dut)
    await reset_dut(dut)
    await RisingEdge(dut.clk)

    # Rapid alternating read/write to same register
    test_addr = 15
    values = [0x11111111, 0x22222222, 0x33333333, 0x44444444]

    for val in values:
        # Write
        await write_regfile(dut, test_addr, val)

        # Immediate read while writing next value
        dut.rd_addr1_ip.value = test_addr
        next_val = (val + 0x10101010) & 0xFFFFFFFF
        dut.wr_addr_ip.value = test_addr
        dut.wr_data_ip.value = next_val
        dut.wr_en_ip.value = 1
        await RisingEdge(dut.clk)

        # Should read previous value, not the one being written
        assert dut.rd_data1_op.value == val, (
            f"Stress test failed: got=0x{dut.rd_data1_op.value:08x}, expected=0x{val:08x}"
        )

        # Clean up - disable write
        dut.wr_en_ip.value = 0
        await RisingEdge(dut.clk)


@cocotb.test()
async def test_regfile_parametrized_8bit(dut) -> None:
    """Test regfile functionality with 8-bit width parameter"""
    # Note: This test assumes the regfile is instantiated with XW=8
    # In practice, you'd need separate test runners for different XW values

    _ = setup_clock(dut)
    init_inputs(dut)
    await reset_dut(dut)
    await RisingEdge(dut.clk)

    # Test 8-bit values (if XW=8)
    test_values_8bit = [0x00, 0xFF, 0x55, 0xAA, 0x80, 0x7F]

    for i, val in enumerate(test_values_8bit, 1):
        await write_regfile(dut, i, val)
        actual = await read_regfile(dut, i)

        # For 8-bit, only check lower 8 bits
        expected = val & 0xFF
        actual = actual & 0xFF
        assert actual == expected, (
            f"8-bit test failed: addr={i}, got=0x{actual:02x}, expected=0x{expected:02x}"
        )


def test_regfile_runner() -> None:
    hdl_root = os.getenv("CPU_ROOT")
    assert hdl_root is not None
    hdl_root = Path(hdl_root) / "hdl"
    runner = get_runner("icarus")
    runner.build(
        sources=[hdl_root / "regfile.sv"],
        hdl_toplevel="regfile",
        always=True,
        waves=True,
        timescale=("1ns", "1ns"),
        build_dir="sim",
    )

    runner.test(hdl_toplevel="regfile", test_module="test_regfile", waves=True)
