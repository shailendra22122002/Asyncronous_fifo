`timescale 1ns/1ps

module tb_async_fifo;

    // Parameters
    parameter DATA_WIDTH = 8;
    parameter FIFO_DEPTH = 16;

    // Inputs
    reg wr_clk;
    reg rd_clk;
    reg rst;
    reg wr_en;
    reg rd_en;
    reg [DATA_WIDTH-1:0] write_data;

    // Outputs
    wire [DATA_WIDTH-1:0] read_data;
    wire full;
    wire empty;

    // Instantiate the Unit Under Test (UUT)
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) uut (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .write_data(write_data),
        .read_data(read_data),
        .full(full),
        .empty(empty)
    );

    // Clock generation for wr_clk (50 MHz) and rd_clk (25 MHz)
    initial begin
        wr_clk = 0;
        forever #10 wr_clk = ~wr_clk; // Write clock period = 20 ns
    end

    initial begin
        rd_clk = 0;
        forever #20 rd_clk = ~rd_clk; // Read clock period = 40 ns
    end

    // Stimulus generation
    initial begin
        // Monitor output signals
        $monitor("Time: %0t | wr_en: %b | rd_en: %b | write_data: %h | read_data: %h | empty: %b | full: %b",
                 $time, wr_en, rd_en, write_data, read_data, empty, full);
        
        // Reset the system
        rst = 1; // Assert reset
        wr_en = 0;
        rd_en = 0;
        write_data = 0;
        #50; // Hold reset for a while
        rst = 0;  // Release reset
        #20; // Allow some time after reset for clocks to start toggling

        // Write data to the FIFO
        wr_en = 1; // Enable writing
        repeat(8) begin
            @(posedge wr_clk);
            write_data = $random;  // Write random data
            #1; // Small delay to allow monitoring of write_data
        end
        wr_en = 0;

        // Allow some time for writes to complete
        #100;

        // Simultaneous read/write
        rd_en = 1; // Enable reading
        repeat(4) begin
            @(posedge rd_clk);
            #1; // Small delay for read_data
        end
        rd_en = 0;

        // Check for full and empty conditions
        wr_en = 1; // Enable writing
        repeat(8) begin
            @(posedge wr_clk);
            write_data = $random;  // Write random data
            #1; // Small delay to allow monitoring
        end
        wr_en = 0;

        repeat(8) @(posedge rd_clk); // Read until FIFO is empty
        rd_en = 1;
        repeat(8) @(posedge rd_clk);
        rd_en = 0;

        // End simulation after some time
        #200;
        $finish;
    end

endmodule
