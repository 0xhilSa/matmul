`timescale 1ns/1ps

module systolic_array_tb;
    parameter DATA_WIDTH = 8;
    parameter ARRAY_SIZE = 4;
    parameter CLK_PERIOD = 10;

    reg clk;
    reg rst_n;
    reg en;
    reg signed [ARRAY_SIZE*DATA_WIDTH-1:0] a_in;
    reg signed [ARRAY_SIZE*DATA_WIDTH-1:0] b_in;
    wire signed [ARRAY_SIZE*2*DATA_WIDTH-1:0] c_out;

    reg signed [DATA_WIDTH-1:0] matrix_a [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    reg signed [DATA_WIDTH-1:0] matrix_b [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    reg signed [2*DATA_WIDTH-1:0] expected_c [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    reg signed [DATA_WIDTH-1:0] a_in_arr [0:ARRAY_SIZE-1];
    reg signed [DATA_WIDTH-1:0] b_in_arr [0:ARRAY_SIZE-1];
    wire signed [2*DATA_WIDTH-1:0] c_out_arr [0:ARRAY_SIZE-1];

    integer i, j, k, cycle;

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

    systolic_array#(
      .DATA_WIDTH(DATA_WIDTH),
      .ARRAY_SIZE(ARRAY_SIZE)
    )dut(
      .clk(clk),
      .rst_n(rst_n),
      .en(en),
      .a_in(a_in),
      .b_in(b_in),
      .c_out(c_out)
    );

    initial begin
      clk = 0;
      forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
      matrix_a[0][0] = 1; matrix_a[0][1] = 2; matrix_a[0][2] = 3; matrix_a[0][3] = 4;
      matrix_a[1][0] = 5; matrix_a[1][1] = 6; matrix_a[1][2] = 7; matrix_a[1][3] = 8;
      matrix_a[2][0] = 9; matrix_a[2][1] = 10; matrix_a[2][2] = 11; matrix_a[2][3] = 12;
      matrix_a[3][0] = 13; matrix_a[3][1] = 14; matrix_a[3][2] = 15; matrix_a[3][3] = 16;

      matrix_b[0][0] = 3; matrix_b[0][1] = 4; matrix_b[0][2] = 3; matrix_b[0][3] = 6;
      matrix_b[1][0] = 7; matrix_b[1][1] = 4; matrix_b[1][2] = 4; matrix_b[1][3] = 2;
      matrix_b[2][0] = 1; matrix_b[2][1] = 4; matrix_b[2][2] = 8; matrix_b[2][3] = 4;
      matrix_b[3][0] = 0; matrix_b[3][1] = 5; matrix_b[3][2] = 1; matrix_b[3][3] = 6;

      for(i = 0; i < ARRAY_SIZE; i = i + 1) begin
        for(j = 0; j < ARRAY_SIZE; j = j + 1) begin
          expected_c[i][j] = 0;
          for(k = 0; k < ARRAY_SIZE; k = k + 1) begin
            expected_c[i][j] = expected_c[i][j] + (matrix_a[i][k] * matrix_b[k][j]);
          end
        end
      end
    end

    // Test sequence
    initial begin
      $dumpfile("systolic_array.vcd");
      $dumpvars(0, systolic_array_tb);

      rst_n = 0;
      en = 0;
      for(i = 0; i < ARRAY_SIZE; i = i + 1) begin
        a_in_arr[i] = 0;
        b_in_arr[i] = 0;
      end

      repeat(2) @(posedge clk);
      rst_n = 1;
      @(posedge clk);
      en = 1;

      $display("\n=== Systolic Array Test ===");
      $display("Matrix A:");
      for(i = 0; i < ARRAY_SIZE; i = i + 1) begin
        $write("  [");
        for(j = 0; j < ARRAY_SIZE; j = j + 1) begin
          $write("%3d ", matrix_a[i][j]);
        end
        $display("]");
      end

      $display("\nMatrix B:");
      for(i = 0; i < ARRAY_SIZE; i = i + 1) begin
        $write("  [");
        for(j = 0; j < ARRAY_SIZE; j = j + 1) begin
          $write("%3d ", matrix_b[i][j]);
        end
        $display("]");
      end

      for(cycle = 0; cycle < ARRAY_SIZE * 3; cycle = cycle + 1) begin
        // Feed A matrix horizontally with skewing
        for(i = 0; i < ARRAY_SIZE; i = i + 1) begin
          if(cycle >= i && cycle < ARRAY_SIZE + i) begin
            a_in_arr[i] = matrix_a[i][cycle - i];
          end else begin
            a_in_arr[i] = 0;
          end
        end

        // Feed B matrix vertically with skewing
        for(j = 0; j < ARRAY_SIZE; j = j + 1) begin
          if(cycle >= j && cycle < ARRAY_SIZE + j) begin
            b_in_arr[j] = matrix_b[cycle - j][j];
          end else begin
            b_in_arr[j] = 0;
          end
        end

        @(posedge clk);
      end

      repeat(ARRAY_SIZE * 2) @(posedge clk);

      $display("\nExpected Result (C = A * B):");
      for(i = 0; i < ARRAY_SIZE; i = i + 1) begin
        $write("  [");
        for(j = 0; j < ARRAY_SIZE; j = j + 1) begin
          $write("%4d ", expected_c[i][j]);
        end
        $display("]");
      end

      $display("\nActual Output:");
      $write("  [");
      for(j = 0; j < ARRAY_SIZE; j = j + 1) begin
        $write("%4d ", c_out_arr[j]);
      end
      $display("]");
      $display("\n=== Test Complete ===\n");
      repeat(10) @(posedge clk);
      $finish;
    end

    initial begin
      #10000;
      $display("ERROR: Test timeout!");
      $finish;
    end
endmodule
