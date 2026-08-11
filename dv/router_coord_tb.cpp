#include "Vrouter_top.h"
#include "verilated.h"
#include <iostream>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vrouter_top* top = new Vrouter_top;

    top->clk = 0;
    top->rst_n = 0;
    for (int i = 0; i < 5; i++) {
        top->s_axis_tdata[i] = 0;
        top->s_axis_tvalid[i] = 0;
        top->m_axis_tready[i] = 1;
    }

    for (int i = 0; i < 6; i++) { top->clk = !top->clk; top->eval(); }
    top->rst_n = 1;

    // Packet destined for X=2, Y=1 (matches input_port's field layout:
    // [31:24]=X, [23:16]=Y, [15:0]=payload)
    uint32_t packet = (2u << 24) | (1u << 16) | 0xBEEF;
    top->s_axis_tdata[0] = packet;
    top->s_axis_tvalid[0] = 1;

    int fired_port = -1;
    for (int cyc = 0; cyc < 20 && fired_port == -1; cyc++) {
        top->clk = 1; top->eval();
        top->clk = 0; top->eval();
        for (int p = 0; p < 5; p++) {
            if (top->m_axis_tvalid[p]) { fired_port = p; break; }
        }
    }

    // Port index mapping from input_port.sv: [4]=Local [3]=East [2]=West [1]=North [0]=South
    const char* names[5] = {"South", "North", "West", "East", "Local"};
    if (fired_port == -1) {
        std::cout << "No egress observed within timeout.\n";
    } else {
        std::cout << "Packet destined for (X=2,Y=1) exited on port " << fired_port
                   << " (" << names[fired_port] << ")\n";
    }

    delete top;
    return 0;
}