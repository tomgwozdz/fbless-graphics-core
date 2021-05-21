import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
from cocotbext.wishbone.driver import WishboneMaster
from cocotbext.wishbone.driver import WBOp


class VgaTest(object):
    def __init__(self, dut):
        self._dut = dut

        self.clock = Clock(self._dut.clk, 10, units="us")
        self._clock_thread = cocotb.fork(self.clock.start())

        self.wbs = WishboneMaster(dut, "wb", self._dut.clk, width = 32, signals_dict = {
                "cyc": "cyc_i",
                "stb": "stb_i",
                "we": "we_i",
                "adr": "addr_i",
                "datwr": "data_i",
                "datrd": "data_o",
                "ack": "ack_o",
                "sel": "sel_i"
            })

    async def reset(self):
        self._dut.reset <= 1
        await ClockCycles(self._dut.clk, 5)
        self._dut.reset <= 0;


@cocotb.test()
async def test_vga_core(dut):
    vga = VgaTest(dut)
    await vga.reset()

    # reg 0:
    # h_sync_start = 18 (00 0001 0010 )
    # h_sync_end = 36 (00 0010 0100)
    # h_active_start = 63 (00 0011 1111)
    # = 0x120903f
    await vga.wbs.send_cycle([WBOp(0x04000000, dat=0x120903f)])

    # reg 4:
    # v_sync_start = 1 (00 0000 0001)
    # v_sync_end = 3 (00 0000 0011)
    # v_active_start = 28 (00 0001 1100)
    # = 0x100c1c
    await vga.wbs.send_cycle([WBOp(0x04000004, dat=0x100c1c)])

    # reg 8:
    # enabled = 1 (1)
    # h_pol = 0 (0)
    # v_pol = 0 (0)
    # h_active_end = 276 (01 0001 0100)
    # v_active_end = 508 (01 1111 1100)
    # = 0x4451fc
    await vga.wbs.send_cycle([WBOp(0x04000008, dat=0x4451fc)])

    await ClockCycles(dut.clk, 800 * 50)
