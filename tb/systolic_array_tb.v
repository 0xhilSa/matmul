`timescale 1ns/1ps
module systolic_array_tb;
  parameter DATA_WIDTH = 8;
  parameter ARRAY_SIZE = 4;
  parameter CLK_PERIOD = 10;

  reg clk;
  reg rst_n;
  reg en;
  reg drain;
  reg [$clog2(32)-1:0] drain_cnt;

  reg signed [ARRAY_SIZE*DATA_WIDTH-1:0] a_in;
  reg signed [ARRAY_SIZE*DATA_WIDTH-1:0] b_in;
  wire signed [ARRAY_SIZE*2*DATA_WIDTH-1:0] c_out;

  // 2-D bookkeeping arrays
  reg signed [DATA_WIDTH-1:0] matrix_a [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
  reg signed [DATA_WIDTH-1:0] matrix_b [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
  reg signed [2*DATA_WIDTH-1:0] expected_c [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
  reg signed [2*DATA_WIDTH-1:0] result_c [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];

  // Helper 1-D views for driving/reading the DUT
  reg  signed [DATA_WIDTH-1:0] a_in_arr [0:ARRAY_SIZE-1];
  reg  signed [DATA_WIDTH-1:0] b_in_arr [0:ARRAY_SIZE-1];
  wire signed [2*DATA_WIDTH-1:0] c_out_arr [0:ARRAY_SIZE-1];

  integer i, j, k, cycle, row, errors;

  // Pack helper arrays -> flat bus (combinatorial)
  always @(*) begin
    for(i = 0; i < ARRAY_SIZE; i = i + 1) begin
      a_in[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH] = a_in_arr[i];
      b_in[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH] = b_in_arr[i];
    end
  end

  genvar g;
  generate
    for(g = 0; g < ARRAY_SIZE; g = g + 1) begin : unpack_outputs
      assign c_out_arr[g] = c_out[(g+1)*2*DATA_WIDTH-1 -: 2*DATA_WIDTH];
    end
  endgenerate

  // DUT
  systolic_array#(
    .DATA_WIDTH(DATA_WIDTH),
    .ARRAY_SIZE(ARRAY_SIZE)
  )dut(
    .clk(clk),
    .rst_n(rst_n),
    .en(en),
    .drain(drain),
    .drain_cnt(drain_cnt),
    .a_in(a_in),
    .b_in(b_in),
    .c_out(c_out)
  );

  initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  // Initialise matrices
  initial begin
    matrix_a[0][0]=1;  matrix_a[0][1]=2;  matrix_a[0][2]=3;  matrix_a[0][3]=4;
    matrix_a[1][0]=5;  matrix_a[1][1]=6;  matrix_a[1][2]=7;  matrix_a[1][3]=8;
    matrix_a[2][0]=9;  matrix_a[2][1]=10; matrix_a[2][2]=11; matrix_a[2][3]=12;
    matrix_a[3][0]=13; matrix_a[3][1]=14; matrix_a[3][2]=15; matrix_a[3][3]=16;

    matrix_b[0][0]=1; matrix_b[0][1]=0; matrix_b[0][2]=0; matrix_b[0][3]=0;
    matrix_b[1][0]=0; matrix_b[1][1]=1; matrix_b[1][2]=0; matrix_b[1][3]=0;
    matrix_b[2][0]=0; matrix_b[2][1]=0; matrix_b[2][2]=1; matrix_b[2][3]=0;
    matrix_b[3][0]=0; matrix_b[3][1]=0; matrix_b[3][2]=0; matrix_b[3][3]=1;

    for(i = 0; i < ARRAY_SIZE; i = i + 1)
      for(j = 0; j < ARRAY_SIZE; j = j + 1) begin
        expected_c[i][j] = 0;
        for(k = 0; k < ARRAY_SIZE; k = k + 1)
          expected_c[i][j] = expected_c[i][j] + matrix_a[i][k] * matrix_b[k][j];
      end
  end

  // Main test sequence
  initial begin
    $dumpfile("systolic_array.vcd");
    $dumpvars(0, systolic_array_tb);

    // Initialise control signals
    rst_n = 0;
    en = 0;
    drain = 0;
    drain_cnt = 0;
    for(i = 0; i < ARRAY_SIZE; i = i + 1) begin
      a_in_arr[i] = 0;
      b_in_arr[i] = 0;
    end

    // Reset
    repeat(2) @(posedge clk);
    rst_n = 1;
    @(posedge clk);
    en = 1;

    $display("\n=== Systolic Array Test ===");
    $display("Matrix A:");
    for(i = 0; i < ARRAY_SIZE; i = i + 1) begin
      $write("  [");
      for(j = 0; j < ARRAY_SIZE; j = j + 1) $write("%3d ", matrix_a[i][j]);
      $display("]");
    end
    $display("\nMatrix B:");
    for(i = 0; i < ARRAY_SIZE; i = i + 1) begin
      $write("  [");
      for(j = 0; j < ARRAY_SIZE; j = j + 1) $write("%3d ", matrix_b[i][j]);
      $display("]");
    end

    $display("\n--- Starting Computation ---");

    // ---------------------------------------------------------------
    // COMPUTE PHASE
    // Feed skewed data: row i of A starts at cycle i; col j of B starts at cycle j.
    // Total input cycles needed: (ARRAY_SIZE - 1) + ARRAY_SIZE = 2*ARRAY_SIZE - 1 = 7
    // We run the loop for ARRAY_SIZE*2 - 1 cycles to cover all skewed inputs.
    // ---------------------------------------------------------------
    for(cycle = 0; cycle < ARRAY_SIZE * 2 - 1; cycle = cycle + 1) begin
      for(i = 0; i < ARRAY_SIZE; i = i + 1) begin
        if(cycle >= i && cycle < ARRAY_SIZE + i)
          a_in_arr[i] = matrix_a[i][cycle - i];
        else
          a_in_arr[i] = 0;
      end
      for(j = 0; j < ARRAY_SIZE; j = j + 1) begin
        if(cycle >= j && cycle < ARRAY_SIZE + j)
          b_in_arr[j] = matrix_b[cycle - j][j];
        else
          b_in_arr[j] = 0;
      end
      @(posedge clk);
    end

    // Zero inputs after feeding
    for(i = 0; i < ARRAY_SIZE; i = i + 1) begin
      a_in_arr[i] = 0;
      b_in_arr[i] = 0;
    end

    // Pipeline flush: the last skewed input element (a[N-1][N-1] / b[N-1][N-1])
    // enters the edge of the array on the final feed edge and still needs N-1 hops
    // to reach PE[N-1][N-1], where the accumulation register captures it one cycle
    // later. Total flush needed = N cycles (not N-1).
    repeat(ARRAY_SIZE) @(posedge clk);

    // ---------------------------------------------------------------
    // DRAIN PHASE
    // For each row (0 = top, ARRAY_SIZE-1 = bottom):
    //   - Set drain=1, drain_cnt=row
    //   - Wait ARRAY_SIZE clock cycles for the result to propagate from row `row`
    //     to the bottom of the array
    //   - Latch c_out_arr (one result column per cycle)
    // ---------------------------------------------------------------
    drain = 1;
    for(row = 0; row < ARRAY_SIZE; row = row + 1) begin
      drain_cnt = row[$clog2(32)-1:0];
      // Wait ARRAY_SIZE-row cycles for result to reach the array bottom
      repeat(ARRAY_SIZE - row) @(posedge clk);
      // Latch the entire output row
      for(j = 0; j < ARRAY_SIZE; j = j + 1)
        result_c[row][j] = c_out_arr[j];
    end
    drain = 0;

    // ---------------------------------------------------------------
    // Display results
    // ---------------------------------------------------------------
    $display("\nExpected Result (C = A * B):");
    for(i = 0; i < ARRAY_SIZE; i = i + 1) begin
      $write("  [");
      for(j = 0; j < ARRAY_SIZE; j = j + 1) $write("%4d ", expected_c[i][j]);
      $display("]");
    end

    $display("\nActual Output:");
    errors = 0;
    for(i = 0; i < ARRAY_SIZE; i = i + 1) begin
      $write("  [");
      for(j = 0; j < ARRAY_SIZE; j = j + 1) begin
        $write("%4d ", result_c[i][j]);
        if(result_c[i][j] !== expected_c[i][j]) errors = errors + 1;
      end
      $display("]");
    end

    if(errors == 0)
      $display("\n*** PASS: All %0d results correct ***", ARRAY_SIZE*ARRAY_SIZE);
    else
      $display("\n*** FAIL: %0d mismatches ***", errors);

    $display("\n=== Test Complete ===\n");
    repeat(5) @(posedge clk);
    $finish;
  end

  initial begin
    #50000;
    $display("ERROR: Test timeout!");
    $finish;
  end
endmodule
