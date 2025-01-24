module async_fifo #(
    parameter DATA_WIDTH = 8,   
    parameter FIFO_DEPTH = 16  
)(
    input wr_clk,                
    input rd_clk,                
    input rst,                   
    input wr_en,                 
    input rd_en,                 
    input [DATA_WIDTH-1:0] write_data,  
    output reg [DATA_WIDTH-1:0] read_data, 
    output full,               
    output empty                 
);

    
    reg [DATA_WIDTH-1:0] mem [FIFO_DEPTH-1:0];
    reg [clog2(FIFO_DEPTH):0] wptr, rptr;
    wire [clog2(FIFO_DEPTH):0] wptr_gray, rptr_gray;

    // Synchronized pointers for cross-clock domain communication
    reg [clog2(FIFO_DEPTH):0] wptr_gray_sync_rd, rptr_gray_sync_wr;
    reg [clog2(FIFO_DEPTH):0] wptr_gray_ff1_rd, wptr_gray_ff2_rd;
    reg [clog2(FIFO_DEPTH):0] rptr_gray_ff1_wr, rptr_gray_ff2_wr;

    // Convert binary read and write pointers to Gray code
    assign wptr_gray = wptr ^ (wptr >> 1);
    assign rptr_gray = rptr ^ (rptr >> 1);

    // Full and empty conditions
    assign empty = (wptr_gray_sync_rd == rptr_gray);  // Empty when pointers match
    assign full = ((wptr_gray[clog2(FIFO_DEPTH)] != rptr_gray_sync_wr[clog2(FIFO_DEPTH)]) &&
                   (wptr_gray[clog2(FIFO_DEPTH)-1:0] == rptr_gray_sync_wr[clog2(FIFO_DEPTH)-1:0]));

    // Write operation on wr_clk domain
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            wptr <= 0;
        end else if (wr_en && !full) begin
            mem[wptr[clog2(FIFO_DEPTH)-1:0]] <= write_data;  // Write data to memory
            wptr <= wptr + 1;  // Increment write pointer
        end
    end

    // Read operation on rd_clk domain
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            rptr <= 0;
            read_data <= 0;
        end else if (rd_en && !empty) begin
            read_data <= mem[rptr[clog2(FIFO_DEPTH)-1:0]];  // Read data from memory
            rptr <= rptr + 1;  // Increment read pointer
        end
    end

    // Synchronize write pointer to rd_clk domain
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            {wptr_gray_ff2_rd, wptr_gray_ff1_rd, wptr_gray_sync_rd} <= 0;
        end else begin
            wptr_gray_ff1_rd <= wptr_gray;         // First stage of synchronization
            wptr_gray_ff2_rd <= wptr_gray_ff1_rd;  // Second stage of synchronization
            wptr_gray_sync_rd <= wptr_gray_ff2_rd; // Synchronized pointer in rd_clk domain
        end
    end

    // Synchronize read pointer to wr_clk domain
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            {rptr_gray_ff2_wr, rptr_gray_ff1_wr, rptr_gray_sync_wr} <= 0;
        end else begin
            rptr_gray_ff1_wr <= rptr_gray;         // First stage of synchronization
            rptr_gray_ff2_wr <= rptr_gray_ff1_wr;  // Second stage of synchronization
            rptr_gray_sync_wr <= rptr_gray_ff2_wr; // Synchronized pointer in wr_clk domain
        end
    end

    // Function to calculate log2 for pointer width
    function integer clog2(input integer depth);
        integer i;
        begin
            clog2 = 0;
            for (i = depth; i > 1; i = i >> 1) begin
                clog2 = clog2 + 1;
            end
        end
    endfunction

endmodule
