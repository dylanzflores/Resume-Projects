  module vga(input  logic 		clk, game_clk, reset, playerWon, menuScreen,
             input  logic  		shapes[6:0],
             input  logic [9:0] distance, obj_counter,
             output logic 		hits, buzz,
             output logic 		vgaclk,          // 25.175 MHz VGA clock 
             output logic 		hsync, vsync, 
             output logic 		sync_b, blank_b, // to monitor & DAC 
             output logic [7:0] r, g, b);  // to video DAC        
    logic [9:0] x, y; 
    always_ff @(posedge clk, posedge reset)
      if (reset)
        vgaclk = 1'b0;
      else
        vgaclk = ~vgaclk; 
    // generate monitor timing signals 
    vgaController vgaCont(vgaclk, reset, hsync, vsync, sync_b, blank_b, x, y); 
    // user-defined module to determine pixel color 
    videoGen game(x, y, vgaclk, distance, obj_counter, reset, game_clk, playerWon, menuScreen, shapes, r, g, b, hits, buzz); 
  endmodule

  // Module detecting whenever the player hits an obstacle that triggers a death
  module collisions_tri(input  logic 	    state,
						input  logic  [9:0] player_left, player_top, player_right, player_bot, 
						input  logic  [9:0] hit_left, hit_top, hit_right, hit_bot,
						output logic 	    hit);
    always_comb begin
	   if( (state == 1'b1) && (player_left >= hit_left && player_right <= hit_right && player_top <= hit_top && player_bot >= hit_bot) ) hit = 1'b1; // hit detected
	   else hit = 1'b0; // hit not triggered
	 end
  endmodule
	
	// Module generating the graphics logic of the game.
  module videoGen(input  logic [9:0] x, y, clk, distance, obj_position_counter,
				  input  logic		 reset, game_clk, playerWon, menuScreen,
				  input  logic 		 shapes [6:0],
				  output logic [7:0] r, g, b,
				  output logic 		 hits, buzz); 
    parameter base_lvl = 360; 
	 // ************************************************************************************************************************//
	 logic menu, win, player, ground;
	 logic obs[23:0], hitBox[23:0];
	 logic [9:0] player_left_loc, player_top_loc, player_right_loc, player_bottom_loc;
	 logic [9:0] hitBox_left[23:0], hitBox_right[23:0], hitBox_top[23:0], hitBox_bot[23:0];
	 logic [9:0] obs_top[23:0], obs_left[23:0];
	 assign player_left_loc = 10'd220;
	 assign player_right_loc = 10'd250;
	 assign player_top_loc = base_lvl - distance;
	 assign player_bottom_loc = 10'd400 - distance;
	 
	 generateMenuScreen m(x, y, obj_position_counter, menu); // menu screen
	 generateWinScreen(x, y, movingPosition, win); // win screen
	 sqGen mainSq(x, y, player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, player); // main player square character
	 sqGen ground1(x, y, 10'd0, 10'd400, 10'd700, 10'd405, ground); // level for player		  
	 // ************************************************************************************************************************//	
	 triangles_generating tri_generate(x, y, obj_position_counter, shapes, obs_left, obs_top, obs);
	 hitBox_top hB_top1(x, y, obj_position_counter, shapes, hitBox_left, hitBox_top, hitBox_right, hitBox_bot, hitBox);  
	 collisions_top C_top1(player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, hitBox_left, hitBox_right, hitBox_top, hitBox_bot, shapes, hits);
	 buzzer buzzer(clk, reset, hits, buzz);
	 
	 // Display shapes
	 display_to_vga_screen ngng(clk, reset, menu, win, menuScreen, playerWon, hits, player, ground, obs, hitBox, r, g, b);
		
  endmodule

  // Module to trigger the buzzer
  module buzzer (input  logic clk, reset, hits,
                 output logic buzz);                  
    logic [16:0] cnt;
    always_ff @ (posedge clk, posedge reset)
      if (reset)         cnt <= 17'b0;
      else if(~hits)     cnt <= 17'b0;
      else               cnt <= cnt + 17'b1;
    assign buzz = cnt[16];
  endmodule
  
  // Top module organizing all triangles being generated
  module triangles_generating(input logic [9:0]  x, y, obj_position_counter, 
							  input logic 		 shapes[6:0], 
							  output logic [9:0] obs_left[23:0], obs_top[23:0],
							  output logic 		 obs [23:0]);
    parameter spawn_loc = 680;
    parameter base_lvl = 360; 
    // 680 is the default number on the x-axis of the VGA that spawns in the obstacles and the smaller this number gets, the more right the obstacle spawns
    // ************************************************************************************************************************//
	 // S0 triangle generates
    triangle_generate o1(x, y, obj_position_counter, shapes[0], obs[0], obs_left[0], obs_top[0]); 
    triangle_generate #(spawn_loc - 30) o12(x, y, obj_position_counter, shapes[0], obs[1], obs_left[1], obs_top[1]); 
    triangle_generate #(spawn_loc - 150) o13(x, y, obj_position_counter, shapes[0], obs[2], obs_left[2], obs_top[2]); 
    // S1 triangle generates
    triangle_generate #(spawn_loc - 120) o23(x, y, obj_position_counter, shapes[1], obs[3], obs_left[3], obs_top[3]); 
    // S2 triangle generates
    triangle_generate o2(x, y, obj_position_counter, shapes[2], obs[4], obs_left[4], obs_top[4]); 
     // S3 triangle generates
    triangle_generate #(spawn_loc - 60) o3(x, y, obj_position_counter, shapes[3], obs[6], obs_left[6], obs_top[6]); 
    triangle_generate #(spawn_loc - 30) o33(x, y, obj_position_counter, shapes[3], obs[7], obs_left[7], obs_top[7]); 
    // S4 triangle generates
    triangle_generate #(spawn_loc + 30) o40 (x, y, obj_position_counter, shapes[4], obs[9], obs_left[9], obs_top[9]); 
    triangle_generate #(spawn_loc) o41 (x, y, obj_position_counter, shapes[4], obs[10], obs_left[10], obs_top[10]); 
    triangle_generate #(spawn_loc - 30) o42 (x, y, obj_position_counter, shapes[4], obs[11], obs_left[11], obs_top[11]); 
    triangle_generate #(spawn_loc - 130) o401 (x, y, obj_position_counter, shapes[4], obs[12], obs_left[12], obs_top[12]); 
    triangle_generate #(spawn_loc - 160) o411 (x, y, obj_position_counter, shapes[4], obs[13], obs_left[13], obs_top[13]); 
    triangle_generate #(spawn_loc - 190) o421 (x, y, obj_position_counter, shapes[4], obs[14], obs_left[14], obs_top[14]); 
    
    // S5
    triangle_generate #(spawn_loc - 190) o5 (x, y, obj_position_counter, shapes[5], obs[15], obs_left[15], obs_top[15]); 
    triangle_generate #(spawn_loc - 220) o51( x, y, obj_position_counter, shapes[5], obs[16], obs_left[16], obs_top[16]); 
    triangle_generate #(spawn_loc - 250) o52(x, y, obj_position_counter, shapes[5], obs[17], obs_left[17], obs_top[17]);
     
  endmodule
  
  // Top module organizing all hitBox instantiations
  module hitBox_top(input  logic [9:0]   x, y, obj_position_counter,
				    input  logic 		 shapes[6:0],
				    output logic [9:0] 	 hitBox_left[23:0], hitBox_top[23:0], hitBox_right[23:0], hitBox_bot[23:0],
				    output logic 		 hitBox [23:0]);
    // S0
    hitBoxGen h(x, y, obj_position_counter, shapes[0], hitBox_left[0], hitBox_top[0], hitBox_right[0], hitBox_bot[0], hitBox[0]); 
    hitBoxGen #(650) h12(x, y, obj_position_counter, shapes[0], hitBox_left[1], hitBox_top[1], hitBox_right[1], hitBox_bot[1], hitBox[1]); 
    hitBoxGen #(530) h13(x, y, obj_position_counter, shapes[0], hitBox_left[2], hitBox_top[2], hitBox_right[2], hitBox_bot[2], hitBox[2]); 
    // S1
    hitBoxGen #(560) h2(x, y, obj_position_counter, shapes[1], hitBox_left[3], hitBox_top[3], hitBox_right[3], hitBox_bot[3], hitBox[3]);
    // S2
    hitBoxGen h3(x, y, obj_position_counter, shapes[2], hitBox_left[4], hitBox_top[4], hitBox_right[4], hitBox_bot[4], hitBox[4]); 
    hitBoxGen #(530, 325) sq1(x, y, obj_position_counter, shapes[2], hitBox_left[5], hitBox_top[5], hitBox_right[5], hitBox_bot[5],hitBox[5]); // hitBox[5] display
  
    // S3
    hitBoxGen #(620) h40  (x, y, obj_position_counter, shapes[3], hitBox_left[6], hitBox_top[6], hitBox_right[6], hitBox_bot[6], hitBox[6]); 
    hitBoxGen #(650) h41  (x, y, obj_position_counter, shapes[3], hitBox_left[7], hitBox_top[7], hitBox_right[7], hitBox_bot[7], hitBox[7]); 
    hitBoxGen #(300, 325) h42(x, y, obj_position_counter, shapes[3], hitBox_left[8], hitBox_top[8], hitBox_right[8], hitBox_bot[8],hitBox[8]); // hitBox[8] display
  
    // S4
    hitBoxGen #(710) h50  (x, y, obj_position_counter, shapes[4], hitBox_left[9], hitBox_top[9], hitBox_right[9], hitBox_bot[9], hitBox[9]); 
    hitBoxGen #(680) h51  (x, y, obj_position_counter, shapes[4], hitBox_left[10], hitBox_top[10], hitBox_right[10], hitBox_bot[10], hitBox[10]); 
    hitBoxGen #(650) h52  (x, y, obj_position_counter, shapes[4], hitBox_left[11], hitBox_top[11], hitBox_right[11], hitBox_bot[11], hitBox[11]); 
    hitBoxGen #(550) h501 (x, y, obj_position_counter, shapes[4], hitBox_left[12], hitBox_top[12], hitBox_right[12], hitBox_bot[12], hitBox[12]); 
    hitBoxGen #(520) h511 (x, y, obj_position_counter, shapes[4], hitBox_left[13], hitBox_top[13], hitBox_right[13], hitBox_bot[13], hitBox[13]); 
    hitBoxGen #(490) h521 (x, y, obj_position_counter, shapes[4], hitBox_left[14], hitBox_top[14], hitBox_right[14], hitBox_bot[14], hitBox[14]);
    
    // S5
    hitBoxGen #(490) h6(x, y, obj_position_counter, shapes[5], hitBox_left[15], hitBox_top[15], hitBox_right[15], hitBox_bot[15], hitBox[15]);
    hitBoxGen #(460) h61 (x, y, obj_position_counter, shapes[5], hitBox_left[16], hitBox_top[16], hitBox_right[16], hitBox_bot[16], hitBox[16]);
    hitBoxGen #(430) h62 (x, y, obj_position_counter, shapes[5], hitBox_left[17], hitBox_top[17], hitBox_right[17], hitBox_bot[17], hitBox[17]); 
    hitBoxGen #(700, 325) h63 (x, y, obj_position_counter, shapes[5], hitBox_left[18], hitBox_top[18], hitBox_right[18], hitBox_bot[18], hitBox[18]); // hitBox[18] display
    hitBoxGen #(750, 325) h64 (x, y, obj_position_counter, shapes[5], hitBox_left[19], hitBox_top[19], hitBox_right[19], hitBox_bot[19], hitBox[19]); // hitBox[19] display
    hitBoxGen #(800, 325) h65 (x, y, obj_position_counter, shapes[5], hitBox_left[20], hitBox_top[20], hitBox_right[20], hitBox_bot[20], hitBox[20]); // hitBox[20] display
  
    // S6
    hitBoxGen #(430, 390) h7(x, y, obj_position_counter, shapes[6], hitBox_left[21], hitBox_top[21], hitBox_right[21], hitBox_bot[21], hitBox[21]); // hitBox[21]
    hitBoxGen #(610, 325) h71(x, y, obj_position_counter, shapes[6], hitBox_left[22], hitBox_top[22], hitBox_right[22], hitBox_bot[22], hitBox[22]); // hitBox[22]
    hitBoxGen #(700, 390) h72(x, y, obj_position_counter, shapes[6], hitBox_left[23], hitBox_top[23], hitBox_right[23], hitBox_bot[23], hitBox[23]); // hitBox[23]
  endmodule
  
  // Top module organizing all cases of collisions possible
  module collisions_top(input  logic [9:0] player_left_loc, player_top_loc, player_right_loc, player_bottom_loc,
  					    input  logic [9:0] hitBox_left[23:0], hitBox_right[23:0], hitBox_top[23:0], hitBox_bot[23:0],
  					    input  logic 	   shapes[6:0],
  					    output logic 	   hits);
  							 
    logic collisions[23:0]; // collisions array
	 // S0 collisions logic
    collisions_tri c1(shapes[0], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  						  hitBox_left[0], hitBox_top[0], hitBox_right[0], hitBox_bot[0], collisions[0]);
    collisions_tri c2(shapes[0], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc,
  						  hitBox_left[1], hitBox_top[1], hitBox_right[1], hitBox_bot[1], collisions[1]);
    collisions_tri c3(shapes[0], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  						  hitBox_left[2], hitBox_top[2], hitBox_right[2], hitBox_bot[2], collisions[2]);	
  	 // S1 collisions logic					  
    collisions_tri c4(shapes[1], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  						  hitBox_left[3], hitBox_top[3], hitBox_right[3], hitBox_bot[3], collisions[3]);
  	 // S2 collisions logic					  
    collisions_tri c5(shapes[2], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  					  hitBox_left[4], hitBox_top[4], hitBox_right[4], hitBox_bot[4], collisions[4]);
    collisions_tri hq1(shapes[2], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  					  hitBox_left[5], hitBox_top[5], hitBox_right[5], hitBox_bot[5], collisions[5]);
  	 // S3 collisions logic				  
    collisions_tri c6(shapes[3], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  					  hitBox_left[6], hitBox_top[6], hitBox_right[6], hitBox_bot[6], collisions[6]);				 
    collisions_tri c7(shapes[3], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  					  hitBox_left[7], hitBox_top[7], hitBox_right[7], hitBox_bot[7], collisions[7]);				 
    collisions_tri c8(shapes[3], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  					  hitBox_left[8], hitBox_top[8], hitBox_right[8], hitBox_bot[8], collisions[8]);	
  	 // S4 collisions logic				  
    collisions_tri c9(shapes[4], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  					  hitBox_left[9], hitBox_top[9], hitBox_right[9], hitBox_bot[9], collisions[9]);	
    collisions_tri c11(shapes[4], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  					  hitBox_left[10], hitBox_top[10], hitBox_right[10], hitBox_bot[10], collisions[10]);
    collisions_tri c12(shapes[4], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  					  hitBox_left[11], hitBox_top[11], hitBox_right[11], hitBox_bot[11], collisions[11]);
    collisions_tri c13(shapes[4], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  					  hitBox_left[12], hitBox_top[12], hitBox_right[12], hitBox_bot[12], collisions[12]);
    collisions_tri c14(shapes[4], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  					  hitBox_left[13], hitBox_top[13], hitBox_right[13], hitBox_bot[13], collisions[13]);
    collisions_tri c15(shapes[4], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  					  hitBox_left[14], hitBox_top[14], hitBox_right[14], hitBox_bot[14], collisions[14]);
    // S5 collisions logic					  
    collisions_tri c16(shapes[5], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  					  hitBox_left[15], hitBox_top[15], hitBox_right[15], hitBox_bot[15], collisions[15]);
    collisions_tri c17(shapes[5], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  					  hitBox_left[16], hitBox_top[16], hitBox_right[16], hitBox_bot[16], collisions[16]);
    collisions_tri c18(shapes[5], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  					  hitBox_left[17], hitBox_top[17], hitBox_right[17], hitBox_bot[17], collisions[17]);	
    collisions_tri c19(shapes[5], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  					  hitBox_left[18], hitBox_top[18], hitBox_right[18], hitBox_bot[18], collisions[18]);
    collisions_tri c20(shapes[5], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  					  hitBox_left[19], hitBox_top[19], hitBox_right[19], hitBox_bot[19], collisions[19]);	
    collisions_tri c21(shapes[5], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  					  hitBox_left[20], hitBox_top[20], hitBox_right[20], hitBox_bot[20], collisions[20]);
    // S6 collisions logic	  
    collisions_tri c22(shapes[6], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  					  hitBox_left[21], hitBox_top[21], hitBox_right[21], hitBox_bot[21], collisions[21]);		
    collisions_tri c23(shapes[6], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  					  hitBox_left[22], hitBox_top[22], hitBox_right[22], hitBox_bot[22], collisions[22]); 
    collisions_tri c24(shapes[6], player_left_loc, player_top_loc, player_right_loc, player_bottom_loc, 
  					  hitBox_left[23], hitBox_top[23], hitBox_right[23], hitBox_bot[23], collisions[23]);
  					  
    // collisions detection and any collision detected results in a failed attempt					  
    assign hits = collisions[0]| collisions[1] | collisions[2] | collisions[3] | collisions[4] | collisions[5] | collisions[6] | collisions[7] |
    collisions[8] | collisions[9] | collisions[10] | collisions[11] | collisions[12] | collisions[13] | collisions[14] | collisions[15] | collisions[16]
    | collisions[17] | collisions[18] | collisions[19] | collisions[20] | collisions[21] | collisions[22] | collisions[23];
    
  endmodule
  
	// Hitbox Generator for spikes
	module hitBoxGen #(parameter spawn_loc = 680, parameter hitBox_spawn_base_lvl = 375) 
						(input  logic [9:0] x, y, count,
						 input  logic 		make,
						 output logic [9:0] left, top, right, bot,
						 output logic 		shape);
							
		assign left = spawn_loc - count - 22;
		assign right = spawn_loc + 30 - count;
		assign bot = hitBox_spawn_base_lvl;
		assign top = hitBox_spawn_base_lvl + 30;
		assign shape = make ? (x > (left) & x < (right) &  y > (bot) & y < (top) ) : 0; 
	endmodule 
	
	// Module that displays the game itself onto the VGA screen
	module display_to_vga_screen(input  logic 		clk, reset, 
								 input  logic 		menu, win, menuScreen, playerWon, playerLost, 
								 input  logic 		player, ground, obs[23:0], hitBox[23:0],
								 output logic [7:0] r_red, r_green, r_blue);
		logic display_obstacles, display_hitBox, display_triangles;
		// Display the obstacles generated at each instance of time in the level.
		assign display_triangles = obs[0] | obs[1] | obs[2] | obs[3] | obs[4] | obs[5] | obs[6] | obs[7]| obs[9] | obs[10] | obs[11] | obs[12]
		| obs[13] | obs[14] | obs[15] | obs[16] | obs[17] | obs[21] | obs[22] | obs[23];
		assign display_hitBox = hitBox[5] | hitBox[8] | hitBox[18] | hitBox[19] | hitBox[20] | hitBox[21] | hitBox[22] | hitBox[23];
		assign display_obstacles = display_triangles | display_hitBox;
		
		always_ff @(posedge clk) begin		
			// Display the menu screen until the user presses a button
			if(menuScreen == 1) begin
				if(menu) begin
					r_red = 8'hFF;
					r_green = 8'hFF;
					r_blue = 8'hFF;
				end
				// Background level
				else begin
					r_red = 8'h25;
					r_green = 8'hAA;
					r_blue = 8'hAD;
				end
			end
			// Display the win screen showing that the user won.
			else if(playerWon == 1) begin
			  if(win) begin
			    r_red = 8'hFF;
			    r_green = 8'hFF;
				 r_blue = 8'hFF;
			  end
			  // Player graphics
			  else if(player) begin	
			    r_red = 8'hFF;
			    r_green = 8'h00;
			    r_blue = 8'h00;
			  end
			  // Ground displayed
			  else if(ground) begin
			    r_red = 8'hFF;
			    r_green = 8'hFF;
			    r_blue = 8'hFF;
			  end
			  // Background level
			  else begin
			    r_red = 8'h25;
				 r_green = 8'hAA;
				 r_blue = 8'hAD;
			  end
			end
			else begin
			  // Player graphics
			  if(player & playerLost == 0) begin
			    r_red = 8'hFF;
			    r_green = 8'h00;
			    r_blue = 8'h00;
			  end
			  else if(!player) begin // background
			    r_red = 8'h25;
			    r_green = 8'hAA;
			    r_blue = 8'hAD;
			  end
			  else begin // float values of red, green, blue
			    r_red = 8'hzz;
			    r_green = 8'hzz;
			    r_blue = 8'hzz;
			  end
			  if(display_obstacles) begin // obstacle 1
			    r_red = 8'h00;
			    r_green = 8'h00;
			    r_blue = 8'h00;
			  end
			  // Ground displayed
			  else if(ground) begin
			    r_red = 8'hFF;
			    r_green = 8'hFF;
			    r_blue = 8'hFF;
			  end
			end
		end																			
	endmodule	
  // Generate a triangle obstacle									  
	module triangle_generate #(parameter spawn_loc = 680, parameter triangle_spawn_base_lvl = 370)
									 (input  logic [9:0]  x, y, movingPosition, 
									  input  logic 		  make_triangle,
									  output logic        triangle,
									  output logic [9:0]  obstacle_pos_left, obstacle_pos_top); 
									 
		logic [750:0] triROM[750:0]; // character generator ROM 
		logic [750:0] ROMline;            // a line read from the ROM 
		
		// initialize ROM with characters from text file 
		initial $readmemb("triangle.txt", triROM); 
		// index into ROM 
		assign obstacle_pos_left = x + movingPosition - spawn_loc;
		assign obstacle_pos_top = y - triangle_spawn_base_lvl;
		// Generate triangle
		assign ROMline = triROM[obstacle_pos_top];  
		assign triangle = make_triangle ? ROMline[obstacle_pos_left] : 0; 
	
	endmodule 


  // Generate Menu Screen logic
  module generateMenuScreen(input  logic [9:0] x, y, movingPosition,
  						    output logic       menu);
    logic [749:0] menuROM[749:0]; // character generator ROM 
    logic [749:0] ROMline;            // a line read from the ROM 
    
    // initialize ROM with characters from text file 
    initial $readmemb("menuText.txt", menuROM); 
    // index into ROM 
    assign ROMline = menuROM[y - 200];  
    assign menu = ROMline[10'd749 - x - 200]; 
    
  endmodule

	// Generate Menu Screen logic
	module generateWinScreen(input  logic [9:0] x, y, movingPosition,
							 output logic 		win);
		logic [749:0] winROM[749:0]; // character generator ROM 
		logic [749:0] ROMline;            // a line read from the ROM 
		// initialize ROM with characters from text file 
		initial $readmemb("winScreen.txt", winROM); 
		// index into ROM 
		assign ROMline = winROM[y - 200];  
		assign win = ROMline[10'd749 - x - 200]; 
	endmodule
	
	// Square logic
	module sqGen(input  logic [9:0] x, y, left, top, right, bot, 
				 output logic 	    shape);
		assign shape = (x > left & x < right &  y > top & y < bot); 
	endmodule 	
	
	module vgaController #(parameter HBP     = 10'd48,   // horizontal back porch
								  HACTIVE = 10'd640,  // number of pixels per line
								  HFP     = 10'd16,   // horizontal front porch
								  HSYN    = 10'd96,   // horizontal sync pulse = 96 to move electron gun back to left
								  HMAX    = HBP + HACTIVE + HFP + HSYN, //48+640+16+96=800: number of horizontal pixels (i.e., clock cycles)
								  VBP     = 10'd32,   // vertical back porch
								  VACTIVE = 10'd480,  // number of lines
								  VFP     = 10'd11,   // vertical front porch
								  VSYN    = 10'd2,    // vertical sync pulse = 2 to move electron gun back to top
								  VMAX    = VBP + VACTIVE + VFP  + VSYN) //32+480+11+2=525: number of vertical pixels (i.e., clock cycles)                      
	
						  (input  logic 	  vgaclk, reset,
						   output logic 	  hsync, vsync, sync_b, blank_b, 
						   output logic [9:0] hcnt, vcnt); 
	
			// counters for horizontal and vertical positions 
		always @(posedge vgaclk, posedge reset) begin 
			if (reset) begin
				hcnt <= 0;
				vcnt <= 0;
			end
			else begin
				hcnt++; 
					if (hcnt == HMAX) begin 
					hcnt <= 0; 
				vcnt++; 
				if (vcnt == VMAX) 
					vcnt <= 0; 
				end 
			end
		end 
		
		// compute sync signals (active low)
		assign hsync  = ~( (hcnt >= (HBP + HACTIVE + HFP)) & (hcnt < HMAX) ); 
		assign vsync  = ~( (vcnt >= (VBP + VACTIVE + VFP)) & (vcnt < VMAX) ); 

		// assign sync_b = hsync & vsync; 
		assign sync_b = 1'b0;  // this should be 0 for newer monitors

		// force outputs to black when not writing pixels
		assign blank_b = (hcnt > HBP & hcnt < (HBP + HACTIVE)) & (vcnt > VBP & vcnt < (VBP + VACTIVE)); 
	endmodule 
	