import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
import random

async def reset(dut):
    dut.reset <= 1

    await ClockCycles(dut.clk, 5)
    dut.reset <= 0;

@cocotb.test()
async def test_vga_timing(dut):
    clock = Clock(dut.clk, 10, units="us")
    cocotb.fork(clock.start())

    await reset(dut)
    
    await ClockCycles(dut.clk, 800 * 50)
