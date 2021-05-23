import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
import random

async def reset(dut):
    dut.reset <= 1

    await ClockCycles(dut.clk, 5)
    dut.reset <= 0


@cocotb.test()
async def test_vga_background_simple(dut):
    clock = Clock(dut.clk, 10, units="us")
    cocotb.fork(clock.start())

    await reset(dut)

    dut.h_active <= 0;
    dut.v_active <= 1
    dut.bg_size_0 <= 1
    dut.bg_size_1 <= 1

    dut.bg_pixels <= 0xc0000002
    dut.bg_pixels_load_0 <= 1
    dut.bg_pixels_load_1 <= 0

    await ClockCycles(dut.clk, 1)

    dut.bg_pixels <= 0x40000002
    dut.bg_pixels_load_0 <= 0
    dut.bg_pixels_load_1 <= 1

    await ClockCycles(dut.clk, 1)

    dut.bg_pixels_load_0 <= 0
    dut.bg_pixels_load_1 <= 0

    for i in range(3):
        await ClockCycles(dut.clk, 2)

        dut.h_active <= 1;

        await ClockCycles(dut.clk, 64)

        dut.h_active <= 0;

        await ClockCycles(dut.clk, 2)


@cocotb.test()
async def test_vga_background_repeat_0(dut):
    clock = Clock(dut.clk, 10, units="us")
    cocotb.fork(clock.start())

    await reset(dut)

    dut.h_active <= 0;
    dut.v_active <= 1
    dut.bg_size_0 <= 1
    dut.bg_size_1 <= 0

    dut.bg_pixels <= 0xc0000002
    dut.bg_pixels_load_0 <= 1
    dut.bg_pixels_load_1 <= 0

    await ClockCycles(dut.clk, 1)

    dut.bg_pixels <= 0x40000002
    dut.bg_pixels_load_0 <= 0
    dut.bg_pixels_load_1 <= 1

    await ClockCycles(dut.clk, 1)

    dut.bg_pixels_load_0 <= 0
    dut.bg_pixels_load_1 <= 0

    for i in range(3):
        await ClockCycles(dut.clk, 2)

        dut.h_active <= 1;

        await ClockCycles(dut.clk, 80)

        dut.h_active <= 0;

        await ClockCycles(dut.clk, 2)

