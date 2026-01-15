module ball_collision (
    input  logic        frame_clk,
    
    // Player 1
    input  logic [9:0]  p1_x, p1_y, 
    input  logic [9:0]  p1_w, p1_h,
    input  logic signed [9:0] p1_vel_x, p1_vel_y,
    input  logic        p1_is_kicking,
    
    // Player 2 
    input  logic [9:0]  p2_x, p2_y, 
    input  logic [9:0]  p2_w, p2_h,
    input  logic signed [9:0] p2_vel_x, p2_vel_y,
    input  logic        p2_is_kicking,
    
    // Ball
    input  logic [9:0]  ball_x, ball_y, ball_r,
    input  logic signed [9:0] ball_vel_x, ball_vel_y,
    
    output logic        force_out, 
    output logic signed [9:0] force_x_out, 
    output logic signed [9:0] force_y_out
);

    parameter signed [9:0] KICK_TARGET_VEL_X = 10;
    parameter signed [9:0] KICK_TARGET_VEL_Y = -14;
    
    logic [9:0] p1_center_x, p1_center_y;
    assign p1_center_x = p1_x + (p1_w >> 1);
    assign p1_center_y = p1_y + (p1_h >> 1);
    
    logic p1_collision;
    assign p1_collision = 
        (ball_x + ball_r > p1_x) &&           
        (ball_x < p1_x + p1_w + ball_r) &&    
        (ball_y + ball_r > p1_y) &&           
        (ball_y < p1_y + p1_h + ball_r);
    
    logic p1_collision_prev;
    always_ff @(posedge frame_clk) begin
        p1_collision_prev <= p1_collision;
    end
    logic p1_new_collision;
    assign p1_new_collision = p1_collision && !p1_collision_prev;
    
    logic p1_kick_prev;
    always_ff @(posedge frame_clk) begin
        p1_kick_prev <= p1_is_kicking;
    end
    logic p1_kick_start;
    assign p1_kick_start = p1_is_kicking && !p1_kick_prev;
    
    logic p1_trigger_force;
    assign p1_trigger_force = p1_new_collision || (p1_kick_start && p1_collision);
    
    logic p1_hit_from_left, p1_hit_from_right, p1_hit_from_top, p1_hit_from_bottom;
    always_comb begin
        p1_hit_from_left = 1'b0;
        p1_hit_from_right = 1'b0;
        p1_hit_from_top = 1'b0;
        p1_hit_from_bottom = 1'b0;
        
        if (p1_collision) begin
            if (ball_x < p1_center_x && ball_vel_x > 0)
                p1_hit_from_left = 1'b1;
            else if (ball_x >= p1_center_x && ball_vel_x < 0)
                p1_hit_from_right = 1'b1;
            else if (ball_y < p1_center_y)
                p1_hit_from_top = 1'b1;
            else
                p1_hit_from_bottom = 1'b1;
        end
    end
    
    logic signed [9:0] p1_force_x, p1_force_y;
    always_comb begin
        p1_force_x = 0;
        p1_force_y = 0;
        
        if (p1_trigger_force) begin
            if (p1_is_kicking) begin
                p1_force_x = KICK_TARGET_VEL_X - ball_vel_x + p1_vel_x; 
                p1_force_y = KICK_TARGET_VEL_Y - ball_vel_y; 
            end
            else begin
                if (p1_hit_from_left || p1_hit_from_right) begin
                    p1_force_x = (-2 * ball_vel_x) + (p1_vel_x * 2);
                end
                else begin
                    p1_force_x = p1_vel_x * 2;
                end
                
                if (p1_hit_from_top || p1_hit_from_bottom) begin
                    p1_force_y = (-2 * ball_vel_y) + p1_vel_y;
                end
                else begin
                    if (p1_vel_y < 0)
                        p1_force_y = p1_vel_y - 5; 
                    else
                        p1_force_y = -6; 
                end
            end
        end
    end


    logic [9:0] p2_center_x, p2_center_y;
    assign p2_center_x = p2_x + (p2_w >> 1);
    assign p2_center_y = p2_y + (p2_h >> 1);
    
    logic p2_collision;
    assign p2_collision = 
        (ball_x + ball_r > p2_x) &&           
        (ball_x < p2_x + p2_w + ball_r) &&    
        (ball_y + ball_r > p2_y) &&           
        (ball_y < p2_y + p2_h + ball_r);
    
    logic p2_collision_prev;
    always_ff @(posedge frame_clk) begin
        p2_collision_prev <= p2_collision;
    end
    logic p2_new_collision;
    assign p2_new_collision = p2_collision && !p2_collision_prev;
    
    logic p2_kick_prev;
    always_ff @(posedge frame_clk) begin
        p2_kick_prev <= p2_is_kicking;
    end
    logic p2_kick_start;
    assign p2_kick_start = p2_is_kicking && !p2_kick_prev;
    
    logic p2_trigger_force;
    assign p2_trigger_force = p2_new_collision || (p2_kick_start && p2_collision);
    
    logic p2_hit_from_left, p2_hit_from_right, p2_hit_from_top, p2_hit_from_bottom;
    always_comb begin
        p2_hit_from_left = 1'b0;
        p2_hit_from_right = 1'b0;
        p2_hit_from_top = 1'b0;
        p2_hit_from_bottom = 1'b0;
        
        if (p2_collision) begin
            if (ball_x < p2_center_x && ball_vel_x > 0)
                p2_hit_from_left = 1'b1;
            else if (ball_x >= p2_center_x && ball_vel_x < 0)
                p2_hit_from_right = 1'b1;
            else if (ball_y < p2_center_y)
                p2_hit_from_top = 1'b1;
            else
                p2_hit_from_bottom = 1'b1;
        end
    end
    
    logic signed [9:0] p2_force_x, p2_force_y;
    always_comb begin
        p2_force_x = 0;
        p2_force_y = 0;
        
        if (p2_trigger_force) begin
            if (p2_is_kicking) begin
                p2_force_x = -KICK_TARGET_VEL_X - ball_vel_x + p2_vel_x;
                p2_force_y = KICK_TARGET_VEL_Y - ball_vel_y;         
            end
            else begin
                if (p2_hit_from_left || p2_hit_from_right) begin
                    p2_force_x = (-2 * ball_vel_x) + (p2_vel_x * 2);
                end
                else begin
                    p2_force_x = p2_vel_x * 2;
                end
                
                if (p2_hit_from_top || p2_hit_from_bottom) begin
                    p2_force_y = (-2 * ball_vel_y) + p2_vel_y;
                end
                else begin
                    if (p2_vel_y < 0)
                        p2_force_y = p2_vel_y - 5;
                    else
                        p2_force_y = -6;
                end
            end
        end
    end

    always_comb begin
        force_out = p1_trigger_force || p2_trigger_force;
        
        if (p1_trigger_force && p2_trigger_force) begin
            force_x_out = p1_force_x + p2_force_x;
            force_y_out = p1_force_y + p2_force_y;
        end
        else if (p1_trigger_force) begin
            force_x_out = p1_force_x;
            force_y_out = p1_force_y;
        end
        else if (p2_trigger_force) begin
            force_x_out = p2_force_x;
            force_y_out = p2_force_y;
        end
        else begin
            force_x_out = 0;
            force_y_out = 0;
        end
    end

endmodule