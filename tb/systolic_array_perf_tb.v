`timescale 1ns/1ps

module systolic_array_perf_tb;
  parameter DATA_WIDTH = 8;
  parameter CLK_PERIOD = 10;  // 100 MHz

  // test different array sizes
  parameter NUM_TESTS = 4;
  integer test_sizes [0:NUM_TESTS-1];

  integer test_idx;
  integer ARRAY_SIZE;

  // timing variables
  integer start_time;
  integer end_time;
  integer total_time;
  real time_ns;
  real time_us;

  // performance metrics
  integer total_ops;
  integer input_cycles;
  integer compute_cycles;
  integer output_cycles;
  integer total_cycles;
  real ops_per_cycle;
  real throughput_gops;
  real cycles_per_element;

  initial begin
    // define test sizes
    test_sizes[0] = 2;
    test_sizes[1] = 4;
    test_sizes[2] = 8;
    test_sizes[3] = 16;

    $display("\n");
    $display("================================================================================");
    $display("           SYSTOLIC ARRAY PERFORMANCE BENCHMARK");
    $display("================================================================================");
    $display("Data Width:      %0d bits", DATA_WIDTH);
    $display("Clock Period:    %0d ns (%0d MHz)", CLK_PERIOD, 1000/CLK_PERIOD);
    $display("================================================================================\n");

    // header
    $display("%-10s | %-8s | %-12s | %-12s | %-12s | %-10s", "Size", "Cycles", "Time (ns)", "Time (us)", "Ops/Cycle", "GOPS");
    $display("-----------|----------|--------------|--------------|--------------|------------");

    // run tests for each size
    for(test_idx = 0; test_idx < NUM_TESTS; test_idx = test_idx + 1) begin
      ARRAY_SIZE = test_sizes[test_idx];

      // calculate timing
      input_cycles = ARRAY_SIZE - 1;      // skewing delay
      compute_cycles = ARRAY_SIZE;         // actual computation
      output_cycles = ARRAY_SIZE * 2;      // result propagation
      total_cycles = input_cycles + compute_cycles + output_cycles;

      time_ns = total_cycles * CLK_PERIOD;
      time_us = time_ns / 1000.0;

      // calculate performance
      total_ops = ARRAY_SIZE * ARRAY_SIZE * ARRAY_SIZE * 2;  // MACs
      ops_per_cycle = total_ops * 1.0 / total_cycles;
      throughput_gops = (total_ops / time_ns);  // GOPS
      cycles_per_element = total_cycles * 1.0 / (ARRAY_SIZE * ARRAY_SIZE);

      // display results
      $display("%-3dx%-3d    | %-8d | %-12.1f | %-12.3f | %-12.2f | %-10.3f",
        ARRAY_SIZE, ARRAY_SIZE,
        total_cycles,
        time_ns,
        time_us,
        ops_per_cycle,
        throughput_gops);
    end

    $display("================================================================================\n");

    // Additional analysis
    $display("COMPARISON WITH OTHER ARCHITECTURES:");
    $display("------------------------------------");
    ARRAY_SIZE = 8;
    total_cycles = (ARRAY_SIZE - 1) + ARRAY_SIZE + (ARRAY_SIZE * 2);
    total_ops = ARRAY_SIZE * ARRAY_SIZE * ARRAY_SIZE * 2;

    $display("For 8x8 matrix multiplication (%0d operations):", total_ops);
    $display("  • Systolic Array:     ~%-3d cycles (this design)", total_cycles);
    $display("  • Serial:             ~%-3d cycles (no parallelism)", total_ops);
    $display("  • Parallel (ideal):   ~%-3d cycles (perfect parallelism)", ARRAY_SIZE*ARRAY_SIZE);
    $display("  • Speedup vs Serial:  %.1fx", total_ops*1.0/total_cycles);
    $display("");

    $finish;
  end
endmodule
