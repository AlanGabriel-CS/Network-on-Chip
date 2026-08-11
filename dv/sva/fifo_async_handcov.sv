// fifo_async_handcov.sv
// hand-rolled functional coverage for fifo_async.sv - see
// router_top_handcov.sv for why. one bind covers every instance, each
// gets its own counters and its own final printout, told apart by %m
// (hierarchical instance path) in the $display output

module fifo_async_handcov (
    input logic wr_clk, wr_rst_n,
    input logic full,
    input logic rd_clk, rd_rst_n,
    input logic empty
);

    logic full_prev;
    logic empty_prev;

    // transition bins: [prev][curr] - covers 0->0, 0->1, 1->0, 1->1
    int unsigned full_transition_hits  [2][2];
    int unsigned empty_transition_hits [2][2];

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            full_prev <= 1'b0;
        end else begin
            full_transition_hits[full_prev][full]++;
            full_prev <= full;
        end
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            empty_prev <= 1'b1;
        end else begin
            empty_transition_hits[empty_prev][empty]++;
            empty_prev <= empty;
        end
    end

    final begin
        int unsigned miss_count;
        string inst_path;
        miss_count = 0;
        inst_path = $sformatf("%m");

        $display("HANDCOV ==== fifo_async functional coverage summary: %s ====", inst_path);

        for (int p = 0; p < 2; p++) begin
            for (int c = 0; c < 2; c++) begin
                if (full_transition_hits[p][c] == 0) begin
                    $display("HANDCOV %s full_transition %0d->%0d hits=0 MISS", inst_path, p, c);
                    miss_count++;
                end else begin
                    $display("HANDCOV %s full_transition %0d->%0d hits=%0d", inst_path, p, c, full_transition_hits[p][c]);
                end
            end
        end

        for (int p = 0; p < 2; p++) begin
            for (int c = 0; c < 2; c++) begin
                if (empty_transition_hits[p][c] == 0) begin
                    $display("HANDCOV %s empty_transition %0d->%0d hits=0 MISS", inst_path, p, c);
                    miss_count++;
                end else begin
                    $display("HANDCOV %s empty_transition %0d->%0d hits=%0d", inst_path, p, c, empty_transition_hits[p][c]);
                end
            end
        end

        $display("HANDCOV %s total missed bins: %0d", inst_path, miss_count);
    end

endmodule

bind fifo_async fifo_async_handcov u_fifo_async_handcov (
    .wr_clk   (wr_clk),
    .wr_rst_n (wr_rst_n),
    .full     (full),
    .rd_clk   (rd_clk),
    .rd_rst_n (rd_rst_n),
    .empty    (empty)
);