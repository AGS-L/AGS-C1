# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Edge, Timer
from cocotb.handle import ModifiableObject
from cocotb.result import TestFailure

@cocotb.test()
async def test_send_multiple_payloads(dut):
    clk = dut.clk

    # Start the clock if not driven externally
    cocotb.start_soon(Clock(clk, 10, units="ns").start())  # Adjust clock period as needed

    # Wait for 10 clock cycles
    for _ in range(10):
        await RisingEdge(clk)

    dut.rst_n.value = 0
    for _ in range(10):
        await RisingEdge(clk)

    dut.rst_n.value = 1
    for _ in range(10):
        await RisingEdge(clk)

    # Define payloads
    payloads = [
        [0x01, 0xFF, 0x00, 0x00, 0x00],
        [0x03, 0x0F, 0x00, 0x00, 0x00],
        [0x04, 0x02, 0x00, 0x00, 0x00],
        [0x05, 0x5F, 0x00, 0x00, 0x00],
        [0x07],
    ]

    delays = [200, 200, 200, 200, 1000]  # Delay after each payload

    for payload, delay in zip(payloads, delays):
        await send_multi_byte(dut, payload, len(payload))
        for _ in range(delay):
            await RisingEdge(clk)

    # Simulation done
    dut._log.info("Test completed. Finishing simulation.")

    
@cocotb.coroutine
async def send_multi_byte(dut, data: list[int], length: int):
    """
    Send multiple bytes using SPI-like signaling.

    Args:
        dut: The device under test handle.
        data: A list of 8-bit integers to be sent.
        length: Number of bytes to send from the list.
    """

    clk = dut.clk

    # Wait for clock posedge
    await RisingEdge(clk)
    dut.r_Master_CS_n.value = 0  # Active low CS

    for i in range(length):
        await RisingEdge(clk)
        dut.r_Master_TX_Byte.value = data[i]
        dut.r_Master_TX_DV.value = 1

        await RisingEdge(clk)
        dut.r_Master_TX_DV.value = 0

        # Wait for w_Master_TX_Ready to go high (positive edge)
        await RisingEdge(dut.w_Master_TX_Ready)

    dut.r_Master_CS_n.value = 1  # Deactivate CS
