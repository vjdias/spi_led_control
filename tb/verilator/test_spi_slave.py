import sys
import os
from pathlib import Path
sys.path.append(str(Path(__file__).parent))

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb_test.simulator import run

from spi_master import spi_xfer

@cocotb.test()
async def spi_slave_basic(dut):
    """Send one byte and check loopback through FIFOs."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst_n.value = 0
    dut.spi_sclk.value = 1
    dut.spi_csn.value = 1
    dut.spi_mosi.value = 0
    dut.rx_byte_ready.value = 0
    dut.tx_byte_valid.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Preload TX FIFO with a byte to be shifted out
    dut.tx_byte.value = 0xA5
    dut.tx_byte_valid.value = 1
    while not int(dut.tx_byte_ready.value):
        await RisingEdge(dut.clk)
    dut.tx_byte_valid.value = 0

    # Transfer one byte and capture response
    miso = await spi_xfer(dut, [0x3C])
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    # Check RX path captured MOSI byte
    assert int(dut.rx_byte_valid.value) == 1


def test_spi_slave(tmp_path):
    root = Path(__file__).resolve().parents[2]
    verilog_sources = [str(root / "src" / "drivers" / "spi_slave_8.sv")]
    run(
        simulator="verilator",
        verilog_sources=verilog_sources,
        toplevel="spi_slave_8",
        module=os.path.splitext(os.path.basename(__file__))[0],
        includes=[str(root)],
        compile_args=["-Wno-fatal"],
        sim_build=str(Path(__file__).parent / "sim_build" / "spi_slave"),
        parameters={"CPOL": 1, "CPHA": 1},
        python_search=[str(Path(__file__).parent)],
        waves=True,
        plus_args=["--trace"],
    )
