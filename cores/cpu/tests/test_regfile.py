"""
cocotb testbench for regfile.sv
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb_tools.runner import get_runner
import random
from tb_utils import get_hdl_root, reset_dut, tb_init_base


async def fill_regfile_random(dut) -> dict[int, int]:
    """Fill regfile with random data and return the test data"""
    test_data: dict[int, int] = {}

    # Fill registers 1-31 with random data
    for addr in range(1, 32):
        data = random.getrandbits(32)
        test_data[addr] = data
        await write_regfile(dut, addr, data)

    test_data[0] = 0
    return test_data


async def write_regfile(dut, addr: int, data: int, enable: bool = True) -> None:
    """Write data to a register"""
    dut.i_wr_addr.value = addr
    dut.i_wr_data.value = data
    dut.i_wr_en.value = int(enable)
    await RisingEdge(dut.i_clk)
    dut.i_wr_en.value = 0
    dut._log.debug(f"Wrote {data:0x} to x{addr}")


async def read_launch_regfile(dut, addr: int, port=1) -> None:
    """Launch read address"""
    port2sig = {1: dut.i_rd_addr1, 2: dut.i_rd_addr2}
    port2sig[port].value = addr
    await RisingEdge(dut.i_clk)


def read_capture_regfile(dut, port=1) -> None:
    """Launch read address"""
    port2sig = {1: dut.o_rd_data1, 2: dut.o_rd_data2}
    return port2sig[port].value.to_unsigned()


async def read_launch_regfile_dual(dut, addr: tuple[int, int]) -> None:
    """Launch read address dual"""
    dut.i_rd_addr1.value = addr[0]
    dut.i_rd_addr2.value = addr[1]
    await RisingEdge(dut.i_clk)


async def init_inputs(dut) -> None:
    """Initialize all inputs to known state"""
    dut.i_rd_addr1.value = 0
    dut.i_rd_addr2.value = 0
    dut.i_wr_addr.value = 0
    dut.i_wr_data.value = 0
    dut.i_wr_en.value = 0
    await RisingEdge(dut.i_clk)


async def tb_init(dut) -> Clock:
    """Initialize testbench with regfile-specific reset timing"""
    return await tb_init_base(dut, init_inputs)


@cocotb.test()
@cocotb.parametrize(port=[1, 2])
async def test_regfile_rw_single(dut, port) -> None:
    """Regfile read/write test: mixed single port"""
    _ = await tb_init(dut)

    test_data = await fill_regfile_random(dut)

    # set up initial state
    addr = 0
    expected = test_data[addr]
    await read_launch_regfile(dut, addr, port=port)
    for addr in range(1, 32):
        # launch next address
        await read_launch_regfile(dut, addr, port=port)
        # read and assert previous
        actual = read_capture_regfile(dut, port=port)
        assert actual == expected, f"{port=}: {addr=}, {actual=:0x}, {expected=:0x}"
        expected = test_data[addr]


@cocotb.test()
async def test_regfile_rw_dual(dut) -> None:
    """Regfile read/write test: mixed dual port"""
    _ = await tb_init(dut)

    test_data = await fill_regfile_random(dut)
    pattern = [(random.randint(0, 31), random.randint(0, 31)) for _ in range(10)]

    # set up initial state
    addr1, addr2 = pattern.pop(0)
    await read_launch_regfile_dual(dut, (addr1, addr2))
    expected = (test_data[addr1], test_data[addr2])
    for addr1, addr2 in pattern:
        # launch next addresses
        await read_launch_regfile_dual(dut, (addr1, addr2))

        # read and assert previous
        actual = (
            dut.o_rd_data1.value.to_unsigned(),
            dut.o_rd_data2.value.to_unsigned(),
        )
        assert expected == actual
        expected = (test_data[addr1], test_data[addr2])


@cocotb.test()
async def test_regfile_read_during_write(dut) -> None:
    """Test that a read during a write returns old write data"""
    _ = await tb_init(dut)

    addr = random.randint(1, 31)
    values = (random.getrandbits(32), random.getrandbits(32))

    # write initial data
    await write_regfile(dut, addr, values[0])

    # write next data
    dut.i_rd_addr1.value = addr  # launch read
    await write_regfile(dut, addr, values[1])
    await RisingEdge(dut.i_clk)  # capture first read

    # should read old value
    assert dut.o_rd_data1.value.to_unsigned() == values[0], (
        f"Read during write failed: got={dut.o_rd_data1.value.to_unsigned():08x}, expected={values[0]}"
    )

    # capture second read
    await RisingEdge(dut.i_clk)
    actual = dut.o_rd_data1.value.to_unsigned()
    assert actual == values[1], (
        f"Post-write read failed: got={actual:08x}, expected={values[1]}"
    )


@cocotb.test()
async def test_regfile_write_enable(dut) -> None:
    """Test that writes don't happen when write enable is low"""
    _ = await tb_init(dut)

    # Write initial value
    await write_regfile(dut, 10, 0x12345678)

    # Try to write with enable low
    await write_regfile(dut, 10, 0xDEADBEEF, enable=False)

    # Read back - should still have original value
    await read_launch_regfile(dut, 10)
    await RisingEdge(dut.i_clk)
    actual = dut.o_rd_data1.value.to_unsigned()
    assert actual == 0x12345678, (
        f"Write enable test failed: got={actual:08x}, expected=0x12345678"
    )


@cocotb.test()
async def test_regfile_x0_hardwired(dut) -> None:
    """Test that x0 is hardwired to zero"""
    _ = await tb_init(dut)

    # Try to write to x0
    await write_regfile(dut, 0, 0xDEADBEEF)

    # Read x0 - should always be 0
    await read_launch_regfile_dual(dut, (0, 0))
    await RisingEdge(dut.i_clk)  # capture
    for actual in (
        dut.o_rd_data1.value.to_unsigned(),
        dut.o_rd_data2.value.to_unsigned(),
    ):
        assert actual == 0, f"x0 not hardwired to zero: got={actual}"


@cocotb.test()
@cocotb.parametrize(port=[1, 2])
async def test_regfile_boundary_values(dut, port) -> None:
    """Test boundary values for 32-bit registers"""
    _ = await tb_init(dut)

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
        await read_launch_regfile(dut, i, port=port)
        await RisingEdge(dut.i_clk)
        actual = read_capture_regfile(dut, port=port)
        assert actual == val, (
            f"Boundary test failed: addr={i}, got=0x{actual:08x}, expected=0x{val:08x}"
        )


@cocotb.test()
async def test_regfile_reset_behavior(dut) -> None:
    """Test that all registers are properly cleared on reset"""
    _ = await tb_init(dut)
    await RisingEdge(dut.i_clk)

    # Fill some registers with non-zero data
    for addr in range(1, 5):
        await write_regfile(dut, addr, 0xDEADBEEF)

    # Apply reset
    await reset_dut(dut)

    # Check that all registers read as zero after reset
    for addr in range(32):
        await read_launch_regfile(dut, addr)
        await RisingEdge(dut.i_clk)
        actual = read_capture_regfile(dut)
        assert actual == 0, (
            f"Register {addr} not cleared after reset: got=0x{actual:08x}"
        )


def test_regfile_runner() -> None:
    """Test runner for register file"""
    hdl_root = get_hdl_root()
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
