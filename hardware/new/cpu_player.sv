module cpu_player (
    input  logic        Reset,
    input  logic        frame_clk,
    
    input  logic [9:0]  ball_x,
    input  logic [9:0]  ball_y,
    input  logic signed [9:0] ball_vel_x,
    input  logic signed [9:0] ball_vel_y,
    
    input  logic [9:0]  cpu_x,
    input  logic [9:0]  cpu_y,
    
    input  logic [9:0]  player_x,
    input  logic [9:0]  player_y,
    
    output logic [7:0]  cpu_keycode
);

    parameter [9:0] FIELD_CENTER_X = 320;
    parameter [9:0] CPU_GOAL_X = 588;
    parameter [9:0] GROUND_Y = 257;
    parameter [9:0] CPU_HOME_X = 480;
    
    parameter [9:0] KICK_DISTANCE_X = 70;
    parameter [9:0] KICK_DISTANCE_Y = 80;
    parameter [9:0] JUMP_TRIGGER_Y = 200;
    parameter [9:0] JUMP_DISTANCE_X = 120;
    parameter [9:0] DEAD_ZONE = 15;
    parameter [9:0] DEFENSIVE_LINE = 400;
    
    parameter [5:0] REACTION_FRAMES = 8;
    logic [5:0] reaction_counter;
    
    logic [9:0] delayed_ball_x, delayed_ball_y;
    logic signed [9:0] delayed_ball_vel_x, delayed_ball_vel_y;
    
    logic [9:0] ball_x_history [0:15];
    logic [9:0] ball_y_history [0:15];
    logic signed [9:0] ball_vel_x_history [0:15];
    logic signed [9:0] ball_vel_y_history [0:15];
    logic [3:0] history_index;
    
    logic [9:0] cpu_center_x;
    assign cpu_center_x = cpu_x + 24;
    
    logic [10:0] dist_to_ball_x;
    logic [10:0] dist_to_ball_y;
    logic ball_is_left;
    logic ball_is_above;
    
    logic cpu_on_ground;
    logic ball_coming_toward_cpu;
    logic ball_in_danger_zone;
    logic should_be_defensive;
    
    logic move_left, move_right, do_jump, do_kick;
    
    always_ff @(posedge frame_clk or posedge Reset) begin
        if (Reset) begin
            history_index <= 4'd0;
            for (int i = 0; i < 16; i++) begin
                ball_x_history[i] <= FIELD_CENTER_X;
                ball_y_history[i] <= 10'd100;
                ball_vel_x_history[i] <= 10'sd0;
                ball_vel_y_history[i] <= 10'sd0;
            end
        end
        else begin
            ball_x_history[history_index] <= ball_x;
            ball_y_history[history_index] <= ball_y;
            ball_vel_x_history[history_index] <= ball_vel_x;
            ball_vel_y_history[history_index] <= ball_vel_y;
            
            history_index <= history_index + 1'b1;
        end
    end
    
    logic [3:0] delayed_index;
    assign delayed_index = history_index - REACTION_FRAMES[3:0];
    
    always_comb begin
        delayed_ball_x = ball_x_history[delayed_index];
        delayed_ball_y = ball_y_history[delayed_index];
        delayed_ball_vel_x = ball_vel_x_history[delayed_index];
        delayed_ball_vel_y = ball_vel_y_history[delayed_index];
    end
    
    always_comb begin
        if (delayed_ball_x > cpu_center_x) begin
            dist_to_ball_x = delayed_ball_x - cpu_center_x;
            ball_is_left = 1'b0;
        end
        else begin
            dist_to_ball_x = cpu_center_x - delayed_ball_x;
            ball_is_left = 1'b1;
        end
        
        if (delayed_ball_y > cpu_y) begin
            dist_to_ball_y = delayed_ball_y - cpu_y;
            ball_is_above = 1'b0;
        end
        else begin
            dist_to_ball_y = cpu_y - delayed_ball_y;
            ball_is_above = 1'b1;
        end
        
        cpu_on_ground = (cpu_y >= GROUND_Y - 5);
        ball_coming_toward_cpu = (delayed_ball_vel_x > 0);
        ball_in_danger_zone = (delayed_ball_x > DEFENSIVE_LINE);
        should_be_defensive = (delayed_ball_x < FIELD_CENTER_X) && !ball_coming_toward_cpu;
    end
    
    always_comb begin
        move_left = 1'b0;
        move_right = 1'b0;
        do_jump = 1'b0;
        do_kick = 1'b0;
        
        if ((dist_to_ball_x < KICK_DISTANCE_X) && (dist_to_ball_y < KICK_DISTANCE_Y)) begin
            do_kick = 1'b1;
            
            if (ball_is_left && dist_to_ball_x > DEAD_ZONE) begin
                move_left = 1'b1;
            end
            else if (!ball_is_left && dist_to_ball_x > DEAD_ZONE) begin
                move_right = 1'b1;
            end
        end
        
        else if (ball_is_above && 
                 (delayed_ball_y < JUMP_TRIGGER_Y) && 
                 (dist_to_ball_x < JUMP_DISTANCE_X) &&
                 cpu_on_ground) begin
            do_jump = 1'b1;
            
            if (ball_is_left && dist_to_ball_x > DEAD_ZONE) begin
                move_left = 1'b1;
            end
            else if (!ball_is_left && dist_to_ball_x > DEAD_ZONE) begin
                move_right = 1'b1;
            end
        end

        else if (should_be_defensive) begin
            if (cpu_center_x < CPU_HOME_X - DEAD_ZONE) begin
                move_right = 1'b1;
            end
            else if (cpu_center_x > CPU_HOME_X + DEAD_ZONE) begin
                move_left = 1'b1;
            end
        end
        
        else begin
            if (ball_is_left) begin
                if (cpu_center_x > 150) begin
                    if (dist_to_ball_x > DEAD_ZONE) begin
                        move_left = 1'b1;
                    end
                end
            end
            else begin
                if (dist_to_ball_x > DEAD_ZONE) begin
                    move_right = 1'b1;
                end
            end
            
            if (ball_is_above && 
                (delayed_ball_y < JUMP_TRIGGER_Y) && 
                ball_coming_toward_cpu &&
                cpu_on_ground &&
                (dist_to_ball_x < JUMP_DISTANCE_X * 2)) begin
                do_jump = 1'b1;
            end
        end
        
        if (ball_in_danger_zone && (delayed_ball_x > cpu_center_x)) begin
            move_right = 1'b1;
            move_left = 1'b0;
            
            if (ball_is_above && (dist_to_ball_x < KICK_DISTANCE_X * 2) && cpu_on_ground) begin
                do_jump = 1'b1;
            end
        end
    end

    assign cpu_keycode = {4'b0000, do_kick, do_jump, move_right, move_left};

endmodule