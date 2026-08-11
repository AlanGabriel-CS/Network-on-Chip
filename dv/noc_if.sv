`ifndef NOC_IF_SV
`define NOC_IF_SV

// One noc_if instance = one router_top port.
// Ingress = testbench -> DUT (s_axis side), driven by noc_driver.
// Egress  = DUT -> testbench (m_axis side), observed by noc_monitor.
interface noc_if #(
    parameter DATA_WIDTH = 32
) (
    input logic clk,
    input logic rst_n
);

    // ---- Ingress (driver drives, DUT's s_axis_* for this port) ----
    logic [DATA_WIDTH-1:0] s_tdata;
    logic                  s_tvalid;
    logic                  s_tready;   // driven by DUT, sampled by driver

    // ---- Egress (DUT's m_axis_* for this port, monitor observes) ----
    logic [DATA_WIDTH-1:0] m_tdata;
    logic                  m_tvalid;
    logic                  m_tready;   // sink side, driven by tb_top (usually tied high)

    modport driver (
        input  clk, rst_n, s_tready,
        output s_tdata, s_tvalid
    );

    modport monitor (
        input  clk, rst_n,
        input  s_tdata, s_tvalid, s_tready,
        input  m_tdata, m_tvalid, m_tready
    );

endinterface

`endif
