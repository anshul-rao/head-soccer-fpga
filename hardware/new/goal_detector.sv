module goal_detector (
    input  logic        frame_clk,
    input  logic        Reset,
    
    input  logic [9:0]  ball_x,
    input  logic [9:0]  ball_y,
    input  logic [9:0]  ball_r,
    
    input  logic        game_restart,
    
    output logic        goal_scored,
    output logic        left_goal,       
    
    output logic [3:0]  p1_score,
    output logic [3:0]  p2_score,     
    
    output logic        game_over,        
    output logic        p1_wins           
);

    parameter [9:0] LEFT_GOAL_X   = 32;    
    parameter [9:0] RIGHT_GOAL_X  = 604;
    parameter [9:0] GOAL_Y_TOP    = 176; 
    parameter [9:0] GOAL_Y_BOTTOM = 316; 
    
    parameter [3:0] WIN_SCORE = 4'd5;

    logic goal_detected;
    logic goal_detected_prev;
    logic is_left_goal;
    
    logic [3:0] score_p1, score_p2;
    
    logic game_over_reg;
    logic p1_wins_reg;
    
    always_comb begin
        goal_detected = 1'b0;
        is_left_goal = 1'b0;
        
        if (!game_over_reg) begin
            if ((ball_y >= GOAL_Y_TOP) && (ball_y <= GOAL_Y_BOTTOM)) begin
                if ((ball_x - ball_r) <= LEFT_GOAL_X) begin
                    goal_detected = 1'b1;
                    is_left_goal = 1'b1; 
                end
                else if ((ball_x + ball_r) >= RIGHT_GOAL_X) begin
                    goal_detected = 1'b1;
                    is_left_goal = 1'b0;
                end
            end
        end
    end
    
    always_ff @(posedge frame_clk or posedge Reset) begin
        if (Reset) begin
            goal_detected_prev <= 1'b0;
            goal_scored <= 1'b0;
            left_goal <= 1'b0;
            score_p1 <= 4'd0;
            score_p2 <= 4'd0;
            game_over_reg <= 1'b0;
            p1_wins_reg <= 1'b0;
        end
        else if (game_restart) begin
            goal_detected_prev <= 1'b0;
            goal_scored <= 1'b0;
            left_goal <= 1'b0;
            score_p1 <= 4'd0;
            score_p2 <= 4'd0;
            game_over_reg <= 1'b0;
            p1_wins_reg <= 1'b0;
        end
        else begin
            goal_detected_prev <= goal_detected;
            
            if (goal_detected && !goal_detected_prev && !game_over_reg) begin
                goal_scored <= 1'b1;
                left_goal <= is_left_goal;
                
                if (is_left_goal) begin
                    if (score_p2 < 4'd9) begin
                        score_p2 <= score_p2 + 1'b1;
                        
                        if (score_p2 + 1'b1 >= WIN_SCORE) begin
                            game_over_reg <= 1'b1;
                            p1_wins_reg <= 1'b0; 
                        end
                    end
                end
                else begin
                    if (score_p1 < 4'd9) begin
                        score_p1 <= score_p1 + 1'b1;
                        
                        if (score_p1 + 1'b1 >= WIN_SCORE) begin
                            game_over_reg <= 1'b1;
                            p1_wins_reg <= 1'b1;  
                        end
                    end
                end
            end
            else begin
                goal_scored <= 1'b0;  
            end
        end
    end
    
    assign p1_score = score_p1;
    assign p2_score = score_p2;
    assign game_over = game_over_reg;
    assign p1_wins = p1_wins_reg;

endmodule