module color_mapper (
    input  logic vga_clk,
    input  logic [9:0] DrawX, DrawY,
    input  logic blank,
    
    input  logic [9:0] Player1X,
    input  logic [9:0] Player1Y,
    input  logic Player1_Kicking,
    
    input  logic [9:0] Player2X,
    input  logic [9:0] Player2Y,
    input  logic Player2_Kicking,
    
    input  logic [9:0] BallX, BallY, BallS,
    
    input  logic [3:0] P1Score,
    input  logic [3:0] P2Score,
    
    input  logic game_over,
    input  logic p1_wins,
    input  logic show_start_screen, 
    
    output logic [3:0] red, green, blue
);

    logic negedge_vga_clk;
    assign negedge_vga_clk = ~vga_clk;


    parameter [9:0] HEAD_SPRITE_W = 32;
    parameter [9:0] HEAD_SPRITE_W_SCALED = 48;
    parameter [9:0] HEAD_SPRITE_H_SCALED = 63;
    
    parameter [9:0] KICK_SPRITE_W = 42;
    parameter [9:0] KICK_SPRITE_W_SCALED = 63;
    parameter [9:0] KICK_SPRITE_H_SCALED = 63;
    
    parameter [9:0] BALL_SPRITE_W = 32; 
    parameter [9:0] BALL_SPRITE_H = 30; 
    
    parameter [9:0] NUM_SRC_W = 8;
    parameter [9:0] NUM_SRC_H = 16;
    parameter [9:0] NUM_SHEET_W = 80;
    parameter [9:0] NUM_SCALE = 4;
    parameter [9:0] NUM_DST_W = 32;
    parameter [9:0] NUM_DST_H = 64;
    
    parameter [9:0] P1_SCORE_X = 152;
    parameter [9:0] P1_SCORE_Y = 400;
    parameter [9:0] P2_SCORE_X = 456;
    parameter [9:0] P2_SCORE_Y = 400;
    
    parameter [9:0] WINNER_SPRITE_W = 58;
    parameter [9:0] WINNER_SPRITE_H = 36;
    parameter [9:0] WINNER_SCALE = 4;
    parameter [9:0] WINNER_DST_W = 232;
    parameter [9:0] WINNER_DST_H = 144;
    parameter [9:0] WINNER_X = 204;
    parameter [9:0] WINNER_Y = 8;


    logic [14:0] start_rom_address;
    logic [3:0]  start_rom_q;
    logic [3:0]  start_red, start_green, start_blue;

    assign start_rom_address = ((DrawX * 160) / 640) + (((DrawY * 120) / 480) * 160);

    startScreen_rom start_rom_inst (
        .clka   (negedge_vga_clk),
        .addra  (start_rom_address),
        .douta  (start_rom_q)
    );

    startScreen_palette start_palette_inst (
        .index (start_rom_q),
        .red   (start_red),
        .green (start_green),
        .blue  (start_blue)
    );


    logic [14:0] field_rom_address;
    logic [3:0]  field_rom_q;
    logic [3:0]  field_red, field_green, field_blue;

    assign field_rom_address = ((DrawX * 160) / 640) + (((DrawY * 120) / 480) * 160);

    field_rom field_rom_inst (
        .clka   (negedge_vga_clk),
        .addra  (field_rom_address),
        .douta  (field_rom_q)
    );

    field_palette field_palette_inst (
        .index (field_rom_q),
        .red   (field_red),
        .green (field_green),
        .blue  (field_blue)
    );

    logic [10:0] player1_head_rom_address;
    logic [2:0]  player1_head_rom_q;
    logic [3:0]  player1_head_red, player1_head_green, player1_head_blue;
    
    logic [10:0] player1_kick_rom_address;
    logic [2:0]  player1_kick_rom_q;
    logic [3:0]  player1_kick_red, player1_kick_green, player1_kick_blue;
    
    logic player1_on_next;
    logic player1_on;
    logic player1_kicking_reg;

    always_comb begin
        logic [9:0] next_x;
        logic [9:0] p1_dist_x, p1_dist_y;
        logic [9:0] p1_rom_x, p1_rom_y;
        logic [9:0] p1_sprite_w_scaled;
        logic [9:0] p1_sprite_w_src;
        
        next_x = DrawX + 1'b1;
        player1_on_next = 1'b0;
        player1_head_rom_address = 0;
        player1_kick_rom_address = 0;
        
        if (Player1_Kicking) begin
            p1_sprite_w_scaled = KICK_SPRITE_W_SCALED;
            p1_sprite_w_src = KICK_SPRITE_W;
        end
        else begin
            p1_sprite_w_scaled = HEAD_SPRITE_W_SCALED;
            p1_sprite_w_src = HEAD_SPRITE_W;
        end
        
        if (!show_start_screen && !game_over) begin
            if (next_x >= Player1X && next_x < (Player1X + p1_sprite_w_scaled) &&
                DrawY >= Player1Y && DrawY < (Player1Y + HEAD_SPRITE_H_SCALED)) 
            begin
                player1_on_next = 1'b1;
                
                p1_dist_x = next_x - Player1X;
                p1_dist_y = DrawY - Player1Y;
                
                p1_rom_x = (p1_dist_x * 2) / 3;
                p1_rom_y = (p1_dist_y * 2) / 3;
                
                player1_head_rom_address = (p1_rom_y * HEAD_SPRITE_W) + p1_rom_x;
                player1_kick_rom_address = (p1_rom_y * KICK_SPRITE_W) + p1_rom_x;
            end
        end
    end
    
    always_ff @(posedge vga_clk) begin
        player1_on <= player1_on_next;
        player1_kicking_reg <= Player1_Kicking;
    end

    zuofuHead_rom player1_head_rom_inst (
        .clka   (negedge_vga_clk),
        .addra  (player1_head_rom_address),
        .douta  (player1_head_rom_q)
    );

    zuofuHead_palette player1_head_palette_inst (
        .index (player1_head_rom_q),
        .red   (player1_head_red),
        .green (player1_head_green),
        .blue  (player1_head_blue)
    );
    
    zuofuKick_rom player1_kick_rom_inst (
        .clka   (negedge_vga_clk),
        .addra  (player1_kick_rom_address),
        .douta  (player1_kick_rom_q)
    );

    zuofuKick_palette player1_kick_palette_inst (
        .index (player1_kick_rom_q),
        .red   (player1_kick_red),
        .green (player1_kick_green),
        .blue  (player1_kick_blue)
    );
    
    logic [3:0] player1_red, player1_green, player1_blue;
    always_comb begin
        if (player1_kicking_reg) begin
            player1_red   = player1_kick_red;
            player1_green = player1_kick_green;
            player1_blue  = player1_kick_blue;
        end
        else begin
            player1_red   = player1_head_red;
            player1_green = player1_head_green;
            player1_blue  = player1_head_blue;
        end
    end


    logic [10:0] player2_head_rom_address;
    logic [2:0]  player2_head_rom_q;
    logic [3:0]  player2_head_red, player2_head_green, player2_head_blue;
    
    logic [10:0] player2_kick_rom_address;
    logic [2:0]  player2_kick_rom_q;
    logic [3:0]  player2_kick_red, player2_kick_green, player2_kick_blue;

    logic player2_on_next;
    logic player2_on;
    logic player2_kicking_reg;

    always_comb begin
        logic [9:0] next_x;
        logic [9:0] p2_dist_x, p2_dist_y;
        logic [9:0] p2_rom_x, p2_rom_y;
        logic [9:0] p2_sprite_w_scaled;
        logic [9:0] p2_sprite_w_src;
        
        next_x = DrawX + 1'b1;
        player2_on_next = 1'b0;
        player2_head_rom_address = 0;
        player2_kick_rom_address = 0;
        
        if (Player2_Kicking) begin
            p2_sprite_w_scaled = KICK_SPRITE_W_SCALED;
            p2_sprite_w_src = KICK_SPRITE_W;
        end
        else begin
            p2_sprite_w_scaled = HEAD_SPRITE_W_SCALED;
            p2_sprite_w_src = HEAD_SPRITE_W;
        end
        
        if (!show_start_screen && !game_over) begin
            if (next_x >= Player2X && next_x < (Player2X + p2_sprite_w_scaled) &&
                DrawY >= Player2Y && DrawY < (Player2Y + HEAD_SPRITE_H_SCALED)) 
            begin
                player2_on_next = 1'b1;
                
                p2_dist_x = next_x - Player2X;
                p2_dist_y = DrawY - Player2Y;
                
                p2_rom_x = (p2_dist_x * 2) / 3;
                p2_rom_y = (p2_dist_y * 2) / 3;
                
                player2_head_rom_address = (p2_rom_y * HEAD_SPRITE_W) + p2_rom_x;
                player2_kick_rom_address = (p2_rom_y * KICK_SPRITE_W) + p2_rom_x;
            end
        end
    end
    
    always_ff @(posedge vga_clk) begin
        player2_on <= player2_on_next;
        player2_kicking_reg <= Player2_Kicking;
    end

    evilZuofuHead_rom player2_head_rom_inst (
        .clka   (negedge_vga_clk),
        .addra  (player2_head_rom_address),
        .douta  (player2_head_rom_q)
    );

    evilZuofuHead_palette player2_head_palette_inst (
        .index (player2_head_rom_q),
        .red   (player2_head_red),
        .green (player2_head_green),
        .blue  (player2_head_blue)
    );
    
    evilZuofuKick_rom player2_kick_rom_inst (
        .clka   (negedge_vga_clk),
        .addra  (player2_kick_rom_address),
        .douta  (player2_kick_rom_q)
    );

    evilZuofuKick_palette player2_kick_palette_inst (
        .index (player2_kick_rom_q),
        .red   (player2_kick_red),
        .green (player2_kick_green),
        .blue  (player2_kick_blue)
    );
    
    logic [3:0] player2_red, player2_green, player2_blue;
    always_comb begin
        if (player2_kicking_reg) begin
            player2_red   = player2_kick_red;
            player2_green = player2_kick_green;
            player2_blue  = player2_kick_blue;
        end
        else begin
            player2_red   = player2_head_red;
            player2_green = player2_head_green;
            player2_blue  = player2_head_blue;
        end
    end


    logic [9:0] ball_rom_address;
    logic [2:0] ball_rom_q;
    logic [3:0] ball_red, ball_green, ball_blue;
    
    logic ball_on_next;
    logic ball_on;
    
    always_comb begin
        logic [9:0] next_x;
        logic [9:0] ball_draw_start_x;
        logic [9:0] ball_draw_start_y;
        logic [9:0] ball_rom_x, ball_rom_y;
        
        next_x = DrawX + 1'b1;
        ball_draw_start_x = BallX - (BALL_SPRITE_W / 2);
        ball_draw_start_y = BallY - (BALL_SPRITE_H / 2);
        
        ball_on_next = 1'b0;
        ball_rom_address = 0;

        if (!show_start_screen && !game_over) begin
            if (next_x >= ball_draw_start_x && next_x < (ball_draw_start_x + BALL_SPRITE_W) &&
                DrawY >= ball_draw_start_y && DrawY < (ball_draw_start_y + BALL_SPRITE_H)) 
            begin
                ball_on_next = 1'b1;
                
                ball_rom_x = next_x - ball_draw_start_x;
                ball_rom_y = DrawY - ball_draw_start_y;
                
                ball_rom_address = (ball_rom_y * BALL_SPRITE_W) + ball_rom_x;
            end
        end
    end
    
    always_ff @(posedge vga_clk) begin
        ball_on <= ball_on_next;
    end
    
    ball_rom ball_rom_inst (
        .clka   (negedge_vga_clk),
        .addra  (ball_rom_address),
        .douta  (ball_rom_q)
    );

    ball_palette ball_palette_inst (
        .index (ball_rom_q),
        .red   (ball_red),
        .green (ball_green),
        .blue  (ball_blue)
    );


    logic [10:0] numbers_rom_address;
    logic [2:0]  numbers_rom_q;
    logic [3:0]  numbers_red, numbers_green, numbers_blue;
    
    logic p1_score_on_next, p2_score_on_next;
    logic p1_score_on, p2_score_on;
    
    always_comb begin
        logic [9:0] next_x;
        logic [9:0] score_src_x, score_src_y;
        logic [3:0] current_digit;
        
        next_x = DrawX + 1'b1;
        
        p1_score_on_next = 1'b0;
        p2_score_on_next = 1'b0;
        numbers_rom_address = 0;
        current_digit = 0;
        score_src_x = 0;
        score_src_y = 0;
        
        if (!show_start_screen) begin
            if (next_x >= P1_SCORE_X && next_x < (P1_SCORE_X + NUM_DST_W) &&
                DrawY >= P1_SCORE_Y && DrawY < (P1_SCORE_Y + NUM_DST_H)) 
            begin
                p1_score_on_next = 1'b1;
                current_digit = P1Score;
                
                score_src_x = (next_x - P1_SCORE_X) / NUM_SCALE;
                score_src_y = (DrawY - P1_SCORE_Y) / NUM_SCALE;
                
                numbers_rom_address = (score_src_y * NUM_SHEET_W) + (current_digit * NUM_SRC_W) + score_src_x;
            end
            else if (next_x >= P2_SCORE_X && next_x < (P2_SCORE_X + NUM_DST_W) &&
                     DrawY >= P2_SCORE_Y && DrawY < (P2_SCORE_Y + NUM_DST_H)) 
            begin
                p2_score_on_next = 1'b1;
                current_digit = P2Score;
                
                score_src_x = (next_x - P2_SCORE_X) / NUM_SCALE;
                score_src_y = (DrawY - P2_SCORE_Y) / NUM_SCALE;
                
                numbers_rom_address = (score_src_y * NUM_SHEET_W) + (current_digit * NUM_SRC_W) + score_src_x;
            end
        end
    end
    
    always_ff @(posedge vga_clk) begin
        p1_score_on <= p1_score_on_next;
        p2_score_on <= p2_score_on_next;
    end
    
    numbers_rom numbers_rom_inst (
        .clka   (negedge_vga_clk),
        .addra  (numbers_rom_address),
        .douta  (numbers_rom_q)
    );
    
    numbers_palette numbers_palette_inst (
        .index (numbers_rom_q),
        .red   (numbers_red),
        .green (numbers_green),
        .blue  (numbers_blue)
    );


    logic [11:0] p1wins_rom_address;
    logic [2:0]  p1wins_rom_q;
    logic [3:0]  p1wins_red, p1wins_green, p1wins_blue;
    
    logic [11:0] p2wins_rom_address;
    logic [2:0]  p2wins_rom_q;
    logic [3:0]  p2wins_red, p2wins_green, p2wins_blue;
    
    logic winner_on_next;
    logic winner_on;
    
    always_comb begin
        logic [9:0] next_x;
        logic [9:0] win_dist_x, win_dist_y;
        logic [9:0] win_src_x, win_src_y;
        
        next_x = DrawX + 1'b1;
        
        winner_on_next = 1'b0;
        p1wins_rom_address = 0;
        p2wins_rom_address = 0;
        
        if (game_over && !show_start_screen) begin
            if (next_x >= WINNER_X && next_x < (WINNER_X + WINNER_DST_W) &&
                DrawY >= WINNER_Y && DrawY < (WINNER_Y + WINNER_DST_H)) 
            begin
                winner_on_next = 1'b1;
                
                win_dist_x = next_x - WINNER_X;
                win_dist_y = DrawY - WINNER_Y;
                
                win_src_x = win_dist_x / WINNER_SCALE;
                win_src_y = win_dist_y / WINNER_SCALE;
                
                p1wins_rom_address = (win_src_y * WINNER_SPRITE_W) + win_src_x;
                p2wins_rom_address = (win_src_y * WINNER_SPRITE_W) + win_src_x;
            end
        end
    end
    
    always_ff @(posedge vga_clk) begin
        winner_on <= winner_on_next;
    end
    
    playeronewins_rom p1wins_rom_inst (
        .clka   (negedge_vga_clk),
        .addra  (p1wins_rom_address),
        .douta  (p1wins_rom_q)
    );
    
    playeronewins_palette p1wins_palette_inst (
        .index (p1wins_rom_q),
        .red   (p1wins_red),
        .green (p1wins_green),
        .blue  (p1wins_blue)
    );
    
    playertwowins_rom p2wins_rom_inst (
        .clka   (negedge_vga_clk),
        .addra  (p2wins_rom_address),
        .douta  (p2wins_rom_q)
    );
    
    playertwowins_palette p2wins_palette_inst (
        .index (p2wins_rom_q),
        .red   (p2wins_red),
        .green (p2wins_green),
        .blue  (p2wins_blue)
    );
    
    logic [3:0] winner_red, winner_green, winner_blue;
    always_comb begin
        if (p1_wins) begin
            winner_red   = p1wins_red;
            winner_green = p1wins_green;
            winner_blue  = p1wins_blue;
        end
        else begin
            winner_red   = p2wins_red;
            winner_green = p2wins_green;
            winner_blue  = p2wins_blue;
        end
    end


    logic show_start_screen_reg;
    always_ff @(posedge vga_clk) begin
        show_start_screen_reg <= show_start_screen;
    end
    
    always_ff @(posedge vga_clk) begin
        red   <= 4'h0;
        green <= 4'h0;
        blue  <= 4'h0;

        if (blank) begin

            if (show_start_screen_reg) begin
                red   <= start_red;
                green <= start_green;
                blue  <= start_blue;
            end

            else begin
                red   <= field_red;
                green <= field_green;
                blue  <= field_blue;

                if (player1_on) begin
                    if (!((player1_red == 4'hF) && (player1_green == 4'h0) && (player1_blue == 4'hF))) begin
                        red   <= player1_red;
                        green <= player1_green;
                        blue  <= player1_blue;
                    end
                end
                
                if (player2_on) begin
                    if (!((player2_red == 4'hF) && (player2_green == 4'h0) && (player2_blue == 4'hF))) begin
                        red   <= player2_red;
                        green <= player2_green;
                        blue  <= player2_blue;
                    end
                end
                
                if (ball_on) begin
                    if (!((ball_red == 4'hF) && (ball_green == 4'h0) && (ball_blue == 4'hF))) begin
                        red   <= ball_red;
                        green <= ball_green;
                        blue  <= ball_blue;
                    end
                end
                
                if (p1_score_on || p2_score_on) begin
                    if (!((numbers_red == 4'hF) && (numbers_green == 4'h0) && (numbers_blue == 4'hF))) begin
                        red   <= numbers_red;
                        green <= numbers_green;
                        blue  <= numbers_blue;
                    end
                end
                
                if (winner_on) begin
                    if (!((winner_red == 4'hF) && (winner_green == 4'h0) && (winner_blue == 4'hF))) begin
                        red   <= winner_red;
                        green <= winner_green;
                        blue  <= winner_blue;
                    end
                end
            end
        end
    end

endmodule