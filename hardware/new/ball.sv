module ball (
    input  logic        Reset, 
    input  logic        frame_clk, 
    
    input  logic        apply_force, 
    input  logic signed [9:0] force_x, 
    input  logic signed [9:0] force_y,
    
    input  logic        goal_reset,

    output logic [9:0]  BallX, 
    output logic [9:0]  BallY,
    output logic [9:0]  BallS,
    output logic signed [9:0] BallVelX,
    output logic signed [9:0] BallVelY
);
    
    parameter [9:0] BALL_RADIUS = 15; 
    
    parameter [9:0] X_MIN = 0;
    parameter [9:0] X_MAX = 639;
    parameter [9:0] FLOOR = 320;

    parameter [9:0] LEFT_GOAL_X   = 32;
    parameter [9:0] RIGHT_GOAL_X  = 604;
    parameter [9:0] GOAL_Y_TOP    = 176;
    parameter [9:0] GOAL_Y_BOTTOM = 316;

    parameter [9:0] LEFT_CROSSBAR_X_MAX  = 48;
    parameter [9:0] RIGHT_CROSSBAR_X_MIN = 588;
    parameter [9:0] CROSSBAR_Y           = 156;

    parameter [9:0] GRAVITY = 1;  
    parameter [9:0] X_FRICTION = 1; 
    
    parameter signed [9:0] MAX_VELOCITY = 15;

    parameter [9:0] INIT_X = 320;
    parameter [9:0] INIT_Y = 50;

    logic [9:0] Ball_X_Pos, Ball_Y_Pos;
    logic signed [9:0] Ball_X_Motion, Ball_Y_Motion;
    logic [9:0] Ball_X_Pos_in, Ball_Y_Pos_in;
    logic signed [9:0] Ball_X_Motion_in, Ball_Y_Motion_in;
    
    logic [4:0] friction_counter;

    function signed [9:0] clamp_velocity(input signed [9:0] vel);
        if (vel > MAX_VELOCITY)
            return MAX_VELOCITY;
        else if (vel < -MAX_VELOCITY)
            return -MAX_VELOCITY;
        else
            return vel;
    endfunction

    always_ff @ (posedge frame_clk or posedge Reset) begin
        if (Reset) begin 
            Ball_X_Pos    <= INIT_X;
            Ball_Y_Pos    <= INIT_Y;
            Ball_X_Motion <= 0;   
            Ball_Y_Motion <= 0;
            friction_counter <= 0;
        end
        else if (goal_reset) begin
            Ball_X_Pos    <= INIT_X;
            Ball_Y_Pos    <= INIT_Y;
            Ball_X_Motion <= 0;   
            Ball_Y_Motion <= 0;
            friction_counter <= 0;
        end
        else begin 
            Ball_X_Pos    <= Ball_X_Pos_in;
            Ball_Y_Pos    <= Ball_Y_Pos_in;
            Ball_X_Motion <= clamp_velocity(Ball_X_Motion_in);
            Ball_Y_Motion <= clamp_velocity(Ball_Y_Motion_in);
            
            if (Ball_Y_Pos + BALL_RADIUS >= FLOOR) 
                friction_counter <= friction_counter + 1;
            else 
                friction_counter <= 0;
        end
    end

    always_comb begin
        int X_Pos_Next, Y_Pos_Next;
        int X_Motion_Next, Y_Motion_Next;
        logic in_goal_height;
        logic in_left_crossbar_x;
        logic in_right_crossbar_x;
        logic hit_left_crossbar;
        logic hit_right_crossbar;

        Y_Motion_Next = int'(Ball_Y_Motion) + int'(GRAVITY);
        X_Motion_Next = int'(Ball_X_Motion);

        if (apply_force) begin
            X_Motion_Next = X_Motion_Next + int'(force_x);
            Y_Motion_Next = Y_Motion_Next + int'(force_y);
        end

        Y_Pos_Next = int'(Ball_Y_Pos) + Y_Motion_Next;
        X_Pos_Next = int'(Ball_X_Pos) + X_Motion_Next;

        if (Y_Pos_Next + int'(BALL_RADIUS) >= int'(FLOOR)) begin
            Y_Motion_Next = (-3 * Y_Motion_Next) >>> 2;
            
            if ( (Y_Motion_Next > -2) && (Y_Motion_Next < 2) ) 
                Y_Motion_Next = 0;

            Y_Pos_Next = int'(FLOOR) - int'(BALL_RADIUS);
            
            if (friction_counter == 5'b11111) begin
                if (X_Motion_Next > 0) X_Motion_Next -= int'(X_FRICTION);
                else if (X_Motion_Next < 0) X_Motion_Next += int'(X_FRICTION);
            end
        end

        else if (Y_Pos_Next - int'(BALL_RADIUS) <= 0) begin
            Y_Motion_Next = (-3 * Y_Motion_Next) >>> 2;
            Y_Pos_Next = int'(BALL_RADIUS);
        end

        in_left_crossbar_x = (X_Pos_Next >= 0) && (X_Pos_Next <= int'(LEFT_CROSSBAR_X_MAX));

        in_right_crossbar_x = (X_Pos_Next >= int'(RIGHT_CROSSBAR_X_MIN)) && (X_Pos_Next <= int'(X_MAX));
        
        hit_left_crossbar = in_left_crossbar_x && 
                            (Y_Pos_Next + int'(BALL_RADIUS) >= int'(CROSSBAR_Y)) &&
                            (int'(Ball_Y_Pos) + int'(BALL_RADIUS) < int'(CROSSBAR_Y)) &&
                            (Y_Motion_Next > 0);
        
        hit_right_crossbar = in_right_crossbar_x && 
                             (Y_Pos_Next + int'(BALL_RADIUS) >= int'(CROSSBAR_Y)) &&
                             (int'(Ball_Y_Pos) + int'(BALL_RADIUS) < int'(CROSSBAR_Y)) &&
                             (Y_Motion_Next > 0);
        
        if (hit_left_crossbar || hit_right_crossbar) begin
            Y_Motion_Next = (-3 * Y_Motion_Next) >>> 2;
            Y_Pos_Next = int'(CROSSBAR_Y) - int'(BALL_RADIUS);
        end

        in_goal_height = (Y_Pos_Next >= int'(GOAL_Y_TOP)) && (Y_Pos_Next <= int'(GOAL_Y_BOTTOM));

        if (X_Pos_Next - int'(BALL_RADIUS) <= int'(X_MIN)) begin
            if (in_goal_height) begin
                if (X_Pos_Next < -50) begin
                    X_Pos_Next = -50;
                    X_Motion_Next = 0;
                end
            end
            else begin
                X_Motion_Next = (-3 * X_Motion_Next) >>> 2;
                X_Pos_Next = int'(X_MIN) + int'(BALL_RADIUS);
            end
        end
        else if (X_Pos_Next + int'(BALL_RADIUS) >= int'(X_MAX)) begin
            if (in_goal_height) begin
                if (X_Pos_Next > 689) begin
                    X_Pos_Next = 689;
                    X_Motion_Next = 0;
                end
            end
            else begin
                X_Motion_Next = (-3 * X_Motion_Next) >>> 2;
                X_Pos_Next = int'(X_MAX) - int'(BALL_RADIUS);
            end
        end

        Ball_X_Pos_in    = X_Pos_Next;
        Ball_Y_Pos_in    = Y_Pos_Next;
        Ball_X_Motion_in = X_Motion_Next;
        Ball_Y_Motion_in = Y_Motion_Next;
    end
    
    assign BallX = Ball_X_Pos;
    assign BallY = Ball_Y_Pos;
    assign BallS = BALL_RADIUS;
    assign BallVelX = Ball_X_Motion;
    assign BallVelY = Ball_Y_Motion;

endmodule