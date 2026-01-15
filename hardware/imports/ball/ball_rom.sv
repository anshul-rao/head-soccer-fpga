module ball_rom (
	input logic clock,
	input logic [9:0] address,
	output logic [2:0] q
);

logic [2:0] memory [0:959] /* synthesis ram_init_file = "./ball/ball.COE" */;

always_ff @ (posedge clock) begin
	q <= memory[address];
end

endmodule
