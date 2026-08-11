`ifndef NOC_PKG_SV
`define NOC_PKG_SV

package noc_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // 1. Transaction item first
    `include "noc_packet.sv"

    `include "noc_seq.sv"

    // 2. Verification components
    `include "noc_driver.sv"
    `include "noc_monitor.sv"
    `include "noc_agent.sv"
    `include "noc_scoreboard.sv"
    `include "noc_env.sv"
    `include "noc_test.sv"

endpackage

`endif
