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
async def test_vga_core_timing(dut):
    vga = VgaTest(dut)
    await vga.reset()

    # reg 0c:
    await vga.wbs.send_cycle([WBOp(0x3000000c, dat=0xc0000002)])

    # reg 10:
    await vga.wbs.send_cycle([WBOp(0x30000010, dat=0x40000002)])

    # background colors
    await vga.wbs.send_cycle([WBOp(0x3000001c, dat=0x00a00000)])
    await vga.wbs.send_cycle([WBOp(0x30000020, dat=0x000b000c)])

    # reg 14:
    # background 0 size = 6 (000110)
    # background 1 size = 6 (000110)
    # = 0x186
    await vga.wbs.send_cycle([WBOp(0x30000014, dat=0x186)])

    # reg 00:
    # h_sync_start = 18 (00 0001 0010)
    # h_sync_end = 36 (00 0010 0100)
    # h_active_start = 63 (00 0011 1111)
    # = 0x120903f
    await vga.wbs.send_cycle([WBOp(0x30000000, dat=0x120903f)])

    # reg 04:
    # v_sync_start = 1 (00 0000 0001)
    # v_sync_end = 3 (00 0000 0011)
    # v_active_start = 28 (00 0001 1100)
    # = 0x100c1c
    await vga.wbs.send_cycle([WBOp(0x30000004, dat=0x100c1c)])

    # reg 08:
    # enabled = 1 (1)
    # h_pol = 0 (0)
    # v_pol = 0 (0)
    # h_active_end = 276 (01 0001 0100)
    # v_active_end = 508 (01 1111 1100)
    # = 0x4451fc
    await vga.wbs.send_cycle([WBOp(0x30000008, dat=0x4451fc)])

    # reg 18:
    # check v active = 1
    # check h active = 0
    # check vertical count = 0
    # check horizontal count = 1
    # expected v active = 1
    # expected h active = 0
    # expected vertical count = 0 (00 0000 0000)
    # expected horizontal count = 0 (00 0000 0001)
    # = 0x2600001
    await vga.wbs.send_cycle([WBOp(0x30000018, dat=0x2600001)])
    await vga.wbs.send_cycle([WBOp(0x30000018, dat=0x2600001)])

    await ClockCycles(dut.clk, 800 * 50)


@cocotb.test()
async def test_vga_core_collision(dut):
    vga = VgaTest(dut)
    await vga.reset()

    # background pixels 0, 1
    await vga.wbs.send_cycle([WBOp(0x3000000c, dat=0x55555555)])
    await vga.wbs.send_cycle([WBOp(0x30000010, dat=0x55555555)])

    # background colors
    await vga.wbs.send_cycle([WBOp(0x3000001c, dat=0x00f00000)])
    await vga.wbs.send_cycle([WBOp(0x30000020, dat=0x000f000f)])

    # sprite 0 pixels, colors, start position
    await vga.wbs.send_cycle([WBOp(0x30000028, dat=0xffffffff)])
    await vga.wbs.send_cycle([WBOp(0x30000024, dat=46)])
    await vga.wbs.send_cycle([WBOp(0x3000002c, dat=0x00000fff)])
    await vga.wbs.send_cycle([WBOp(0x30000030, dat=0x00ffffff)])

    # sprite 1 pixels
    await vga.wbs.send_cycle([WBOp(0x30000038, dat=0x55555555)])
    await vga.wbs.send_cycle([WBOp(0x30000034, dat=56)])
    await vga.wbs.send_cycle([WBOp(0x3000003c, dat=0x00000fff)])
    await vga.wbs.send_cycle([WBOp(0x30000040, dat=0x00ffffff)])

    # sprite 2 pixels
    await vga.wbs.send_cycle([WBOp(0x30000048, dat=0x55555555)])
    await vga.wbs.send_cycle([WBOp(0x3000004c, dat=0x00000fff)])
    await vga.wbs.send_cycle([WBOp(0x30000050, dat=0x00ffffff)])

    # reg 00:
    # h_sync_start = 1 (00 0000 0001)
    # h_sync_end = 2 (00 0000 0010)
    # h_active_start = 40 (00 0010 1000)
    # = 0x100828
    await vga.wbs.send_cycle([WBOp(0x30000000, dat=0x100828)])

    # reg 04:
    # v_sync_start = 1 (00 0000 0001)
    # v_sync_end = 2 (00 0000 0010)
    # v_active_start = 3 (00 0000 0011)
    # = 0x100803
    await vga.wbs.send_cycle([WBOp(0x30000004, dat=0x100803)])

    # reg 08:
    # enabled = 1 (1)
    # h_pol = 0 (0)
    # v_pol = 0 (0)
    # h_active_end = 71 (00 0100 0111)
    # v_active_end = 10 (00 0000 1010)
    # = 0x411C0A
    await vga.wbs.send_cycle([WBOp(0x30000008, dat=0x411C0A)])

    # Read collision register (to reset it)
    await vga.wbs.send_cycle([WBOp(0x30000000)]);

    # Wait for end of retrace
    await vga.wbs.send_cycle([WBOp(0x30000018, dat=0x2200000)])
    await vga.wbs.send_cycle([WBOp(0x30000018, dat=0x2000000)])

    # Read collision register
    collision_result = await vga.wbs.send_cycle([WBOp(0x30000000)])
    values = [wb.datrd for wb in collision_result]

    dut.log.info(f"Returned Results: {values}")


    await ClockCycles(dut.clk, 800 * 50)
