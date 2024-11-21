`timescale 1ns/1ps

module tb_async_fifo;

    // Parameters
    parameter DATA_WIDTH = 8;
    parameter FIFO_DEPTH = 16;

    // Testbench signals
    reg tb_wr_clk;
    reg tb_rd_clk;
    reg tb_rst;
    reg tb_wr_en;
    reg tb_rd_en;
    reg [DATA_WIDTH-1:0] tb_write_data;

    wire [DATA_WIDTH-1:0] tb_read_data;
    wire tb_full;
    wire tb_empty;

    // Instantiate the Unit Under Test (UUT)
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) uut (
        .wr_clk(tb_wr_clk),
        .rd_clk(tb_rd_clk),
        .rst(tb_rst),
        .wr_en(tb_wr_en),
        .rd_en(tb_rd_en),
        .write_data(tb_write_data),
        .read_data(tb_read_data),
        .full(tb_full),
        .empty(tb_empty)
    );

    // Clock generation for tb_wr_clk (50 MHz) and tb_rd_clk (25 MHz)
    initial begin
        tb_wr_clk = 0;
        forever #10 tb_wr_clk = ~tb_wr_clk; // Write clock period = 20 ns
    end

    initial begin
        tb_rd_clk = 0;
        forever #20 tb_rd_clk = ~tb_rd_clk; // Read clock period = 40 ns
    end

    // Stimulus generation
    initial begin
        $monitor("Time: %0t | wr_en: %b | rd_en: %b | write_data: %h | read_data: %h | empty: %b | full: %b",
                 $time, tb_wr_en, tb_rd_en, tb_write_data, tb_read_data, tb_empty, tb_full);

        // Reset the system
        tb_rst = 1; 
        tb_wr_en = 0;
        tb_rd_en = 0;
        tb_write_data = 0;
        #50; // Reset duration
        tb_rst = 0;

        // Write to FIFO
        tb_wr_en = 1;
        repeat(8) begin
            @(posedge tb_wr_clk);
            tb_write_data = $random;
        end
        tb_wr_en = 0;

        // Wait and then read from FIFO
        #100;
        tb_rd_en = 1;
        repeat(8) @(posedge tb_rd_clk);
        tb_rd_en = 0;

        // End simulation
        #200;
        $finish;
    end

endmodule
