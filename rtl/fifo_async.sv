module fifo_async #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 4 // Must be power of 2 for this logic
)(
    input  logic                  wr_clk, wr_rst_n,
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic                  full,

    input  logic                  rd_clk, rd_rst_n,
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  empty
);

    localparam ADDR_WIDTH = $clog2(DEPTH);
    logic [ADDR_WIDTH:0] wr_ptr, rd_ptr;
    logic [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;

    logic [ADDR_WIDTH:0] wr_ptr_gray_q1, wr_ptr_gray_q2;
    logic [ADDR_WIDTH:0] rd_ptr_gray_q1, rd_ptr_gray_q2;

    logic [DATA_WIDTH-1:0] mem [DEPTH];

    assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);
    assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) {wr_ptr_gray_q2, wr_ptr_gray_q1} <= '0;
        else {wr_ptr_gray_q2, wr_ptr_gray_q1} <= {wr_ptr_gray_q1, wr_ptr_gray};
    end

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) {rd_ptr_gray_q2, rd_ptr_gray_q1} <= '0;
        else {rd_ptr_gray_q2, rd_ptr_gray_q1} <= {rd_ptr_gray_q1, rd_ptr_gray};
    end

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) wr_ptr <= '0;
        else if (wr_en && !full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
            wr_ptr <= wr_ptr + 1;
        end
    end

    assign full = (wr_ptr_gray == {~rd_ptr_gray_q2[ADDR_WIDTH:ADDR_WIDTH-1], rd_ptr_gray_q2[ADDR_WIDTH-2:0]});

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) rd_ptr <= '0;
        else if (rd_en && !empty) rd_ptr <= rd_ptr + 1;
    end

    assign empty = (rd_ptr_gray == wr_ptr_gray_q2);
    assign rd_data = mem[rd_ptr[ADDR_WIDTH-1:0]];

endmodule
