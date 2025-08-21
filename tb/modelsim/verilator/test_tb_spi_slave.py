import subprocess
from pathlib import Path

def test_tb_spi_slave():
    root = Path(__file__).resolve().parents[3]
    build = Path(__file__).parent / "sim_build" / "tb_spi_slave"
    build.mkdir(parents=True, exist_ok=True)
    cmd = [
        "verilator", "-sv", "--binary",
        str(root / "tb" / "modelsim" / "tb_spi_slave.sv"),
        str(root / "src" / "drivers" / "spi_slave_8.sv"),
        "--Mdir", str(build),
    ]
    subprocess.run(cmd, check=True, cwd=root)
    subprocess.run([str(build / "Vtb_spi_slave")], check=True)
