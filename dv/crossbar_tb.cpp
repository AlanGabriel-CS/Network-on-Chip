#include "Vcrossbar.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vcrossbar* top = new Vcrossbar;

    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("crossbar.vcd");

    // unpacked SystemVerilog array ports index directly into these arrays
    top->data_in[0] = 0xAA;
    top->data_in[1] = 0xBB;
    top->data_in[2] = 0xCC;
    top->data_in[3] = 0xDD;

    top->grant_matrix[0] = 0b0001;
    top->grant_matrix[1] = 0b0010;
    top->grant_matrix[2] = 0b0100;
    top->grant_matrix[3] = 0b1000;

    top->eval();
    tfp->dump(1);

    tfp->close();
    top->final();
    delete top;
    delete tfp;
    return 0;
}
