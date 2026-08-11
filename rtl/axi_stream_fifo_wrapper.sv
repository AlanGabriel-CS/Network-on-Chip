module axi_stream_fifo_wrapper #(
    parameter DATA_WIDTH = 32
)(
    input  logic                  wr_clk, wr_rst_n,
    input  logic [DATA_WIDTH-1:0] s_axis_tdata,
    input  logic                  s_axis_tvalid,
    output logic                  s_axis_tready,

    input  logic                  rd_clk, rd_rst_n,
    output logic [DATA_WIDTH-1:0] m_axis_tdata,
    output logic                  m_axis_tvalid,
    input  logic                  m_axis_tready
);

    logic full, empty;

    fifo_async #(
        .DATA_WIDTH(DATA_WIDTH)
    ) fifo_inst (
        .wr_clk(wr_clk), .wr_rst_n(wr_rst_n),
        .wr_en(s_axis_tvalid && s_axis_tready),
        .wr_data(s_axis_tdata),
        .full(full),

        .rd_clk(rd_clk), .rd_rst_n(rd_rst_n),
        .rd_en(m_axis_tvalid && m_axis_tready),
        .rd_data(m_axis_tdata),
        .empty(empty)
    );

    assign s_axis_tready = !full;
    assign m_axis_tvalid = !empty;

endmodule
