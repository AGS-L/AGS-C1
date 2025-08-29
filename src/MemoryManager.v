
/*
    module PWM(
input wire [data_length - 1:0] counter_value,
input wire [data_length - 1:0] prescaler,
input wire [data_length - 1:0] duty_cycle_1,
input wire [data_length - 1:0] duty_cycle_2,
input wire [data_length - 1:0] duty_cycle_3,
input wire clk,
input wire reset_n,
input wire enable,
output reg [3 - 1:0] pwm_out
);

*/

module MemoryManager(
    input wire        i_Rst_L,    // Reset, active low
    input wire        i_Clk,      // Clock

    // Control/Data Signals flowing between SPI Slave and this module
    input wire        o_RX_DV,    // Data Valid pulse (1 clock cycle)
    input wire [7:0]  o_RX_Byte,  // Byte received on MOSI
    output            i_TX_DV,    // Data Valid pulse to register i_TX_Byte
    output  [7:0]     i_TX_Byte,  // Byte to serialize to MISO.

    // outputs flowing over to the encryption module
    output wire [31:0]  counter_value,
                        prescaler,
                        duty_cycle_1,
                        duty_cycle_2,
                        duty_cycle_3,
    output reg          enable_pwm
);

assign i_TX_DV = 1'b0;
assign i_TX_Byte = 8'd0;

reg [7:0] cv_reg        [3:0]; // ordered smallest up, keys[0] is the lower 8 bits of io_key_0
reg [7:0] prescale_reg  [3:0]; // ordered likewise, nonces[0] is the lower 8 bits of io_nonce_0
reg [7:0] dc1_reg       [3:0];
reg [7:0] dc2_reg       [3:0];
reg [7:0] dc3_reg       [3:0];
reg should_write; // this wire is an enable signal for writing into memory - high to enable

assign counter_value = {cv_reg[3], cv_reg[2], cv_reg[1], cv_reg[0]};
assign prescaler = {prescale_reg[3], prescale_reg[2], prescale_reg[1], prescale_reg[0]};
assign duty_cycle_1 = {dc1_reg[3], dc1_reg[2], dc1_reg[1], dc1_reg[0]};
assign duty_cycle_2 = {dc2_reg[3], dc2_reg[2], dc2_reg[1], dc2_reg[0]};
assign duty_cycle_3 = {dc3_reg[3], dc3_reg[2], dc3_reg[1], dc3_reg[0]};

localparam IDLE             = 3'b000;
localparam WRITE_CV         = 3'b001;
localparam WRITE_PRESCALE   = 3'b010;
localparam WRITE_DC1        = 3'b011;
localparam WRITE_DC2        = 3'b100;
localparam WRITE_DC3        = 3'b101;
localparam ENABLE_PWM       = 3'b110;
localparam DISABLE_PWM      = 3'b111;


reg [2:0] curr_state;
reg [2:0] next_state;

reg [1:0] counter;
reg [1:0] next_counter;


