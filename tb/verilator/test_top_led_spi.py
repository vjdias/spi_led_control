import sys
import os
from pathlib import Path
sys.path.append(str(Path(__file__).parent))

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb_test.simulator import run

from spi_master import spi_xfer

@cocotb.test()
async def led_command_flow(dut):
    """Send a LED command frame over SPI and check response and LED output."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst_n.value = 0
    dut.spi_sclk.value = 1
    dut.spi_csn.value = 1
    dut.spi_mosi.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Request: set LED2 ON with ID=0x11
    req = [0xAA, 0x30, 0x11, 0x02, 0x01, 0x55]
    await spi_xfer(dut, req)

    # Wait a bit for pipeline to process
    await Timer(100, units="ns")

    # Read response in a new transaction
    rsp = await spi_xfer(dut, [0x00] * 7)
    assert len(rsp) == 7


def test_top_led_spi(tmp_path):
    root = Path(__file__).resolve().parents[2]
    src = root / "src"
    verilog_sources = [
        str(src / "top" / "top_led_spi.sv"),
        str(src / "drivers" / "spi_slave_8.sv"),
        str(src / "drivers" / "spi_stream_bridge.sv"),
        str(src / "services" / "led_service.sv"),
        str(src / "services" / "main_service.sv"),
        str(src / "protocol" / "protocol_rx.sv"),
        str(src / "protocol" / "protocol_tx.sv"),
        str(src / "protocol" / "formatters" / "tx_formatter_led.sv"),
        str(src / "protocol" / "formatters" / "tx_arbiter.sv"),
        str(src / "protocol" / "parsers" / "rx_router.sv"),
        str(src / "protocol" / "parsers" / "rx_parser_led.sv"),
        str(src / "protocol" / "codecs" / "codec_led.sv"),
        str(src / "protocol" / "interfaces" / "cmd_if_led.sv"),
        str(src / "protocol" / "interfaces" / "stream_if.sv"),
        str(src / "protocol" / "messages" / "msg_led.sv"),
        str(src / "protocol" / "framings" / "framing_pkg.sv"),
        str(src / "protocol" / "cmd" / "led_cmd_pkg.sv"),
    ]
    run(
        simulator="verilator",
        verilog_sources=verilog_sources,
        toplevel="top_led_spi",
        module=os.path.splitext(os.path.basename(__file__))[0],
        includes=[str(root)],
        compile_args=["-Wno-fatal"],
        sim_build=str(tmp_path),
        parameters={"NUM_LEDS": 5},
        python_search=[str(Path(__file__).parent)],
        verilator_generate_vcd=True,
    )
