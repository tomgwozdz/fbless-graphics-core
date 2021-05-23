import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
import random

async def reset(dut):
    dut.reset <= 1
    dut.h_pol <= 0;
    dut.v_pol <= 0;

    await ClockCycles(dut.clk, 5)
    dut.reset <= 0;


@cocotb.test()
async def test_vga_timing(dut):
    clock = Clock(dut.clk, 10, units="us")
    cocotb.fork(clock.start())

    await reset(dut)

    dut.enabled <= 1;

    dut.h_sync_start <= 3;
    dut.h_sync_end <= 7;
    dut.h_active_start <= 11;
    dut.h_active_end <= 19;
    dut.h_pol <= 0;

    dut.v_sync_start <= 2;
    dut.v_sync_end <= 3;
    dut.v_active_start <= 5;
    dut.v_active_end <= 7;
    dut.v_pol <= 0;
    
    await ClockCycles(dut.clk, 50 * 50)
