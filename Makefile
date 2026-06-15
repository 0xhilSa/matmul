# Makefile for Systolic Array Simulation

# verilog files
SOURCES = ./src/processing_elem.v ./src/systolic_array.v
TB_FUNC = ./tb/systolic_array_tb.v
TB_PERF = ./tb/systolic_array_perf_tb.v

# simulation executables
SIM_FUNC = systolic_array_sim
SIM_PERF = systolic_perf_sim

# VCD waveform file
VCD = systolic_array.vcd

# default target
all: run

# compile functional testbench with Icarus Verilog
compile:
	@echo "Compiling Verilog files (functional test)..."
	iverilog -o $(SIM_FUNC) $(SOURCES) $(TB_FUNC)
	@echo "Compilation complete!"

# compile performance testbench
compile-perf:
	@echo "Compiling Verilog files (performance test)..."
	iverilog -o $(SIM_PERF) $(SOURCES) $(TB_PERF)
	@echo "Compilation complete!"

# run functional simulation
run: compile
	@echo "Running functional simulation..."
	vvp $(SIM_FUNC)

# run performance benchmark
perf: compile-perf
	@echo "Running performance benchmark..."
	vvp $(SIM_PERF)

# run both tests
test: run perf

# View waveforms with GTKWave
wave: run
	@echo "Opening waveform viewer..."
	gtkwave $(VCD) &

# clean generated files
clean:
	@echo "Cleaning up..."
	rm -f $(SIM_FUNC) $(SIM_PERF) $(VCD)
	@echo "Clean complete!"

# help
help:
	@echo "Systolic Array Makefile"
	@echo "======================="
	@echo "Available targets:"
	@echo "  make compile      - Compile functional test"
	@echo "  make compile-perf - Compile performance test"
	@echo "  make run          - Compile and run functional simulation"
	@echo "  make perf         - Compile and run performance benchmark"
	@echo "  make test         - Run both functional and performance tests"
	@echo "  make wave         - Run simulation and view waveforms"
	@echo "  make clean        - Remove generated files"
	@echo "  make help         - Show this help message"

.PHONY: all compile compile-perf run perf test wave clean help
