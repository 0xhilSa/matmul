module processing_element #(
  parameter DATA_WIDTH = 8
)(
  input wire clk,
  input wire rst_n,
  input wire en,
  input wire signed [DATA_WIDTH-1:0] a_in,      // Input from left
  input wire signed [DATA_WIDTH-1:0] b_in,      // Input from top
  input wire signed [2*DATA_WIDTH-1:0] c_in,    // Partial sum from top
  output reg signed [DATA_WIDTH-1:0] a_out,     // Output to right
  output reg signed [DATA_WIDTH-1:0] b_out,     // Output to bottom
  output reg signed [2*DATA_WIDTH-1:0] c_out    // Partial sum to bottom
);
  reg signed [2*DATA_WIDTH-1:0] accumulator;
  wire signed [2*DATA_WIDTH-1:0] mult_result;
  assign mult_result = a_in * b_in;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      a_out <= 0;
      b_out <= 0;
      c_out <= 0;
      accumulator <= 0;
    end else if(en) begin
      a_out <= a_in;
      b_out <= b_in;
      accumulator <= c_in + mult_result;
      c_out <= accumulator;
    end
  end
endmodule
