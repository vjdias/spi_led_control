import sys, os
from pathlib import Path
sys.path.append(str(Path(__file__).parent))

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb_test.simulator import run

@cocotb.test()
async def stream_bridge_basic(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst_n.value = 0
    dut.rx_byte_valid.value = 0
    dut.rx_byte.value = 0
    dut.tx_byte_ready.value = 0
    dut.rx_stream_if.ready.value = 0
    dut.tx_stream_if.valid.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Test RX path: byte -> stream
    dut.rx_stream_if.ready.value = 1
    dut.rx_byte.value = 0x3C
    dut.rx_byte_valid.value = 1
    await RisingEdge(dut.clk)
    assert int(dut.rx_stream_if.valid.value) == 1
    assert int(dut.rx_stream_if.data.value) == 0x3C
    assert int(dut.rx_byte_ready.value) == 1
    dut.rx_byte_valid.value = 0
    dut.rx_stream_if.ready.value = 0
    await RisingEdge(dut.clk)

    # Test TX path: stream -> byte
    dut.tx_stream_if.valid.value = 1
    dut.tx_stream_if.data.value = 0xA5
    dut.tx_byte_ready.value = 1
    await RisingEdge(dut.clk)
    assert int(dut.tx_byte_valid.value) == 1
    assert int(dut.tx_byte.value) == 0xA5
    assert int(dut.tx_stream_if.ready.value) == 1
    dut.tx_stream_if.valid.value = 0
    dut.tx_byte_ready.value = 0
    await RisingEdge(dut.clk)


def test_spi_stream_bridge(tmp_path):
    root = Path(__file__).resolve().parents[2]
    verilog_sources = [
        str(root / "src" / "drivers" / "spi_stream_bridge.sv"),
        str(root / "tb" / "verilator" / "spi_stream_bridge_tb.sv"),
    ]
    run(
        simulator="verilator",
        verilog_sources=verilog_sources,
        toplevel="spi_stream_bridge_tb",
        module=os.path.splitext(os.path.basename(__file__))[0],
        includes=[str(root)],
        compile_args=["-Wno-fatal"],
        sim_build=str(Path(__file__).parent / "sim_build" / "spi_stream_bridge"),
        python_search=[str(Path(__file__).parent)],
        waves=True,
        plus_args=["--trace"],
    )
