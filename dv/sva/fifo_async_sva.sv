// fifo_async_sva.sv
// bind-in checker for fifo_async.sv
//   - wr_en never asserted while full, rd_en never asserted while empty
//     (protocol check on whatever's feeding/draining this fifo)
//   - wr_ptr_gray/rd_ptr_gray each move by exactly one bit per change -
//     that's the whole point of gray coding for the CDC synchronizer,
//     a multi-bit jump means the pointer logic or binary->gray
//     conversion is broken
//   - fifo can't come out of reset already full or already non-empty
//
// one bind covers both clock domains since the checks just live as
// separate concurrent assertions on different @(posedge ...) events
// inside the same module

module fifo_async_sva #(
    parameter ADDR_WIDTH = 2
)(
    input logic                  wr_clk, wr_rst_n,
    input logic                  wr_en,
    input logic                  full,
    input logic [ADDR_WIDTH:0]   wr_ptr_gray,

    input logic                  rd_clk, rd_rst_n,
    input logic                  rd_en,
    input logic                  empty,
    input logic [ADDR_WIDTH:0]   rd_ptr_gray
);

    // --- write-domain checks ---
    a_no_write_when_full: assert property (
        @(posedge wr_clk) disable iff (!wr_rst_n)
        wr_en |-> !full
    ) else $error("[FIFO_SVA] wr_en asserted while full");

    a_wr_gray_hamming1: assert property (
        @(posedge wr_clk) disable iff (!wr_rst_n)
        (wr_ptr_gray != $past(wr_ptr_gray)) |->
            ($countones(wr_ptr_gray ^ $past(wr_ptr_gray)) == 1)
    ) else $error("[FIFO_SVA] wr_ptr_gray moved by more than one bit: %b -> %b",
                   $past(wr_ptr_gray), wr_ptr_gray);

    a_not_born_full: assert property (
        @(posedge wr_clk) $rose(wr_rst_n) |-> !full
    ) else $error("[FIFO_SVA] fifo reports full immediately out of reset");

    // --- read-domain checks ---
    a_no_read_when_empty: assert property (
        @(posedge rd_clk) disable iff (!rd_rst_n)
        rd_en |-> !empty
    ) else $error("[FIFO_SVA] rd_en asserted while empty");

    a_rd_gray_hamming1: assert property (
        @(posedge rd_clk) disable iff (!rd_rst_n)
        (rd_ptr_gray != $past(rd_ptr_gray)) |->
            ($countones(rd_ptr_gray ^ $past(rd_ptr_gray)) == 1)
    ) else $error("[FIFO_SVA] rd_ptr_gray moved by more than one bit: %b -> %b",
                   $past(rd_ptr_gray), rd_ptr_gray);

    a_born_empty: assert property (
        @(posedge rd_clk) $rose(rd_rst_n) |-> empty
    ) else $error("[FIFO_SVA] fifo not empty immediately out of reset");

endmodule

bind fifo_async fifo_async_sva #(.ADDR_WIDTH(ADDR_WIDTH)) u_fifo_async_sva (
    .wr_clk      (wr_clk),
    .wr_rst_n    (wr_rst_n),
    .wr_en       (wr_en),
    .full        (full),
    .wr_ptr_gray (wr_ptr_gray),

    .rd_clk      (rd_clk),
    .rd_rst_n    (rd_rst_n),
    .rd_en       (rd_en),
    .empty       (empty),
    .rd_ptr_gray (rd_ptr_gray)
);
