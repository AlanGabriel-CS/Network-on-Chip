`timescale 1ns/1ps

module tb_top;

    import uvm_pkg::*;
    import noc_pkg::*;
    `include "uvm_macros.svh"

    localparam int NUM_PORTS  = 5;
    localparam int DATA_WIDTH = 32;

    logic clk, rst_n;

    // clock gen
    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rst_n = 0;
        #23 rst_n = 1;   // release reset off the clock edge
    end

    // one interface per router port
    noc_if #(.DATA_WIDTH(DATA_WIDTH)) intf[NUM_PORTS] (clk, rst_n);

    // DUT-facing arrays
    logic [DATA_WIDTH-1:0] s_axis_tdata  [NUM_PORTS];
    logic                  s_axis_tvalid [NUM_PORTS];
    logic                  s_axis_tready [NUM_PORTS];
    logic [DATA_WIDTH-1:0] m_axis_tdata  [NUM_PORTS];
    logic                  m_axis_tvalid [NUM_PORTS];
    logic                  m_axis_tready [NUM_PORTS];

    // wire each interface instance to its slice of the DUT's port arrays
    genvar gi;
    generate
        for (gi = 0; gi < NUM_PORTS; gi++) begin : gen_port_bind
            // ingress: driver -> interface -> DUT
            assign s_axis_tdata[gi]   = intf[gi].s_tdata;
            assign s_axis_tvalid[gi]  = intf[gi].s_tvalid;
            assign intf[gi].s_tready  = s_axis_tready[gi];

            // egress: DUT -> interface -> monitor
            assign intf[gi].m_tdata   = m_axis_tdata[gi];
            assign intf[gi].m_tvalid  = m_axis_tvalid[gi];
            assign m_axis_tready[gi]  = 1'b1;              // sink always ready for now
            assign intf[gi].m_tready  = m_axis_tready[gi];
        end
    endgenerate

    // dut instantiate
    router_top #(.DATA_WIDTH(DATA_WIDTH)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .s_axis_tdata  (s_axis_tdata),
        .s_axis_tvalid (s_axis_tvalid),
        .s_axis_tready (s_axis_tready),
        .m_axis_tdata  (m_axis_tdata),
        .m_axis_tvalid (m_axis_tvalid),
        .m_axis_tready (m_axis_tready)
    );

    initial begin
        uvm_config_db#(virtual noc_if)::set(null, "uvm_test_top.env.agent_0.*", "vif", intf[0]);
        uvm_config_db#(virtual noc_if)::set(null, "uvm_test_top.env.agent_1.*", "vif", intf[1]);
        uvm_config_db#(virtual noc_if)::set(null, "uvm_test_top.env.agent_2.*", "vif", intf[2]);
        uvm_config_db#(virtual noc_if)::set(null, "uvm_test_top.env.agent_3.*", "vif", intf[3]);
        uvm_config_db#(virtual noc_if)::set(null, "uvm_test_top.env.agent_4.*", "vif", intf[4]);

        run_test("noc_test");
    end

    initial begin
        $dumpfile("router_top.vcd");
        $dumpvars(0, tb_top);
    end

endmodule
