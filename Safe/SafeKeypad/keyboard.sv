module keyboard(input logic MAX10_CLK1_50,input logic [1:0] KEY,inout wire [15:0] ARDUINO_IO,
output logic [9:0] LEDR, output logic [7:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);

wire [3:0] row_wires, col_wires;
assign ARDUINO_IO[7:4]=row_wires;
assign col_wires=ARDUINO_IO[3:0];

logic clk,rst,key_validn,prev_valid,valid;
assign clk=MAX10_CLK1_50;
assign rst=~KEY[0];

logic [3:0] key_code,code;
logic [3:0] row_scan;
logic [3:0] row,col;
logic [7:0] hex_display;
logic debouncedOK;

typedef enum logic [1:0] {S_0,S_1,S_2,S_3} state_t;
state_t present_row,next_row;

assign ARDUINO_IO[11:8]=key_code;
assign ARDUINO_IO[12]=key_validn;

always_comb
begin
	hex_display=8'hFF;
	code=4'h0;
	case(key_code)
		8'b1110_1011: begin hex_display=8'hC0; code=4'h0; end
		
		8'b0111_0111: begin hex_display=8'hF9; code=4'h1; end
		
		8'b0111_1011: begin hex_display=8'hA4; code=4'h2; end
		
		8'b0111_1101: begin hex_display=8'hB0; code=4'h3; end
		
		8'b1011_0111: begin hex_display=8'h99; code=4'h4; end
		
		8'b1011_1011: begin hex_display=8'h92; code=4'h5; end
		
		8'b1011_1101: begin hex_display=8'h82; code=4'h6; end
		
		8'b1101_0111: begin hex_display=8'hF8; code=4'h7; end
		
		8'b1101_1011: begin hex_display=8'h80; code=4'h8; end
		
		8'b1101_1101: begin hex_display=8'h98; code=4'h9; end
		
		8'b0111_1110: begin hex_display=8'h88; code=4'hA; end
		
		8'b1011_1110: begin hex_display=8'h83; code=4'hB; end
		
		8'b1101_1110: begin hex_display=8'hA7; code=4'hC; end
		
		8'b1110_1110: begin hex_display=8'hA1; code=4'hD; end
		
		8'b1110_1101: begin hex_display=8'h86; code=4'hE; end
		
		8'b1110_0111: begin hex_display=8'h8E; code=4'hF; end
	endcase
end

always_comb
begin
next_row = present_row;
	if (~valid & scan_tick) begin
	case(present_row)
		S_0: next_row=S_1;
		S_1: next_row=S_2;
		S_2: next_row=S_3;
		S_3: next_row=S_0;
	endcase
end
end

always_comb begin
LEDR[9] = ~valid;
LEDR[8] = debouncedOK;
LEDR[7:4] = ~row;
LEDR[3:0] = ~col;

case(present_row) 
S_0: row_scan = 4'b1110;
S_1: row_scan = 4'b1101;
S_2: row_scan = 4'b1011;
S_3: row_scan = 4'b0111;
endcase
end



logic [18:0] scan_counter;
logic scan_tick;

always_ff @(posedge clk) begin
	if(rst) begin
		scan_counter <= 0;
		scan_tick <= 0;
	end else begin
		if(scan_counter == 19'd500000) begin
			scan_counter <= 0;
			scan_tick <= 1;
		end else begin
			scan_counter <= scan_counter + 1;
			scan_tick <= 0;
		end
	end
end

logic initialized = 1'b0;

always_ff @(posedge clk)
begin
	if(rst)
	begin
		initialized<=1'b1;
		key_validn<=1'b1;
		prev_valid<=1'b0;
		key_code<=4'h0;
		present_row <= S_0;
		
		{HEX5,HEX4,HEX3,HEX2,HEX1,HEX0}<=48'hFFFFFFFFFFFF;
	end
	else
	begin
		if(~initialized) begin {HEX5,HEX4,HEX3,HEX2,HEX1,HEX0}<=48'hFFFFFFFFFFFF; initialized<=1'b1; end
		prev_valid<=valid;
		if(key_validn&~prev_valid&hex_display!=8'hFF) begin
		key_code <= code;
		key_validn <= 1'b0;
			{HEX5,HEX4,HEX3,HEX2,HEX1,HEX0}<={HEX4,HEX3,HEX2,HEX1,HEX0,hex_display};
			end
	else if (valid) key_validn <= 1'b0;
	else begin
		key_validn <= 1;
	end

end
end

kb_db (clk,rst,row_wires,col_wires,row_scan,row,col,valid,debouncedOK);

endmodule
