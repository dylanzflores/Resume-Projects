  // Module that slows down the 50 MHz to the appropriate game clock of around 60 HZ of a VGA refresh rate matching
  // 60 fps on the VGA
  module slowClkHz(input logic clk, reset,
				   output logic clk24Hzout);
    logic [23:0] cnt; // figure out the width of the counter

	always_ff @ (posedge clk, posedge reset) begin
      if(reset) cnt <= 24'd0; // resets counter to 0 
      else cnt <= cnt + 24'd20; // 24'12 = 24 Hz, 24'20 = 60 Hz
	end
	
	  assign clk24Hzout = cnt[23]; // msb is the new game clock
  endmodule