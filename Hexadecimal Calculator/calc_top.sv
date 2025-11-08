module register_nums(
	input logic clk, 
	input logic reset, 
	input logic enable, 
	input logic [3:0] button_in, // input values
	output logic [3:0] reg_vals); // values in the ff
	
always_ff @(posedge clk) begin
        if (!reset)    			// reset normally 1 when not pressed --> when !reset (0 - pressed) --> reset ff to zeros     
            reg_vals <= 4'b0000;
        else if (en)         // if enable is set to 1 --> set the ff to whatever is in the 4 input buttons 
            reg_vals <= button_in;
    end
endmodule

module sevenseg_display (
	input logic [3:0] data,
	output logic [6:0] segments );

assign segments[0] = (~data[3] & ~data[2] & data[0] & ~data[1])|(data[2] & ~data[3] & ~data[0] & ~data[1])|(~data[2] & data[3] & data[0] & data[1])|(data[2] & data[3] & ~data[0] & ~data[1])|(data[2] & data[3] & data[0] & ~data[1]);
assign segments[1] = (~data[3] & data[2] & ~data[1] & data[0])|(~data[3] & data[2] & data[1] & ~data[0])|(data[3] & ~data[2] & data[1] & data[0])|(data[3] & data[2] & ~data[1] & ~data[0])| (data[3] & data[2] & data[1] & ~data[0])|(data[3] & data[2] & data[1] & data[0]);
assign segments[2] = (~data[3] & ~data[2] & data[1] & ~data[0])|(data[3] & data[2] & ~data[1] & ~data[0])|(data[3] & data[2] & data[1] & ~data[0])|(data[3] & data[2] & data[1] & data[0]);
assign segments[3] = (~data[3] & ~data[2] & ~data[1] & data[0])|(~data[3] & data[2] & ~data[1] & ~data[0])|(~data[3] & data[2] & data[1] & data[0])|(data[3] & ~data[2] & ~data[1] & data[0])|(data[3] & ~data[2] & data[1] & ~data[0])|(data[3] & data[2] & data[1] & data[0]);
assign segments[4] = (~data[3] & ~data[2] & ~data[1] & data[0])|(~data[3] & ~data[2] & data[1] & data[0])|(~data[3] & data[2] & ~data[1] & ~data[0])|(~data[3] & data[2] & ~data[1] & data[0])|(~data[3] & data[2] & data[1] & data[0])|(data[3] & ~data[2] & ~data[1] & data[0]);
assign segments[5] = (~data[3] & ~data[2] & ~data[1] & data[0])|(~data[3] & ~data[2] & data[1] & ~data[0])|(~data[3] & ~data[2] & data[1] & data[0])|(~data[3] & data[2] & data[1] & data[0])|(data[3] & data[2] & ~data[1] & ~data[0])|(data[3] & data[2] & ~data[1] & data[0]);
assign segments[6] = (~data[3] & ~data[2] & ~data[1] & ~data[0])|(~data[3] & ~data[2] & ~data[1] & data[0])|(~data[3] & data[2] & data[1] & data[0]);

endmodule 


module calc_top( input logic [9:0] SW,
input logic [1:0] KEY,
output logic [9:0] LEDR,
output logic [6:0] HEX5,
output logic [6:0] HEX4,
output logic [6:0] HEX3,
output logic [6:0] HEX2,
output logic [6:0] HEX1,
output logic [6:0] HEX0 );

logic [3:0] A; // register A --> output of the ffs in reg a --> can be used as input for other sector
logic [3:0] B; // register B --> output of the ffs in reg a --> can be used as input for other secto

register_nums A_register(.clk(KEY[1]),.reset(KEY[0]),.enable(SW[9]),.button_in(SW[3:0]),.reg_vals(A)); // create an instance for the register of A ffs
register_nums B_register(.clk(KEY[1]),.reset(KEY[0]),.enable(SW[8	]),.button_in(SW[3:0]),.reg_vals(B)); // create an instance for the register of B ffs 

assign LEDR = SW;
 
logic [4:0] sum; // 5 bits to accomodate carryout
logic [4:0] fifthbit_pluszeros; // carryout with zeros in front

assign sum = A + B; 

assign fifthbit_pluszeros = {3'b000, sum[4]};


sevenseg_display display_A(.data(A),.segments(HEX5)); // displays the values in register A
sevenseg_display display_B(.data(B),.segments(HEX3)); // displays the values in register B
sevenseg_display four_rightsum(.data(sum[3:0]),.segments(HEX0)); // displays four right bits of the sum 
sevenseg_display fifthbit_andzeros(.data(fifthbit_pluszeros),.segments(HEX1)); // displays the carryout and leading zeros

endmodule




