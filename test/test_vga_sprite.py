import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
import random

async def reset(dut):
    dut.reset <= 1

    await ClockCycles(dut.clk, 5)
    dut.reset <= 0


@cocotb.test()
async def test_vga_sprite(dut):
    clock = Clock(dut.clk, 10, units="us")
    cocotb.fork(clock.start())

    await reset(dut)

    dut.start_time_0 <= 4;
    dut.start_time_1 <= 40;
    dut.start_time_2 <= 80;

    dut.sprite_pixels <= 0xc0000002
    dut.sprite_pixel_size <= 0;

    for i in range(200):
        dut.h_counter <= i
        await ClockCycles(dut.clk, 1)

@cocotb.test()
async def test_vga_sprite_wider(dut):
    clock = Clock(dut.clk, 10, units="us")
    cocotb.fork(clock.start())

    await reset(dut)

    dut.start_time_0 <= 4;
    dut.start_time_1 <= 40;
    dut.start_time_2 <= 80;

    dut.sprite_pixels <= 0xc0000002
    dut.sprite_pixel_size <= 1;

    for i in range(200):
        dut.h_counter <= i
        await ClockCycles(dut.clk, 1)
