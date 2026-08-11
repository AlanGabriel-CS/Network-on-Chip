#include "Vfifo_async.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vfifo_async* top = new Vfifo_async;

    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("fifo_async.vcd");

    // initialize signals
    top->wr_clk = 0;
    top->rd_clk = 0;
    top->wr_rst_n = 0;
    top->rd_rst_n = 0;

    int time = 0;

    // reset sequence: toggle clocks and increment time linearly
    for (int i = 0; i < 10; i++) {
        top->wr_clk = !top->wr_clk;
        top->rd_clk = !top->rd_clk;
        top->eval();
        tfp->dump(time++);
    }
    top->wr_rst_n = 1;
    top->rd_rst_n = 1;

    // main simulation loop
    for (int i = 0; i < 100; i++) {
        // 1. toggle clocks independently based on iteration count
        if (i % 2 == 0) top->wr_clk = !top->wr_clk;
        if (i % 3 == 0) top->rd_clk = !top->rd_clk;

        // 2. apply stimulus
        top->wr_en = (i > 10 && i < 40) ? 1 : 0;
        top->wr_data = 0xA0 + (i % 16);
        top->rd_en = (i > 50) ? 1 : 0;

        // 3. evaluate and dump exactly once per time unit
        top->eval();
        tfp->dump(time++);
    }

    tfp->close();
    top->final();
    delete top;
    delete tfp;
    return 0;
}
