import os
import glob
import pytest
from cocotb_test.simulator import run
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


@pytest.mark.parametrize("num_leds", [5])
def test_top_led_spi(request, num_leds):
    repo_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    verilog_sources = [
        os.path.join(repo_dir, f)
        for f in glob.glob("src/**/*.sv", recursive=True)
        if "src/tb" not in f
    ]
    sim_build = os.path.join(repo_dir, "sim_build", request.node.name)
    module = os.path.splitext(os.path.basename(__file__))[0]
    run(
        verilog_sources=verilog_sources,
        toplevel="top_led_spi",
        module=module,
        includes=[repo_dir],
        parameters={"NUM_LEDS": num_leds},
        sim_build=sim_build,
        simulator="verilator",
        compile_args=["--Wno-BLKANDNBLK", "--Wno-WIDTHEXPAND"],
    )


@cocotb.test()
async def basic_reset(dut):
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    dut.rst_n.value = 0
    dut.spi_sclk.value = 0
    dut.spi_csn.value = 1
    dut.spi_mosi.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    for _ in range(5):
        await RisingEdge(dut.clk)
    assert dut.leds.value.integer == 0
