// router_top_coverage.sv
// bind-in functional coverage for router_top.sv
//
// bound in instead of a covergroup in the uvm env because noc_if only
// exposes the axi-stream boundary per port - a monitor can see what was
// sent/received but not whether two ports actually contended for the
// same output in the same cycle. that only shows up on
// request_vec/grant_matrix inside router_top, so binding gets me those
// signals directly and reuses what's already proven out in
// router_top_sva.sv.
//
// cg_dest_coord  - dest x/y of whatever's at each port's fifo head
// cg_source_dest - which output each source is actually requesting
// cg_collision   - how many ports are contending for an output at once
//                  (bin 2 is the exact scenario that exposed the
//                  grant/request race bug)
//
// using plain value coverpoints instead of transition bins since
// verilator's support for those is inconsistent across versions

module router_top_coverage #(
    parameter DATA_WIDTH = 32
)(
    input logic       clk,
    input logic       rst_n,
    input logic [4:0] request_vec       [5],
    input logic [4:0] eff_grant_matrix  [5],
    input logic [DATA_WIDTH-1:0] port_data_out [5]
);

    // bump this if the mesh isn't 4x4 - anything beyond it falls into
    // an "other" bin instead of getting dropped
    localparam int MESH_SIZE = 4;

    // per-source-port "this cycle's request is valid" and decoded dest
    logic [7:0] dest_x [5];
    logic [7:0] dest_y [5];
    logic       req_valid [5];

    // per-output-port contention level this cycle (0..5)
    int unsigned contention [5];

    always_comb begin
        for (int i = 0; i < 5; i++) begin
            req_valid[i] = (request_vec[i] != 5'b0);
            dest_x[i]    = port_data_out[i][31:24];
            dest_y[i]    = port_data_out[i][23:16];
        end
        for (int j = 0; j < 5; j++) begin
            contention[j] = 0;
            for (int i = 0; i < 5; i++) begin
                if (request_vec[i][j]) contention[j]++;
            end
        end
    end

    genvar gi, gj;
    generate
        for (gi = 0; gi < 5; gi++) begin : gen_src_cov

            covergroup cg_dest_coord @(posedge clk);
                option.per_instance = 1;
                cp_dest_x: coverpoint dest_x[gi] iff (rst_n && req_valid[gi]) {
                    bins x[MESH_SIZE] = {[0:MESH_SIZE-1]};
                    bins x_other = default;
                }
                cp_dest_y: coverpoint dest_y[gi] iff (rst_n && req_valid[gi]) {
                    bins y[MESH_SIZE] = {[0:MESH_SIZE-1]};
                    bins y_other = default;
                }
                cx_dest_xy: cross cp_dest_x, cp_dest_y;
            endgroup

            cg_dest_coord u_cg_dest_coord = new();

            covergroup cg_source_dest @(posedge clk);
                option.per_instance = 1;
                cp_out_port: coverpoint request_vec[gi] iff (rst_n && req_valid[gi]) {
                    bins to_out0 = {5'b00001};
                    bins to_out1 = {5'b00010};
                    bins to_out2 = {5'b00100};
                    bins to_out3 = {5'b01000};
                    bins to_out4 = {5'b10000};
                }
            endgroup

            cg_source_dest u_cg_source_dest = new();

        end
    endgenerate

    generate
        for (gj = 0; gj < 5; gj++) begin : gen_out_cov

            covergroup cg_collision @(posedge clk);
                option.per_instance = 1;
                cp_contention: coverpoint contention[gj] iff (rst_n) {
                    bins none        = {0};
                    bins one_req     = {1};
                    bins two_way     = {2};
                    bins three_way   = {3};
                    bins four_way    = {4};
                    bins five_way    = {5};
                }
            endgroup

            cg_collision u_cg_collision = new();

        end
    endgenerate

endmodule

bind router_top router_top_coverage #(.DATA_WIDTH(DATA_WIDTH)) u_router_top_coverage (
    .clk              (clk),
    .rst_n            (rst_n),
    .request_vec      (request_vec),
    .eff_grant_matrix (eff_grant_matrix),
    .port_data_out    (port_data_out)
);