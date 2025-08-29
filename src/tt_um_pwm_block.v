/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_pwm_block (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  assign uio_oe = 8'b00101111; // set data directions
  assign uio_out[4:0] = 5'b0_zzzz; // all unused outputs are assigned
  assign uio_out[7:6] = 2'b00;
  assign uo_out[7:3] = 5'b00000;


wire [31:0] counter_value,
            prescaler,
            duty_cycle_1,
            duty_cycle_2,
            duty_cycle_3;
wire        enable_pwm;
wire [7:0] rx_byte;
wire rx_dv;
wire [7:0] tx_byte;
wire tx_dv;

  SPI_Slave #(.SPI_MODE(0)) spi_module
          (
          // Control/Data Signals,
          rst_n,    // FPGA Reset, active low
          clk,      // FPGA Clock
          rx_dv,    // Data Valid pulse (1 clock cycle)
          rx_byte,  // Byte received on MOSI
          tx_dv,    // Data Valid pulse to register i_TX_Byte
          tx_byte,  // Byte to serialize to MISO.

          // SPI Interface
          uio_in[4],
          uio_out[5],
          uio_in[6],
          uio_in[7]        // active low
          );
  
  MemoryManager MemCell(
                    rst_n,    // Reset, active low
                    clk,      // Clock

                    // Control/Data Signals flowing between SPI Slave and this module
                    rx_dv,    // Data Valid pulse (1 clock cycle)
                    rx_byte,  // Byte received on MOSI
                    tx_dv,    // Data Valid pulse to register i_TX_Byte
                    tx_byte,  // Byte to serialize to MISO.

                    // outputs flowing over to the pwm module
                    counter_value,
                    prescaler,
                    duty_cycle_1,
                    duty_cycle_2,
                    duty_cycle_3,
                    enable_pwm
  );

  PWM    pwm_module(
            counter_value,
            prescaler,
            duty_cycle_1,
            duty_cycle_2,
            duty_cycle_3,
            clk,
            rst_n,
            enable_pwm,
            uo_out[2:0]
  );

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in, uio_in[3:0], uio_in[5], 1'b0};

endmodule
