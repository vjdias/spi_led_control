import sys
import os
from pathlib import Path
sys.path.append(str(Path(__file__).parent))

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb_test.simulator import run


async def spi_xfer_cpha0(dut, byte):
    dut.spi_sclk.value = 1
    dut.spi_csn.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.spi_csn.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    for bit in range(8):
        dut.spi_mosi.value = (byte >> (7 - bit)) & 1
        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)
        dut.spi_sclk.value = 0
        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)
        dut.spi_sclk.value = 1
        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)
    dut.spi_csn.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


@cocotb.test()
async def cpha0_basic(dut):
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

    await spi_xfer_cpha0(dut, 0xA5)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    assert int(dut.rx_byte_valid.value) == 1


def test_spi_slave_cpha0(tmp_path):
    root = Path(__file__).resolve().parents[2]
    verilog_sources = [str(root / "src" / "drivers" / "spi_slave_8.sv")]
    run(
        simulator="verilator",
        verilog_sources=verilog_sources,
        toplevel="spi_slave_8",
        module=os.path.splitext(os.path.basename(__file__))[0],
        includes=[str(root)],
        compile_args=["-Wno-fatal"],
        sim_build=str(Path(__file__).parent / "sim_build" / "spi_slave_cpha0"),
        parameters={"CPOL": 1, "CPHA": 0},
        python_search=[str(Path(__file__).parent)],
        waves=True,
        plus_args=["--trace"],
    )

