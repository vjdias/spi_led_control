import cocotb
from cocotb.triggers import RisingEdge

async def spi_xfer(dut, mosi_bytes):
    """Send a list of bytes over SPI (mode CPOL=1/CPHA=1).

    Uses the design clock to pace transfers so that the DUT's
    synchronizers see each edge. Returns the bytes captured on MISO."""
    miso_bytes = []
    # Idle state
    dut.spi_sclk.value = 1
    dut.spi_csn.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    dut.spi_csn.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    for byte in mosi_bytes:
        miso = 0
        for bit in range(8):
            dut.spi_mosi.value = (byte >> (7 - bit)) & 1
            await RisingEdge(dut.clk)
            await RisingEdge(dut.clk)
            dut.spi_sclk.value = 0  # leading edge (shift)
            await RisingEdge(dut.clk)
            await RisingEdge(dut.clk)
            dut.spi_sclk.value = 1  # trailing edge (sample)
            await RisingEdge(dut.clk)
            await RisingEdge(dut.clk)
            miso = (miso << 1) | int(dut.spi_miso.value)
        miso_bytes.append(miso)
    dut.spi_csn.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    return miso_bytes
