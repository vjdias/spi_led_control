import sys, os
from pathlib import Path
sys.path.append(str(Path(__file__).parent))

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb_test.simulator import run

@cocotb.test()
async def led_service_handles_requests(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst_n.value = 0
    dut.led_if.req_valid.value = 0
    dut.led_if.rsp_ready.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Turn LED2 on
    dut.led_if.req.value = (0x01 << 4) | (2 << 1) | 1
    dut.led_if.req_valid.value = 1
    while not int(dut.led_if.req_ready.value):
        await RisingEdge(dut.clk)
    dut.led_if.req_valid.value = 0
    while not int(dut.led_if.rsp_valid.value):
        await RisingEdge(dut.clk)
    dut.led_if.rsp_ready.value = 1
    while not int(dut.service_done.value):
        await RisingEdge(dut.clk)
    dut.led_if.rsp_ready.value = 0
    assert int(dut.leds.value) & (1 << 2)

    # Turn LED2 off
    dut.led_if.req.value = (0x02 << 4) | (2 << 1)
    dut.led_if.req_valid.value = 1
    while not int(dut.led_if.req_ready.value):
        await RisingEdge(dut.clk)
    dut.led_if.req_valid.value = 0
    while not int(dut.led_if.rsp_valid.value):
        await RisingEdge(dut.clk)
    dut.led_if.rsp_ready.value = 1
    while not int(dut.service_done.value):
        await RisingEdge(dut.clk)
    dut.led_if.rsp_ready.value = 0
    assert int(dut.leds.value) & (1 << 2) == 0

    # Invalid index
    prev = int(dut.leds.value)
    dut.led_if.req.value = (0x03 << 4) | (7 << 1) | 1
    dut.led_if.req_valid.value = 1
    while not int(dut.led_if.req_ready.value):
        await RisingEdge(dut.clk)
    dut.led_if.req_valid.value = 0
    while not int(dut.led_if.rsp_valid.value):
        await RisingEdge(dut.clk)
    dut.led_if.rsp_ready.value = 1
    while not int(dut.service_done.value):
        await RisingEdge(dut.clk)
    dut.led_if.rsp_ready.value = 0
    assert int(dut.leds.value) == prev
    assert int(dut.led_if.rsp.value) & 1 == 0


def test_led_service_unit(tmp_path):
    root = Path(__file__).resolve().parents[2]
    verilog_sources = [
        str(root / "src" / "services" / "led_service.sv"),
        str(root / "src" / "protocol" / "interfaces" / "cmd_if_led.sv"),
        str(root / "src" / "protocol" / "messages" / "msg_led.sv"),
        str(root / "tb" / "verilator" / "led_service_tb.sv"),
    ]
    run(
        simulator="verilator",
        verilog_sources=verilog_sources,
        toplevel="led_service_tb",
        module=os.path.splitext(os.path.basename(__file__))[0],
        includes=[str(root)],
        compile_args=["-Wno-fatal"],
        sim_build=str(Path(__file__).parent / "sim_build" / "led_service"),
        parameters={"NUM_LEDS": 5},
        python_search=[str(Path(__file__).parent)],
        waves=True,
        plus_args=["--trace"],
    )
