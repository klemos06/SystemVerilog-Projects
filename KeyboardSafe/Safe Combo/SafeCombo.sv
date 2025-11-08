module combo (
    input  logic        MAX10_CLK1_50,
    input  logic  [1:0] KEY,             
	 inout  wire [12:8] ARDUINO_IO,
    output logic [6:0]  segments,        
    output logic [5:0]  dig,
	 output logic [7:0] HEX5,
    output logic [7:0] HEX4,
    output logic [7:0] HEX3,
    output logic [7:0] HEX2,
    output logic [7:0] HEX1,
    output logic [7:0] HEX0
);



logic reset;
assign reset = KEY[0];

logic  [3:0] key_code_from_kb; 
logic  key_validn_from_kb;

assign key_code_from_kb = ARDUINO_IO [11:8];
assign key_validn_from_kb = ARDUINO_IO [12];


logic [3:0] key_code_f1, key_code_f2;
logic       key_validn_f1, key_validn_f2;


always_ff @(posedge MAX10_CLK1_50) begin
    if (~reset) begin
        key_code_f1   <= 4'h0;
        key_code_f2   <= 4'h0;
        key_validn_f1 <= 1'b1;
        key_validn_f2 <= 1'b1;
    end else begin
        key_code_f1   <= key_code_from_kb;
        key_code_f2   <= key_code_f1;
        key_validn_f1 <= key_validn_from_kb;
        key_validn_f2 <= key_validn_f1;
    end
end






logic [1:0] low_count;
logic       sample_pulse;
logic [3:0] key_code_sampled;

always_ff @(posedge MAX10_CLK1_50) begin
    if (key_validn_f2) begin
        low_count      <= 2'd0;
        sample_pulse <= 1'b0;
    end else begin
        if (low_count != 2'd3)
            low_count <= low_count + 2'd1;

        sample_pulse <= (low_count == 2'd1); 
    end

    if (sample_pulse)
        key_code_sampled <= key_code_f2;
end






logic [3:0] pw_store [5:0];
logic [3:0] entry_buf [5:0];
logic [2:0] index;
logic       match;

always_comb begin
    match = 1'b1;
    for (int i=0; i<6; i++) begin
        if (pw_store[i] != entry_buf[i])
            match = 1'b0;
    end
end




localparam logic [2:0] open= 3'b000;
localparam logic [2:0] enter_pw= 3'b001;
localparam logic [2:0] save_pw= 3'b010;
localparam logic [2:0] locked= 3'b011;
localparam logic [2:0] enter_try= 3'b100;
localparam logic [2:0] check_pw= 3'b101;
logic [2:0] present,next;


always_ff @(posedge MAX10_CLK1_50) begin
    if (~reset)
        present <= open;
    else
        present <= next;
end


always_comb begin
next = present;
case (present)

open: if (sample_pulse && key_code_sampled != 4'hE && key_code_sampled != 4'hF) next = enter_pw;


enter_pw: begin
if (sample_pulse && key_code_sampled == 4'hF) next = open; 
else if (sample_pulse && key_code_sampled == 4'hE && index == 3'd6) next = save_pw; 
end

save_pw: next = locked;

locked: if (sample_pulse && key_code_sampled != 4'hE && key_code_sampled != 4'hF) next = enter_try;

enter_try: begin
if (sample_pulse && key_code_sampled == 4'hF) next = locked; 
else if (sample_pulse && key_code_sampled == 4'hE && index == 3'd6) next = check_pw;
end


check_pw: if (match) next = open;  
          else next = locked; 
			 
default: next= open;

endcase

end




always_ff @(posedge MAX10_CLK1_50) begin
    if (~reset) begin
        index <= 3'd0;
        for (int i=0; i<6; i++) begin
            pw_store[i]   <= 4'h0;
            entry_buf[i]  <= 4'h0;
        end
    end else if (sample_pulse) begin
        if (key_code_sampled == 4'hF) begin
            index <= 3'd0; 
        end else if (key_code_sampled == 4'hE) begin
            
        end else if (index < 6) begin
            entry_buf[index] <= key_code_sampled;
            index <= index + 3'd1;
        end

        if (present == save_pw) begin
            for (int i=0; i<6; i++)
                pw_store[i] <= entry_buf[i];
        end
    end
end





logic [47:0] OPEN_DISPLAY  = 48'hFC_C0_8C_86_AB_F7; 
logic [47:0] LOCKED_DISPLAY = 48'hC7_C0_C6_89_86_C0; 
logic [47:0] current_disp;
logic [6:0]  seven_seg_data [15:0];

assign seven_seg_data[0]  = 7'b1000000;
assign seven_seg_data[1]  = 7'b1111001;
assign seven_seg_data[2]  = 7'b0100100;
assign seven_seg_data[3]  = 7'b0110000;
assign seven_seg_data[4]  = 7'b0011001;
assign seven_seg_data[5]  = 7'b0010010;
assign seven_seg_data[6]  = 7'b0000010;
assign seven_seg_data[7]  = 7'b1111000;
assign seven_seg_data[8]  = 7'b0000000;
assign seven_seg_data[9]  = 7'b0010000;
assign seven_seg_data[10] = 7'b0001000; 
assign seven_seg_data[11] = 7'b0000011; 
assign seven_seg_data[12] = 7'b1000110; 
assign seven_seg_data[13] = 7'b0100001; 
assign seven_seg_data[14] = 7'b0000110; 
assign seven_seg_data[15] = 7'b0001110; 


 always_comb begin
        {HEX5,HEX4,HEX3,HEX2,HEX1,HEX0} = (locked ? LOCKED_DISPLAY : OPEN_DISPLAY);
    end



/*logic [19:0] refresh;
always_ff @(posedge MAX10_CLK1_50)
    refresh <= refresh + 1'b1;

always_comb begin
    if (present == open || present == locked)
        current_disp = (present == open) ? OPEN_DISPLAY : LOCKED_DISPLAY;
    else begin
        
        current_disp = 48'hFF_FF_FF_FF_FF_FF;
        for (int i = 0; i < 6; i++) begin
            current_disp[(8*i)+:8] = (i < index) ? {1'b0, seven_seg_data[entry_buf[i]]} : 8'hFF;
        end
    end
end


logic [2:0] sel;
assign sel = refresh[19:17];

always_comb begin
    dig = 6'b111111;
    dig[sel] = 1'b0;
    segments = current_disp[(sel*8)+:7];
end*/




endmodule 








 
 

 