// sequential logic for pwm bound signals
integer i;
always @(posedge i_Clk or negedge i_Rst_L) begin
    if (~i_Rst_L) begin // zero all registers on reset
        for (i = 0; i < 4; i = i + 1) begin
            cv_reg[i] <= 8'd0;
        end
        for (i = 0; i < 4; i = i + 1) begin
            prescale_reg[i] <= 8'd0;
        end
        for (i = 0; i < 4; i = i + 1) begin
            dc1_reg[i] <= 8'd0;
        end
        for (i = 0; i < 4; i = i + 1) begin
            dc2_reg[i] <= 8'd0;
        end
        for (i = 0; i < 4; i = i + 1) begin
            dc3_reg[i] <= 8'd0;
        end
        enable_pwm <= 1'b0;
    end 
    else begin
        if(curr_state == WRITE_CV && should_write == 1'b1) begin
            cv_reg[counter] <= o_RX_Byte;
        end
        if(curr_state == WRITE_DC1 && should_write == 1'b1) begin
            dc1_reg[counter] <= o_RX_Byte;
        end
        if(curr_state == WRITE_DC2 && should_write == 1'b1) begin
            dc2_reg[counter] <= o_RX_Byte;
        end
        if(curr_state == WRITE_DC3 && should_write == 1'b1) begin
            dc3_reg[counter] <= o_RX_Byte;
        end
        if(curr_state == WRITE_PRESCALE && should_write == 1'b1) begin
            prescale_reg[counter] <= o_RX_Byte;
        end
        if(curr_state == ENABLE_PWM) begin
            enable_pwm <= 1'b1;
        end
        else if (curr_state == DISABLE_PWM) begin
            enable_pwm <= 1'b0;
        end
    end
end

// sequential logic for state machine
always @(posedge i_Clk or negedge i_Rst_L) begin
    if(~i_Rst_L) begin
        counter <= 2'b00;
        curr_state <= IDLE;
    end
    else begin
        counter <= next_counter;
        curr_state <= next_state;
    end
end

// combinational logic
always @(*) begin
    case (curr_state)
        IDLE : begin        // when we are idling
            next_state = IDLE;
            next_counter = 2'b00;
            should_write = 1'b0;
            if(o_RX_DV) begin // and there is a valid byte to read
                case (o_RX_Byte)    // we go to the state determined by value of read byte
                    8'd1: next_state = WRITE_CV;
                    8'd2: next_state = WRITE_PRESCALE;
                    8'd3: next_state = WRITE_DC1;
                    8'd4: next_state = WRITE_DC2;
                    8'd5: next_state = WRITE_DC3;
                    8'd6: next_state = DISABLE_PWM;
                    8'd7: next_state = ENABLE_PWM;
                    default: next_state = IDLE;
                endcase
            end
        end
        WRITE_CV : begin // we are writing the keys
            next_state = WRITE_CV;
            next_counter = counter;
            should_write = 1'b0;
            if(o_RX_DV) begin // there is a valid byte to read
                should_write = 1'b1;
                if(counter == 2'd3) begin // check counter value
                    next_counter = 2'd0; // zero counter if end of array
                    next_state = IDLE; // and go to idle
                end
                else begin
                    // we increment the counter otherwise
                    next_counter = counter + 2'd1;
                end
            end
        end
        WRITE_PRESCALE : begin
            next_state = WRITE_PRESCALE;
            next_counter = counter;
            should_write = 1'b0;
            if(o_RX_DV) begin // there is a valid byte to read
                should_write = 1'b1;
                if(counter == 2'd3) begin // check counter value
                    next_counter = 2'd0; // zero counter if end of array
                    next_state = IDLE; // and go to idle
                end
                else begin
                    // we increment the counter otherwise
                    next_counter = counter + 2'd1;
                end
            end
        end
        WRITE_DC1 : begin
            next_state = WRITE_DC1;
            next_counter = counter;
            should_write = 1'b0;
            if(o_RX_DV) begin // there is a valid byte to read
                should_write = 1'b1;
                if(counter == 2'd3) begin // check counter value
                    next_counter = 2'd0; // zero counter if end of array
                    next_state = IDLE; // and go to idle
                end
                else begin
                    // we increment the counter otherwise
                    next_counter = counter + 2'd1;
                end
            end
        end
        WRITE_DC2 : begin
            next_state = WRITE_DC2;
            next_counter = counter;
            should_write = 1'b0;
            if(o_RX_DV) begin // there is a valid byte to read
                should_write = 1'b1;
                if(counter == 2'd3) begin // check counter value
                    next_counter = 2'd0; // zero counter if end of array
                    next_state = IDLE; // and go to idle
                end
                else begin
                    // we increment the counter otherwise
                    next_counter = counter + 2'd1;
                end
            end
        end
        WRITE_DC3 : begin
            next_state = WRITE_DC3;
            next_counter = counter;
            should_write = 1'b0;
            if(o_RX_DV) begin // there is a valid byte to read
                should_write = 1'b1;
                if(counter == 2'd3) begin // check counter value
                    next_counter = 2'd0; // zero counter if end of array
                    next_state = IDLE; // and go to idle
                end
                else begin
                    // we increment the counter otherwise
                    next_counter = counter + 2'd1;
                end
            end
        end
        ENABLE_PWM : begin
            next_counter = 2'd0;
            should_write = 1'b0;
            next_state = IDLE;
        end
        DISABLE_PWM : begin
            next_counter = 2'd0;
            should_write = 1'b0;
            next_state = IDLE;
        end
    endcase
end

endmodule
