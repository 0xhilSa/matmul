<h1 align="center">Matmul Hardware Design</h1>

<p align="center">
  Matrix multiplication accelerator implemented using a 4×4 systolic array in Verilog.
</p>

<p align="center">
  Designed for FPGA/ASIC experimentation and learning hardware acceleration concepts.
</p>

<img src="./docs/layout.png" alt="Layout">

### Install
```bash
git clone https://github.com/0xhilSa/matmul.git
cd matmul
rm -rf .git .gitignore
make run
```

### Output
```bash
$ make run
Compiling Verilog files (functional test)...
iverilog -o systolic_array_sim ./src/processing_elem.v ./src/systolic_array.v ./tb/systolic_array_tb.v
Compilation complete!
Running functional simulation...
vvp systolic_array_sim
VCD info: dumpfile systolic_array.vcd opened for output.

=== Systolic Array Test ===
Matrix A:
  [  1   2   3   4 ]
  [  5   6   7   8 ]
  [  9  10  11  12 ]
  [ 13  14  15  16 ]

Matrix B:
  [  1   0   0   0 ]
  [  0   1   0   0 ]
  [  0   0   1   0 ]
  [  0   0   0   1 ]

--- Starting Computation ---

Expected Result (C = A * B):
  [   1    2    3    4 ]
  [   5    6    7    8 ]
  [   9   10   11   12 ]
  [  13   14   15   16 ]

Actual Output:
  [   1    2    3    4 ]
  [   5    6    7    8 ]
  [   9   10   11   12 ]
  [  13   14   15   16 ]

*** PASS: All 16 results correct ***

=== Test Complete ===
```
