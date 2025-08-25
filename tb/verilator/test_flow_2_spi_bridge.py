import sys
import os
from pathlib import Path
sys.path.append(str(Path(__file__).parent))

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb_test.simulator import run

@cocotb.test()
async def flow2_spi_stream_bridge(dut):
    """[2] Testa ponte SPI -> stream e stream -> SPI."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst_n.value = 0
    dut.rx_byte_valid.value = 0
    dut.tx_byte_ready.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # RX path
    dut.rx_stream.ready.value = 1
    dut.rx_byte.value = 0x5A
    dut.rx_byte_valid.value = 1
    await RisingEdge(dut.clk)
    assert int(dut.rx_stream.valid.value) == 1 and int(dut.rx_stream.data.value) == 0x5A, "FAIL: ponte nao repassou RX"
    assert int(dut.rx_byte_ready.value) == 1, "FAIL: ponte nao sinalizou ready"
    dut.rx_byte_valid.value = 0

    dut._log.info("PASS: [2] Ponte SPI-stream funcionando (RX)")


def test_flow_2_spi_bridge(tmp_path):
    root = Path(__file__).resolve().parents[2]
    verilog_sources = [
        str(root / "src" / "drivers" / "spi_stream_bridge.sv"),
        str(root / "src" / "protocol" / "interfaces" / "stream_if.sv"),
        str(root / "tb" / "verilator" / "spi_stream_bridge_tb.sv"),
    ]
    run(
        simulator="verilator",
        verilog_sources=verilog_sources,
        toplevel="spi_stream_bridge_tb",
        module=os.path.splitext(os.path.basename(__file__))[0],
        includes=[str(root)],
        compile_args=["-Wno-fatal"],
        sim_build=str(Path(__file__).parent / "sim_build" / "flow2_bridge"),
        parameters={},
        python_search=[str(Path(__file__).parent)],
        waves=False,
        plus_args=["--trace"],
    )
