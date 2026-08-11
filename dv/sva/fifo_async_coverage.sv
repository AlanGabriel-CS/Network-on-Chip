// fifo_async_coverage.sv
// bind-in functional coverage for fifo_async.sv. one bind covers every
// instance (5 fifos, one per port), verilator auto-scopes it and
// option.per_instance=1 keeps each one's coverage separate
//
// two covergroups, one per clock domain since full is on wr_clk and
// empty is on rd_clk - sampling both off one clock would misrepresent
// the other domain because of CDC skew. each crosses the signal against
// a registered "previous" copy of itself to get all four transitions
// (0->0, 0->1, 1->0, 1->1) without needing SV transition-bin syntax,
// which verilator's coverage support handles less reliably

module fifo_async_coverage (
    input logic wr_clk, wr_rst_n,
    input logic full,
    input logic rd_clk, rd_rst_n,
    input logic empty
);

    logic full_prev;
    logic empty_prev;

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) full_prev <= 1'b0;
        else           full_prev <= full;
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) empty_prev <= 1'b1;
        else           empty_prev <= empty;
    end

    covergroup cg_wr_state @(posedge wr_clk);
        option.per_instance = 1;
        cp_full:      coverpoint full      iff (wr_rst_n);
        cp_full_prev: coverpoint full_prev iff (wr_rst_n);
        cx_full_transition: cross cp_full, cp_full_prev;
    endgroup

    covergroup cg_rd_state @(posedge rd_clk);
        option.per_instance = 1;
        cp_empty:      coverpoint empty      iff (rd_rst_n);
        cp_empty_prev: coverpoint empty_prev iff (rd_rst_n);
        cx_empty_transition: cross cp_empty, cp_empty_prev;
    endgroup

    cg_wr_state u_cg_wr_state = new();
    cg_rd_state u_cg_rd_state = new();

endmodule

bind fifo_async fifo_async_coverage u_fifo_async_coverage (
    .wr_clk   (wr_clk),
    .wr_rst_n (wr_rst_n),
    .full     (full),
    .rd_clk   (rd_clk),
    .rd_rst_n (rd_rst_n),
    .empty    (empty)
);