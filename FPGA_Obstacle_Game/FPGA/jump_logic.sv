	// Top module for the jump logic of the player
	module jump_logic(input  logic clk, reset, en, fallingSq,
					  output logic [9:0] out);
		// Top module for the jump logic of the player
		logic stop;
		jumpDelay jD(clk, reset, enCount, fallingSq, out, stop);
		jumpFSM jFSM(clk, reset, en, stop, enCount);	
	endmodule

  // Logic for the player to jump then jump back down.	
  module jumpDelay(input  logic clk, reset, enCount, fallingSq,
				   output logic [9:0] out,
				   output logic stop);
	logic done;
	// Covers how far the player jumps up and brings the player down upon each button press.
	always_ff @ (posedge clk, posedge reset) begin
	    // Resets the player's jumping.
		if(reset) begin
			out <= 10'd0;
			stop <= 1'b0;
		end
		// Square will fall as a decoration for winning the game.
		else if(fallingSq) begin
			out <= out - 10'd20;
		end
		// Player jump up logic
		else if(enCount == 1 & ~reset) begin
			if(done == 0) begin
				out <= out + 10'd7;
				stop <= 1'b0;
				if(out == 10'd112) done = 1'b1;
				else done = 1'b0;
			end
			// Stops the square from jumping too high up upon each press.
			else if(done == 1'b1) begin
				out <= out - 10'd7;
				if(out == 10'd0) begin
					stop <= 1'b1;
					done <= 1'b0;
				end
				else begin
					stop <= 1'b0;
					done <= 1'b1;
				end
			end
		end
		else out <= 0;
    end
  endmodule
  
  // Logic for the user's jump
  module jumpFSM(input  logic clk, reset, en, stop,
				 output logic enCount);
	
    typedef enum logic {S0, S1} statetype; 
    statetype state, ns;
	 // nextstate logic for the user's jump	
    always_ff @ (posedge clk, posedge reset) begin
      if(reset) state <= S0;
	   else state <= ns;
    end
	 // FSM logic for jumping from the user	
    always_comb
      case(state)
	     S0: begin
		    if(en) ns = S1; // jump
		    else ns = S0; // not jumping
	     end
		  S1: begin
		    if(stop == 1) ns = S0;
		    else ns = S1;
		  end
		  default: ns = S0;
    endcase
		
    assign enCount = (state == S1);
  endmodule
