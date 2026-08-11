#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vrouter_top.h"
#include <iostream>

vluint64_t main_time = 0;

double sc_time_stamp() {
    return (double)main_time;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vrouter_top* top = new Vrouter_top;

    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("router_top.vcd");

    top->clk = 0;
    top->rst_n = 0;
    for (int i = 0; i < 5; i++) {
        top->s_axis_tdata[i] = 0;
        top->s_axis_tvalid[i] = 0;
        top->m_axis_tready[i] = 1;
    }

    std::cout << "Starting collision test..." << std::endl;

    while (main_time < 300) {
        // toggle clock
        if ((main_time % 2) == 0) top->clk = !top->clk;

        if (main_time < 10) {
            top->rst_n = 0;
        } else {
            top->rst_n = 1;

            // simultaneous injection at time 20
            if (main_time == 20) {
                top->s_axis_tdata[0] = 0x01000000;
                top->s_axis_tvalid[0] = 1;
                top->s_axis_tdata[1] = 0x01000000;
                top->s_axis_tvalid[1] = 1;
                std::cout << "[Time " << main_time << "] Injecting packets on Port 0 and 1" << std::endl;
            }

            // only evaluate handshake on rising edge (clk == 1) --
            // avoids zero-time simulation artifacts
            if (top->clk == 1) {
                for (int i = 0; i < 2; i++) {
                    if (top->s_axis_tvalid[i] && top->s_axis_tready[i]) {
                        std::cout << "[Time " << main_time << "] Port " << i << " transaction accepted." << std::endl;
                        top->s_axis_tvalid[i] = 0;
                    }
                }
            }
        }

        top->eval();
        tfp->dump(main_time);
        main_time++;
    }

    std::cout << "Collision test finished." << std::endl;
    tfp->close();
    top->final();
    delete top;
    return 0;
}
