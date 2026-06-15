module processing_element#(
  parameter DATA_WIDTH = 8,
  parameter ROW_ID = 0      // which row this PE sits in (0 = top)
)(
  input wire clk,
  input wire rst_n,
  input wire en,
  input wire drain,                              // drain phase: serialise results downward
  input wire [$clog2(32)-1:0] drain_cnt,         // global drain counter (0,1,2,...)
  input wire signed [DATA_WIDTH-1:0] a_in,       // from left neighbour
  input wire signed [DATA_WIDTH-1:0] b_in,       // from top neighbour
  input wire signed [2*DATA_WIDTH-1:0] c_in,     // partial-sum chain from PE above
  output reg signed [DATA_WIDTH-1:0] a_out,      // to right neighbour
  output reg signed [DATA_WIDTH-1:0] b_out,      // to bottom neighbour
  output reg signed [2*DATA_WIDTH-1:0] c_out     // partial-sum chain to PE below
);

  reg signed [2*DATA_WIDTH-1:0] accumulator;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      a_out <= 0;
      b_out <= 0;
      c_out <= 0;
      accumulator <= 0;
    end else if(en) begin
      a_out <= a_in;
      b_out <= b_in;
      if(drain) begin
        if(drain_cnt == ROW_ID[$clog2(32)-1:0])
          c_out <= accumulator;
        else
          c_out <= c_in;
      end else begin
        accumulator <= accumulator + (a_in * b_in);
        c_out <= 0;
      end
    end
  end

endmodule
