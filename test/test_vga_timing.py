import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
import random

async def reset(dut):
    dut.reset <= 1

    await ClockCycles(dut.clk, 5)
    dut.reset <= 0;

    dut.enabled <= 1;

    dut.h_sync_start <= 18;
    dut.h_sync_end <= 36;
    dut.h_active_start <= 63;
    dut.h_active_end <= 276;
    dut.h_pol <= 0;

    dut.v_sync_start <= 1;
    dut.v_sync_end <= 3;
    dut.v_active_start <= 28;
    dut.v_active_end <= 508;
    dut.v_pol <= 0;


@cocotb.test()
async def test_vga_timing(dut):
    clock = Clock(dut.clk, 10, units="us")
    cocotb.fork(clock.start())

    await reset(dut)
    
    await ClockCycles(dut.clk, 800 * 50)
