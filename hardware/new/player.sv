module player (
    input  logic        Reset, 
    input  logic        frame_clk,
    input  logic [7:0]  keycode,
    
    // Goal reset signal
    input  logic        goal_reset,
    
    // Other player's position for collision detection
    input  logic [9:0]  OtherPlayerX,
    input  logic [9:0]  OtherPlayerY,

    output logic [9:0]  PlayerX, 
    output logic [9:0]  PlayerY,
    output logic signed [9:0]  PlayerVelX,
    output logic signed [9:0]  PlayerVelY,
    output logic        is_kicking,  
    output logic [9:0]  PlayerWidth   
);
    
    parameter [9:0] NORMAL_W = 48;
    parameter [9:0] KICK_W = 63;
    parameter [9:0] PLAYER_H = 63; 
    
    parameter [9:0] X_MIN = 48;
    parameter [9:0] X_MAX = 588;
    
    parameter [9:0] GROUND_Y = 257;
    parameter [9:0] X_SPEED  = 3;
    parameter [9:0] JUMP_VEL = 15;
    parameter [9:0] GRAVITY  = 1;

    parameter [9:0] INIT_X = 213;
    parameter [9:0] INIT_Y = 257;

    logic [9:0] Player_X_Pos, Player_Y_Pos;
    logic signed [9:0] Player_X_Motion, Player_Y_Motion;
    
    logic [9:0] Player_X_Pos_in, Player_Y_Pos_in;
    logic signed [9:0] Player_X_Motion_in, Player_Y_Motion_in;
    
    assign is_kicking = keycode[3];
    
    assign PlayerWidth = is_kicking ? KICK_W : NORMAL_W;
    
    always_ff @ (posedge frame_clk or posedge Reset) begin
        if (Reset) begin 
            Player_X_Pos    <= INIT_X;
            Player_Y_Pos    <= GROUND_Y;
            Player_X_Motion <= 0;
            Player_Y_Motion <= 0;
        end
        else if (goal_reset) begin
            Player_X_Pos    <= INIT_X;
            Player_Y_Pos    <= GROUND_Y;
            Player_X_Motion <= 0;
            Player_Y_Motion <= 0;
        end
        else begin 
            Player_X_Pos    <= Player_X_Pos_in;
            Player_Y_Pos    <= Player_Y_Pos_in;
            Player_X_Motion <= Player_X_Motion_in;
            Player_Y_Motion <= Player_Y_Motion_in;
        end
    end

    always_comb begin
        int X_Pos_Next, Y_Pos_Next;
        int Y_Motion_Next;
        
        int other_left, other_right, other_top, other_bottom;
        
        int my_curr_x, my_curr_y;
        
        int my_left, my_right, my_top, my_bottom;
        int my_width;
        
        int pen_left, pen_right, pen_top, pen_bottom;
        
        logic can_jump;
        logic on_head;
        
        my_width = int'(PlayerWidth); 
        
        other_left   = int'(OtherPlayerX);
        other_right  = int'(OtherPlayerX) + int'(NORMAL_W);  
        other_top    = int'(OtherPlayerY);
        other_bottom = int'(OtherPlayerY) + int'(PLAYER_H);
        
        my_curr_x = int'(Player_X_Pos);
        my_curr_y = int'(Player_Y_Pos);
        
        can_jump = 1'b0;
        on_head = 1'b0;


        Player_X_Motion_in = 0;

        if (keycode[0] == 1'b1) 
            Player_X_Motion_in = -1 * int'(X_SPEED);
        else if (keycode[1] == 1'b1) 
            Player_X_Motion_in = int'(X_SPEED);

        X_Pos_Next = my_curr_x + int'(Player_X_Motion_in);


        Y_Motion_Next = int'(Player_Y_Motion) + int'(GRAVITY);

        if (my_curr_y >= int'(GROUND_Y)) begin
            can_jump = 1'b1;
        end
        

        if ((my_curr_x + my_width > other_left) && 
            (my_curr_x < other_right)) begin
            if ((my_curr_y + int'(PLAYER_H) >= other_top - 2) && 
                (my_curr_y + int'(PLAYER_H) <= other_top + 5)) begin
                can_jump = 1'b1;
            end
        end
        
        if (can_jump && (keycode[2] == 1'b1)) begin
            Y_Motion_Next = -1 * int'(JUMP_VEL);
        end

        Y_Pos_Next = my_curr_y + Y_Motion_Next;


        my_left   = X_Pos_Next;
        my_right  = X_Pos_Next + my_width;
        my_top    = Y_Pos_Next;
        my_bottom = Y_Pos_Next + int'(PLAYER_H);
        
        pen_left   = 0;
        pen_right  = 0;
        pen_top    = 0;
        pen_bottom = 0;
        
        if ((my_right > other_left) && (my_left < other_right) &&
            (my_bottom > other_top) && (my_top < other_bottom)) begin
            
            pen_left   = my_right - other_left; 
            pen_right  = other_right - my_left;  
            pen_top    = my_bottom - other_top; 
            pen_bottom = other_bottom - my_top;  
            
            
            if ((pen_top <= pen_bottom) && (pen_top <= pen_left) && (pen_top <= pen_right)) begin
                Y_Pos_Next = other_top - int'(PLAYER_H);
                if (Y_Motion_Next > 0) 
                    Y_Motion_Next = 0;
            end
            else if ((pen_bottom <= pen_top) && (pen_bottom <= pen_left) && (pen_bottom <= pen_right)) begin
                Y_Pos_Next = other_bottom;
                if (Y_Motion_Next < 0)
                    Y_Motion_Next = 1;  
            end
            else if (pen_left <= pen_right) begin
                X_Pos_Next = other_left - my_width;
                Player_X_Motion_in = 0; 
            end
            else begin
                X_Pos_Next = other_right;
                Player_X_Motion_in = 0;  
            end
        end
        
        my_left   = X_Pos_Next;
        my_right  = X_Pos_Next + my_width;
        my_top    = Y_Pos_Next;
        my_bottom = Y_Pos_Next + int'(PLAYER_H);
        
        if ((my_right > other_left) && (my_left < other_right)) begin
            if ((my_bottom >= other_top - 2) && (my_bottom <= other_top + 3)) begin
                on_head = 1'b1;
                Y_Pos_Next = other_top - int'(PLAYER_H);
                Y_Motion_Next = 0;
            end
        end

        if (X_Pos_Next < int'(X_MIN))
            Player_X_Pos_in = X_MIN;
        else if ((X_Pos_Next + my_width) > int'(X_MAX))
            Player_X_Pos_in = X_MAX - my_width[9:0];
        else
            Player_X_Pos_in = X_Pos_Next;

        if (Y_Pos_Next >= int'(GROUND_Y)) begin
            Player_Y_Pos_in    = GROUND_Y;
            Player_Y_Motion_in = 0;
        end
        else begin
            Player_Y_Pos_in    = Y_Pos_Next;
            Player_Y_Motion_in = Y_Motion_Next;
        end
    end
    
    assign PlayerX = Player_X_Pos;
    assign PlayerY = Player_Y_Pos;
    
    assign PlayerVelX = Player_X_Motion;
    assign PlayerVelY = Player_Y_Motion;

endmodule