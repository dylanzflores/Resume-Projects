  module counter_shapes(input logic clk, reset, menuScreen, playerWon, playerLost, reset_obj_count,
						output logic [9:0] obj_position_counter, 
						output logic [10:0] game_time); 
	// Counter sets the movement of the obstacles for the duration of the level 
	// Game time counter sets the counter for the entirety of the level.
    always_ff @ (posedge clk, posedge reset) begin
	   if(reset) begin // reset counters to 0
		  obj_position_counter <= 10'd0;
		  game_time <= 11'd0;
		end
		// Reset level whenever user wins, loses, or goes to the menu screen.
		else if(menuScreen == 1 | playerWon == 1 | playerLost == 1) begin
		  obj_position_counter <= 10'd0;
		  game_time <= 11'd0;
		end
		else begin
		  // Resets the movement of the obstacles position when it passes the screen or when the next state of the level comes up.
		  if(obj_position_counter >= 10'd680 | reset_obj_count) obj_position_counter <= 10'd0;
		  else obj_position_counter <= obj_position_counter + 10'd5;
		  game_time <= game_time + 11'd1; // increment counter by 1
		end
    end
  endmodule
	