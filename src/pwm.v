// File pwm.vhd translated with vhd2vl 3.0 VHDL to Verilog RTL translator
// vhd2vl settings:
//  * Verilog Module Declaration Style: 2001

// vhd2vl is Free (libre) Software:
//   Copyright (C) 2001-2023 Vincenzo Liguori - Ocean Logic Pty Ltd
//     http://www.ocean-logic.com
//   Modifications Copyright (C) 2006 Mark Gonzales - PMC Sierra Inc
//   Modifications (C) 2010 Shankar Giri
//   Modifications Copyright (C) 2002-2023 Larry Doolittle
//     http://doolittle.icarus.com/~larry/vhd2vl/
//   Modifications (C) 2017 Rodrigo A. Melo
//
//   vhd2vl comes with ABSOLUTELY NO WARRANTY.  Always check the resulting
//   Verilog for correctness, ideally with a formal verification tool.
//
//   You are welcome to redistribute vhd2vl under certain conditions.
//   See the license (GPLv2) file included with the source for details.

// The result of translation follows.  Its copyright status should be
// considered unchanged from the original VHDL.

//--------------------------------------------------------------------------------
// Company: HES-SO AGSL
// Engineer: John Biselx
//
// Create Date: 03/28/2025 02:54:02 PM
// Design Name:
// Module Name: pwm - Behavioral
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//--------------------------------------------------------------------------------
// Uncomment the following library declaration if using
// arithmetic functions with Signed or Unsigned values
// Uncomment the following library declaration if instantiating
// any Xilinx leaf cells in this code.
//library UNISIM;
//use UNISIM.VComponents.all;
// no timescale needed

module PWM(
input wire [31:0] counter_value,
input wire [31:0] prescaler,
input wire [31:0] duty_cycle_1,
input wire [31:0] duty_cycle_2,
input wire [31:0] duty_cycle_3,
input wire clk,
input wire reset_n,
input wire enable,
output reg [2:0] pwm_out
);

reg [31:0] counter0;
reg [31:0] counter1;
reg [31:0] counter2;
reg [31:0] prescaler0;
reg [31:0] prescaler1;
reg [31:0] prescaler2;

  always @(negedge reset_n or posedge clk) begin
    if(reset_n == 1'b0) begin
      pwm_out[0] <= 1'b0;
      counter0 <= 0;
      prescaler0 <= 0;
    end else begin
      if((enable == 1'b1)) begin
        if((prescaler0 >= (prescaler))) begin
          prescaler0 <= 0;
          if((counter0 >= (counter_value))) begin
            counter0 <= 0;
          end
          else begin
            counter0 <= counter0 + 1;
          end
        end
        else begin
          prescaler0 <= prescaler0 + 1;
        end
        if((counter0 < (duty_cycle_1))) begin
          pwm_out[0] <= 1'b1;
        end
        else begin
          pwm_out[0] <= 1'b0;
        end
      end
      else begin
        prescaler0 <= 0;
        counter0 <= 0;
        pwm_out[0] <= 1'b0;
      end
    end
  end

  always @(negedge reset_n or posedge clk) begin
    if((reset_n == 1'b0)) begin
      pwm_out[1] <= 1'b0;
      counter1 <= 0;
      prescaler1 <= 1'b0;
    end else begin
      if((enable == 1'b1)) begin
        if((prescaler1 >= (prescaler))) begin
          prescaler1 <= 0;
          if((counter1 >= (counter_value))) begin
            counter1 <= 0;
          end
          else begin
            counter1 <= counter1 + 1;
          end
        end
        else begin
          prescaler1 <= prescaler1 + 1;
        end
        if((counter1 < (duty_cycle_2))) begin
          pwm_out[1] <= 1'b1;
        end
        else begin
          pwm_out[1] <= 1'b0;
        end
      end
      else begin
        prescaler1 <= 0;
        counter1 <= 0;
        pwm_out[1] <= 1'b0;
      end
    end
  end

  always @(negedge reset_n or posedge clk) begin
    if((reset_n == 1'b0)) begin
      pwm_out[2] <= 1'b0;
      counter2 <= 0;
      prescaler2 <= 0;
    end else begin
      if((enable == 1'b1)) begin
        if((prescaler2 >= (prescaler))) begin
          prescaler2 <= 0;
          if((counter2 >= (counter_value))) begin
            counter2 <= 0;
          end
          else begin
            counter2 <= counter2 + 1;
          end
        end
        else begin
          prescaler2 <= prescaler2 + 1;
        end
        if((counter2 < (duty_cycle_3))) begin
          pwm_out[2] <= 1'b1;
        end
        else begin
          pwm_out[2] <= 1'b0;
        end
      end
      else begin
        prescaler2 <= 0;
        counter2 <= 0;
        pwm_out[2] <= 1'b0;
      end
    end
  end


endmodule
