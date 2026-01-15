module startScreen_rom (
	input logic clock,
	input logic [14:0] address,
	output logic [3:0] q
);

logic [3:0] memory [0:19199] /* synthesis ram_init_file = "./startScreen/startScreen.COE" */;

always_ff @ (posedge clock) begin
	q <= memory[address];
end

endmodule
