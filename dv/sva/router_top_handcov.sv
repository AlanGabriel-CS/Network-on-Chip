module router_top_handcov #(
    parameter DATA_WIDTH = 32
)(
    input logic       clk,
    input logic       rst_n,
    input logic [4:0] request_vec       [5],
    input logic [4:0] eff_grant_matrix  [5],
    input logic [DATA_WIDTH-1:0] port_data_out [5]
);

    localparam int MESH_SIZE = 4;   // adjust if your mesh isn't 4x4

    // --- dest X/Y coverage: per source port, per (x,y) pair ---
    int unsigned dest_xy_hits [5][MESH_SIZE][MESH_SIZE];

    // --- source x dest-output cross-coverage ---
    int unsigned src_dest_hits [5][5];

    // --- arbitration contention-level coverage, per output port ---
    // bins: 0,1,2,3,4,5 simultaneous requesters
    int unsigned contention_hits [5][6];

    logic [7:0] dest_x [5];
    logic [7:0] dest_y [5];
    logic       req_valid [5];
    int unsigned contention [5];

    always_comb begin
        for (int i = 0; i < 5; i++) begin
            req_valid[i] = (request_vec[i] != 5'b0);
            dest_x[i]    = port_data_out[i][31:24];
            dest_y[i]    = port_data_out[i][23:16];
        end
        for (int j = 0; j < 5; j++) begin
            contention[j] = 0;
            for (int i = 0; i < 5; i++)
                if (request_vec[i][j]) contention[j]++;
        end
    end

    always_ff @(posedge clk) begin
        if (rst_n) begin
            for (int i = 0; i < 5; i++) begin
                if (req_valid[i]) begin
                    // clamp to MESH_SIZE-1 so out-of-mesh traffic (if it
                    // ever happens) doesn't index out of bounds - counts
                    // in the top bin instead
                    automatic int xb = (dest_x[i] < MESH_SIZE) ? int'(dest_x[i]) : MESH_SIZE-1;
                    automatic int yb = (dest_y[i] < MESH_SIZE) ? int'(dest_y[i]) : MESH_SIZE-1;
                    dest_xy_hits[i][xb][yb]++;

                    // source x dest-output cross: which output(s) this
                    // source's current request targets
                    for (int j = 0; j < 5; j++)
                        if (request_vec[i][j]) src_dest_hits[i][j]++;
                end
            end
            for (int j = 0; j < 5; j++)
                contention_hits[j][contention[j]]++;
        end
    end

    final begin
        int unsigned miss_count;
        miss_count = 0;

        $display("HANDCOV ==== router_top functional coverage summary ====");

        $display("HANDCOV -- dest X/Y coverage per source port --");
        for (int i = 0; i < 5; i++) begin
            for (int x = 0; x < MESH_SIZE; x++) begin
                for (int y = 0; y < MESH_SIZE; y++) begin
                    if (dest_xy_hits[i][x][y] == 0) begin
                        $display("HANDCOV src=%0d dest_x=%0d dest_y=%0d hits=0 MISS", i, x, y);
                        miss_count++;
                    end else begin
                        $display("HANDCOV src=%0d dest_x=%0d dest_y=%0d hits=%0d", i, x, y, dest_xy_hits[i][x][y]);
                    end
                end
            end
        end

        $display("HANDCOV -- source x dest-output cross-coverage --");
        for (int i = 0; i < 5; i++) begin
            for (int j = 0; j < 5; j++) begin
                if (src_dest_hits[i][j] == 0) begin
                    $display("HANDCOV src=%0d out=%0d hits=0 MISS", i, j);
                    miss_count++;
                end else begin
                    $display("HANDCOV src=%0d out=%0d hits=%0d", i, j, src_dest_hits[i][j]);
                end
            end
        end

        $display("HANDCOV -- arbitration contention-level coverage per output --");
        for (int j = 0; j < 5; j++) begin
            for (int lvl = 0; lvl < 6; lvl++) begin
                if (contention_hits[j][lvl] == 0) begin
                    $display("HANDCOV out=%0d contention=%0d hits=0 MISS", j, lvl);
                    miss_count++;
                end else begin
                    $display("HANDCOV out=%0d contention=%0d hits=%0d", j, lvl, contention_hits[j][lvl]);
                end
            end
        end

        $display("HANDCOV ==== total missed bins: %0d ====", miss_count);
    end

endmodule

bind router_top router_top_handcov #(.DATA_WIDTH(DATA_WIDTH)) u_router_top_handcov (
    .clk              (clk),
    .rst_n            (rst_n),
    .request_vec      (request_vec),
    .eff_grant_matrix (eff_grant_matrix),
    .port_data_out    (port_data_out)
);