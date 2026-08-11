# uvm-src is vendored, not committed. Fetch it before building:
#   git clone --branch uvm-2017-1.0-vlt --depth 1 \
#     https://github.com/chipsalliance/uvm-verilator.git uvm-src
VERILATOR = verilator
UVM_HOME = uvm-src/src

VERILATOR_FLAGS = -Wall \
                  -Wno-fatal \
                  -Wno-VARHIDDEN \
                  -Wno-UNUSEDSIGNAL \
                  -Wno-UNSIGNED \
                  -Wno-EOFNEWLINE \
                  --timing \
                  --vpi \
                  +incdir+$(UVM_HOME) \
                  +incdir+dv \
                  -CFLAGS "-I$(UVM_HOME)/dpi" \
                  --cc --exe -j 0 --trace --build

RTL_FILES = rtl/axi_stream_fifo_wrapper.sv \
            rtl/fifo_async.sv \
            rtl/input_port.sv \
            rtl/arbiter.sv \
            rtl/crossbar.sv \
            rtl/router_top.sv \
            dv/noc_if.sv \
            $(UVM_HOME)/uvm_pkg.sv \
            dv/noc_pkg.sv \
            dv/tb_top.sv

# uvm_dpi.cc backs the $uvm_re_match / $uvm_hdl_* DPI imports uvm_pkg.sv
# declares - without it the link fails. it already #includes
# uvm_svcmd_dpi.c itself, don't compile that one separately too
TB_FILE = dv/tb_main.cpp \
          $(UVM_HOME)/dpi/uvm_dpi.cc
TOP = tb_top

compile:
	$(VERILATOR) $(VERILATOR_FLAGS) $(RTL_FILES) $(TB_FILE) --top-module $(TOP) --Mdir obj_dir
	@echo "Build complete for $(TOP)"

run:
	./obj_dir/V$(TOP)

clean:
	rm -rf obj_dir *.vcd