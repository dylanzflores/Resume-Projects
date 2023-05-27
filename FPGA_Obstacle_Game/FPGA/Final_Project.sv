module Final_Project(input logic 		 CLOCK_50, SW[0:0], KEY[0:0],
                     inout  logic [4:0] GPIO,
                     output logic       VGA_CLK, 
                     output logic       VGA_HS,
                     output logic       VGA_VS,
                     output logic       VGA_SYNC_N,
                     output logic       VGA_BLANK_N,
                     output logic [7:0] VGA_R,
                     output logic [7:0] VGA_G,
                     output logic [7:0] VGA_B,
					 output logic [6:0] HEX0, HEX1,
					 output logic [8:0] LEDG);
      // SW[0] = reset, KEY[0] = player control to jump                        
      logic game_clk, jump, reset_obj_count, fallingSq;
      logic victoryScreen, menuScreen, playerDeath;
      logic [9:0] distance;
      logic [9:0] obj_position_counter;
      logic [10:0] game_time;
      logic shapes[6:0];
		logic [3:0] bcd1, bcd2;
		logic cout1;
	 
      assign GPIO[1] = GPIO[0];
      assign GPIO[2] = GPIO[0];
      // Module instantiations
      levelLogic lm(CLOCK_50, SW[0], playerDeath, ~KEY[0], game_clk, game_time, reset_obj_count, fallingSq, shapes, victoryScreen, menuScreen);
      counter_shapes c1(game_clk, reset, menuScreen, victoryScreen, playerDeath, reset_obj_count, obj_position_counter, game_time);
      slowClkHz hz24 (CLOCK_50, SW[0], game_clk);
      jump_logic j(game_clk, SW[0], ~KEY[0], fallingSq, distance);
      vga vgaDev(CLOCK_50, game_clk, SW[0], victoryScreen, menuScreen, shapes, distance, obj_position_counter, playerDeath, GPIO[4], VGA_CLK, VGA_HS, VGA_VS, VGA_SYNC_N, VGA_BLANK_N,
                    VGA_R, VGA_G, VGA_B);
		// Number of attempts set
		bcdcounter1 d1 (game_clk, SW[0], playerDeath, victoryScreen, cout1, bcd1);
	   bcdcounter2 d2 (game_clk, SW[0], playerDeath, cout1, victoryScreen, LEDG[8], bcd2);			  
		sevenseg seg0 (bcd1, HEX0);
		sevenseg seg1 (bcd2, HEX1);

    endmodule

  // Seven segment display
  module sevenseg(input  logic [3:0] data,
  					   output logic [6:0] segments);
  
    always_comb
      case (data)
    	  4'h0:    segments = 7'b1000000;  // 40
    	  4'h1:    segments = 7'b1111001;  // 79
    	  4'h2:    segments = 7'b0100100;  // 24
    	  4'h3:    segments = 7'b0110000;  // 30
    	  4'h4:    segments = 7'b0011001;  // 19
    	  4'h5:    segments = 7'b0010010;  // 12
    	  4'h6:    segments = 7'b0000010;  // 02
    	  4'h7:    segments = 7'b1111000;  // 78
    	  4'h8:    segments = 7'b0000000;  // 00
    	  4'h9:    segments = 7'b0011000;  // 18
    	  default: segments = 7'bx;        // xx
      endcase
  
  endmodule
  // Counter for ones place of attempts					  
  module bcdcounter1(input logic clk, reset, en, win,
                     output logic  cout,
                     output logic  [3:0] cnt);
    always_ff @ (posedge clk, posedge reset) begin
        if(reset) cnt = 0;  
		  else if(win) cnt = 0;
        else if(cnt == 9 & en == 1) begin
                cnt = 0;
                cout = 0;
        end
        else if(cnt == 8 & en == 1) begin
                cnt <= cnt + 1;
                cout = 1;
        end
        else if(en == 1) begin
                cnt <= cnt + 1;
                cout = 0;
        end
    end
  endmodule

  // Counter for tens place of attempts
  module bcdcounter2(input logic clk, reset, en, cin, win,
							output logic cout,
                     output logic [3:0] cnt2);
    always_ff @ (posedge clk, posedge reset) begin
      if(reset) cnt2 = 0;
		else if(win) cnt2 = 0;
      else if(cnt2 == 9 & en == 1 & cin == 1) begin
		  cnt2 = 0;
		  cout = 1;
		end
		else if(cnt2 == 8 & en == 1 & cin == 1) begin
        cnt2 <= cnt2 + 1;
        cout = 0;
      end
      else if(cin == 1 & en == 1) begin
		  cnt2 <= cnt2 + 1;
		  cout = 0;
		end
    end
  endmodule