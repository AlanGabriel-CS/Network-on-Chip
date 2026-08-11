module router_top #(
    parameter DATA_WIDTH   = 32,
    parameter bit [7:0] ROUTER_X = 8'd0,   // this router's X coordinate in the mesh
    parameter bit [7:0] ROUTER_Y = 8'd0    // this router's Y coordinate in the mesh
)(
    input  logic              clk, rst_n,
    input  logic [DATA_WIDTH-1:0] s_axis_tdata  [5],
    input  logic                  s_axis_tvalid [5],
    output logic                  s_axis_tready [5],

    output logic [DATA_WIDTH-1:0] m_axis_tdata  [5],
    output logic                  m_axis_tvalid [5],
    input  logic                  m_axis_tready [5]
);

    logic [4:0] request_vec [5];
    logic [4:0] grant_vec;
    logic [4:0] grant_matrix [5];
    logic [4:0] eff_grant_matrix [5];
    logic [DATA_WIDTH-1:0] port_data_out [5];

    genvar i, j;
    generate
        for (i = 0; i < 5; i++) begin : gen_ports
            input_port #(.DATA_WIDTH(DATA_WIDTH), .LOC_X(ROUTER_X), .LOC_Y(ROUTER_Y), .PORT_ID(i)) port_inst (
                .clk(clk), .rst_n(rst_n),
                .s_axis_tdata(s_axis_tdata[i]),
                .s_axis_tvalid(s_axis_tvalid[i]),
                .s_axis_tready(s_axis_tready[i]),
                .m_axis_tdata(port_data_out[i]),
                .request(request_vec[i]),
                .grant_vec(grant_vec)
            );
        end
    endgenerate

    generate
        for (j = 0; j < 5; j++) begin : gen_arbiters
            arbiter arb_inst (
                .clk(clk), .rst_n(rst_n),
                .request({request_vec[4][j] & m_axis_tready[j],
                          request_vec[3][j] & m_axis_tready[j],
                          request_vec[2][j] & m_axis_tready[j],
                          request_vec[1][j] & m_axis_tready[j],
                          request_vec[0][j] & m_axis_tready[j]}),
                .grant(grant_matrix[j])
            );
        end
    endgenerate

    always_comb begin
        // grant_matrix is a cycle stale by the time it gets here. if the
        // winning input's fifo already moved on to a different packet
        // (e.g. it also won some other output this same cycle and popped),
        // the old grant would send the crossbar the wrong packet. so only
        // count a grant if the input still actually wants that output now
        for (int j = 0; j < 5; j++) begin
            for (int i = 0; i < 5; i++) begin
                eff_grant_matrix[j][i] = grant_matrix[j][i] && request_vec[i][j];
            end
        end

        grant_vec = '0;
        for (int i = 0; i < 5; i++) begin
            for (int j = 0; j < 5; j++) begin
                if (eff_grant_matrix[j][i]) begin
                    grant_vec[i] = 1'b1;
                end
            end
        end

        for (int i = 0; i < 5; i++) begin
            m_axis_tvalid[i] = |eff_grant_matrix[i];
        end
    end

    crossbar #(.DATA_WIDTH(DATA_WIDTH), .NUM_PORTS(5)) xbar_inst (
        .data_in(port_data_out),
        .grant_matrix(eff_grant_matrix),
        .data_out(m_axis_tdata)
    );

endmodule