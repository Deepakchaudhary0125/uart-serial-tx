module uart (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire tx_start,
    output reg tx,
    output reg tx_done
);
    parameter clk_per_bit = 87;  // Clock cycles per bit (adjust for baud rate)

    reg [3:0] bit_index = 0;
    reg [15:0] clk_count = 0;
    reg [9:0] frame = 10'b1111111111;
    reg busy = 0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            busy <= 0;
            tx_done <= 0;
            tx <= 1'b1;  // Idle line is high
            clk_count <= 0;
            bit_index <= 0;
        end else begin
            if (tx_start && !busy) begin
                busy <= 1;
                clk_count <= 0;
                bit_index <= 0;
                tx_done <= 0;

                // Construct 10-bit UART frame: {stop, data[7:0], start}
                frame <= {1'b1, data_in, 1'b0};
                tx <= 1'b0;  // Start bit
            end else if (busy) begin
                if (clk_count < clk_per_bit - 1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    bit_index <= bit_index + 1;

                    if (bit_index < 9) begin
                        tx <= frame[bit_index + 1];
                    end else begin
                        tx <= 1'b1;  // Return to idle
                        busy <= 0;
                        tx_done <= 1;
                    end
                end
            end else begin
                tx_done <= 0;
            end
        end
    end

endmodule


//Testbench

`timescale 1ps/1ps;

module uart_tb;
    reg clk;
    reg reset;
    reg [7:0] data_in;
    reg tx_start;
    wire tx;
    wire tx_done;

    uart uut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .tx_start(tx_start),
        .tx(tx),
        .tx_done(tx_done)
    );

    always begin
        #5 clk = ~clk;  // 100 MHz clock (10 ns period)
    end

    initial begin
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, uart_tb);
    end

    initial begin
        clk = 0;
        reset = 1;
        tx_start = 0;
        data_in = 8'b0;

        #20 reset = 0;
        #10 data_in = 8'b10101011;
            tx_start = 1;

        #10 tx_start = 0;

        wait(tx_done);
        #50 $finish;
    end

endmodule


   
