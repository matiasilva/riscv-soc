# Smoke test for UART module

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from random import getrandbits, randint
import logging

import os
from pathlib import Path
from cocotb_tools import runner
import pytest


class UartTxDriver:
    def __init__(self, dut_din, baud_rate: int, word_width: int, parity: bool):
        self.tx = dut_din
        self.baud_rate = baud_rate
        self.word_width = word_width
        self.parity = parity
        self.log = logging.getLogger(f"cocotb.{dut_din._path}")

        self.tx.value = 1
        self.log.info(f"UART TX driver: parity {'ON' if parity else 'OFF'}")

    async def send_byte(self, data):
        brt = Timer(int(1e9 / self.baud_rate), units="ns")
        to_send = data
        self.log.info(f"sending byte 0x{data:02x}")
        # start bit
        self.tx.value = 0
        await brt
        # data bits
        data_len = self.word_width + 1 if self.parity else self.word_width
        parity_val = ~(to_send.bit_count() % 2)
        to_send |= parity_val << self.word_width
        for i in range(data_len):
            self.tx.value = (to_send >> i) & 1
            await brt
        # stop bit
        self.tx.value = 1
        await brt


async def init_dut(dut) -> UartTxDriver:
    BAUD_RATE = dut.BAUD_RATE.value.to_unsigned()
    WORD_WIDTH = dut.WORD_WIDTH.value.to_unsigned()
    parity = int(os.getenv("TB_PARITY", ""))
    dut.parity_cfg.value = parity
    # clock & reset
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1

    return UartTxDriver(dut.din, BAUD_RATE, WORD_WIDTH, bool(parity))


@cocotb.test
async def one_byte(dut):
    WORD_WIDTH = dut.WORD_WIDTH.value.to_unsigned()
    uart_tx = await init_dut(dut)

    # add some "aysnchronicity"
    await ClockCycles(dut.clk, randint(2, dut.baud_gen0.M.value.to_unsigned()))

    dut.rd_ready.value = 1
    to_send = getrandbits(WORD_WIDTH)
    await uart_tx.send_byte(to_send)

    while int(dut.rd_valid.value) != 1:
        await RisingEdge(dut.clk)

    received = int(dut.rd_data.value)
    dut._log.info(f"byte received: 0x{received:02x}")
    assert received == to_send

    dut._log.info("one byte test finished")


@cocotb.test()
async def stress_test(dut):
    """send bytes consecutively with variable delay"""

    WORD_WIDTH = dut.WORD_WIDTH.value.to_unsigned()
    uart_tx = await init_dut(dut)
    dut.rd_ready.value = 1

    target = 20
    for _ in range(target):
        # add some "aysnchronicity"
        tick_cycles = dut.baud_gen0.M.value.to_unsigned()
        await ClockCycles(dut.clk, randint(0, 3 * tick_cycles))

        to_send = getrandbits(WORD_WIDTH)
        await uart_tx.send_byte(to_send)

        while int(dut.rd_valid.value) != 1:
            await RisingEdge(dut.clk)

        received = int(dut.rd_data.value)
        dut._log.info(f"byte received: 0x{received:02x}")
        assert received == to_send

    dut._log.info(f"sent {target} bytes, stress test finished")


@cocotb.test()
async def not_ready(dut):
    """tests valid/ready interface"""

    WORD_WIDTH = dut.WORD_WIDTH.value.to_unsigned()
    uart_tx = await init_dut(dut)

    dut.rd_ready.value = 0
    # add some "aysnchronicity"
    await ClockCycles(dut.clk, randint(2, dut.baud_gen0.M.value.to_unsigned()))

    to_send = getrandbits(WORD_WIDTH)
    await uart_tx.send_byte(to_send)

    while int(dut.rd_valid.value) != 1:
        await RisingEdge(dut.clk)

    received = int(dut.rd_data.value)
    dut._log.info(f"byte received: 0x{received:02x}")
    assert received == to_send

    # check that data is not read
    for _ in range(5):
        await RisingEdge(dut.clk)
        assert int(dut.rd_valid.value) == 1

    dut._log.info("not ready test finished")


# TODO: test parity error, frame error, buffer overrun error


@pytest.mark.parametrize("parity", ["0", "1"])
def test_uart_rx_runner(parity: int):
    sim = runner.Icarus()
    root = Path(str(os.getenv("ROOT"))) / "hdl"
    module = "uart_rx"

    sources = [
        f"uart/{module}.v",
        "uart/flag_buf.v",
        "uart/uart_rx_des.v",
        "uart/baud_gen.v",
    ]
    sources = [root / s for s in sources]

    sim.build(
        sources=sources,
        includes=[root, root / "uart"],
        hdl_toplevel=module,
        timescale=("1ns", "1ps"),
        build_dir=f"build/build_{module}_{parity}",
        clean=True,
        waves=True,
    )

    test_opts = {
        "test_module": "test_uart_rx,",
        "waves": True,
        "extra_env": {"TB_PARITY": parity},
    }
    sim.test(hdl_toplevel=module, **test_opts)
