import subprocess
from pathlib import Path

def test_tb_top_led_spi():
    root = Path(__file__).resolve().parents[3]
    build = Path(__file__).parent / "sim_build" / "tb_top_led_spi"
    build.mkdir(parents=True, exist_ok=True)
    sources = [
        root / "src" / "top" / "top_led_spi.sv",
        root / "src" / "drivers" / "spi_slave_8.sv",
        root / "src" / "drivers" / "spi_stream_bridge.sv",
        root / "src" / "services" / "led_service.sv",
        root / "src" / "services" / "main_service.sv",
        root / "src" / "protocol" / "protocol_rx.sv",
        root / "src" / "protocol" / "protocol_tx.sv",
        root / "src" / "protocol" / "formatters" / "tx_formatter_led.sv",
        root / "src" / "protocol" / "formatters" / "tx_arbiter.sv",
        root / "src" / "protocol" / "parsers" / "rx_router.sv",
        root / "src" / "protocol" / "parsers" / "rx_parser_led.sv",
        root / "src" / "protocol" / "codecs" / "codec_led.sv",
        root / "src" / "protocol" / "interfaces" / "cmd_if_led.sv",
        root / "src" / "protocol" / "interfaces" / "stream_if.sv",
        root / "src" / "protocol" / "messages" / "msg_led.sv",
        root / "src" / "protocol" / "framings" / "framing_pkg.sv",
        root / "src" / "protocol" / "cmd" / "led_cmd_pkg.sv",
    ]
    cmd = [
        "verilator", "-sv", "--binary",
        str(root / "tb" / "modelsim" / "tb_top_led_spi.sv"),
        "--Mdir", str(build),
    ] + [str(s) for s in sources]
    subprocess.run(cmd, check=True, cwd=root)
    subprocess.run([str(build / "Vtb_top_led_spi")], check=True)
