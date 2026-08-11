module input_port #(
    parameter DATA_WIDTH        = 32,
    parameter bit [7:0] LOC_X   = 8'd0,
    parameter bit [7:0] LOC_Y   = 8'd0,
    parameter PORT_ID           = 0
) (
    input  logic                  clk, rst_n,
    input  logic [DATA_WIDTH-1:0] s_axis_tdata,
    input  logic                  s_axis_tvalid,
    output logic                  s_axis_tready,
    output logic [DATA_WIDTH-1:0] m_axis_tdata,
    output logic [4:0]            request,
    input  logic [4:0]            grant_vec
);

    logic [DATA_WIDTH-1:0] fifo_dout;
    logic                  fifo_valid;
    logic                  fifo_ready;
    logic                  my_grant;

    axi_stream_fifo_wrapper #(.DATA_WIDTH(DATA_WIDTH)) buffer_inst (
        .wr_clk(clk), .wr_rst_n(rst_n),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .rd_clk(clk), .rd_rst_n(rst_n),
        .m_axis_tdata(fifo_dout),
        .m_axis_tvalid(fifo_valid),
        .m_axis_tready(fifo_ready)
    );

    assign m_axis_tdata = fifo_dout;

    logic [4:0] dest_port;
    always_comb begin
        dest_port = 5'b00000;
        if      (fifo_dout[31:24] > LOC_X) dest_port = 5'b01000;
        // verilator coverage_off
        else if (fifo_dout[31:24] < LOC_X) dest_port = 5'b00100;
        // verilator coverage_on
        else if (fifo_dout[31:24] == LOC_X) begin
            if      (fifo_dout[23:16] > LOC_Y) dest_port = 5'b00010;
            else if (fifo_dout[23:16] < LOC_Y) dest_port = 5'b00001;
            else                               dest_port = 5'b10000;
        end
    end

    assign my_grant   = |(grant_vec & (5'b1 << PORT_ID));
    assign request    = fifo_valid ? dest_port : 5'b00000;
    assign fifo_ready = fifo_valid && my_grant;
endmodule
