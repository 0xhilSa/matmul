# verilog files
SOURCES = ./src/processing_elem.v ./src/systolic_array.v ./tb/systolic_array_tb.v

# simulation executable
SIM = systolic_array_sim

# VCD waveform file
VCD = systolic_array.vcd

# Default target
all: compile run

# Compile with Icarus Verilog
compile:
	@echo "Compiling Verilog files..."
	iverilog -o $(SIM) $(SOURCES)
	@echo "Compilation complete!"

# Run simulation
run: compile
	@echo "Running simulation..."
	vvp $(SIM)

# View waveforms with GTKWave
wave: run
	@echo "Opening waveform viewer..."
	gtkwave $(VCD) &

# Clean generated files
clean:
	@echo "Cleaning up..."
	rm -f $(SIM) $(VCD)
	@echo "Clean complete!"

# Help
help:
	@echo "Systolic Array Makefile"
	@echo "======================="
	@echo "Available targets:"
	@echo "  make compile  - Compile Verilog files"
	@echo "  make run      - Compile and run simulation"
	@echo "  make wave     - Run simulation and view waveforms"
	@echo "  make clean    - Remove generated files"
	@echo "  make help     - Show this help message"

.PHONY: all compile run wave clean help
