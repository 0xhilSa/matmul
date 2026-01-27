module systolic_array#(
  parameter DATA_WIDTH = 8,
  parameter ARRAY_SIZE = 4
)(
  input wire clk,
  input wire rst_n,
  input wire en,
  input wire signed [ARRAY_SIZE*DATA_WIDTH-1:0] a_in,
  input wire signed [ARRAY_SIZE*DATA_WIDTH-1:0] b_in,
  output wire signed [ARRAY_SIZE*2*DATA_WIDTH-1:0] c_out
);
  wire signed [DATA_WIDTH-1:0] a_wire [0:ARRAY_SIZE*ARRAY_SIZE+ARRAY_SIZE-1];
  wire signed [DATA_WIDTH-1:0] b_wire [0:ARRAY_SIZE*ARRAY_SIZE+ARRAY_SIZE-1];
  wire signed [2*DATA_WIDTH-1:0] c_wire [0:ARRAY_SIZE*ARRAY_SIZE+ARRAY_SIZE-1];

  function integer idx_a;
    input integer row, col;
    begin
      idx_a = row * (ARRAY_SIZE + 1) + col;
    end
  endfunction

  function integer idx_b;
    input integer row, col;
    begin
      idx_b = row * ARRAY_SIZE + col;
    end
  endfunction

  function integer idx_c;
    input integer row, col;
    begin
      idx_c = row * ARRAY_SIZE + col;
    end
  endfunction

  // Connect inputs to first row/column
  genvar i, j;
  generate
    for (i = 0; i < ARRAY_SIZE; i = i + 1) begin : input_connections
      assign a_wire[idx_a(i, 0)] = a_in[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH];
      assign b_wire[idx_b(0, i)] = b_in[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH];
      assign c_wire[idx_c(0, i)] = 0;  // Initialize partial sums
    end
  endgenerate

  generate
    for(i = 0; i < ARRAY_SIZE; i = i + 1) begin : row_gen
      for(j = 0; j < ARRAY_SIZE; j = j + 1) begin : col_gen
        processing_element#(
          .DATA_WIDTH(DATA_WIDTH)
        )pe_inst(
          .clk(clk),
          .rst_n(rst_n),
          .en(en),
          .a_in(a_wire[idx_a(i, j)]),
          .b_in(b_wire[idx_b(i, j)]),
          .c_in(c_wire[idx_c(i, j)]),
          .a_out(a_wire[idx_a(i, j+1)]),
          .b_out(b_wire[idx_b(i+1, j)]),
          .c_out(c_wire[idx_c(i+1, j)])
        );
      end
    end
  endgenerate

  generate
    for(i = 0; i < ARRAY_SIZE; i = i + 1) begin : output_connections
      assign c_out[(i+1)*2*DATA_WIDTH-1 -: 2*DATA_WIDTH] = c_wire[idx_c(ARRAY_SIZE, i)];
    end
  endgenerate

endmodule
