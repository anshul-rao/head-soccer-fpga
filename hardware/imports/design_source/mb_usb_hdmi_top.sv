module mb_usb_hdmi_top(
    input logic Clk,
    input logic reset_rtl_0,
    
    input logic [0:0] gpio_usb_int_tri_i,
    output logic gpio_usb_rst_tri_o,
    input logic usb_spi_miso,
    output logic usb_spi_mosi,
    output logic usb_spi_sclk,
    output logic usb_spi_ss,
    
    input logic uart_rtl_0_rxd,
    output logic uart_rtl_0_txd,
    
    output logic hdmi_tmds_clk_n,
    output logic hdmi_tmds_clk_p,
    output logic [2:0]hdmi_tmds_data_n,
    output logic [2:0]hdmi_tmds_data_p,

    output logic [7:0] hex_segA,
    output logic [3:0] hex_gridA,
    output logic [7:0] hex_segB,
    output logic [3:0] hex_gridB
);
    
    logic [31:0] keycode0_gpio, keycode1_gpio;
    logic clk_25MHz, clk_125MHz, clk, clk_100MHz;
    logic locked;
    logic [9:0] drawX, drawY;

    logic hsync, vsync, vde;
    logic [3:0] red, green, blue;
    logic reset_ah;

    logic [9:0] player1_x, player1_y;
    logic signed [9:0] player1_vel_x, player1_vel_y;
    logic player1_is_kicking;
    logic [9:0] player1_width;

    logic [9:0] player2_x, player2_y;
    logic signed [9:0] player2_vel_x, player2_vel_y;
    logic player2_is_kicking;
    logic [9:0] player2_width;
    
    logic [9:0] ball_x, ball_y, ball_s;
    logic signed [9:0] ball_vel_x, ball_vel_y;
    logic force_sig;
    logic signed [9:0] force_x_val, force_y_val;

    logic goal_scored;
    logic left_goal;
    logic [3:0] p1_score, p2_score;
    
    logic game_over;
    logic p1_wins;
    logic game_restart;
    logic return_to_menu;
    
    logic cpu_mode;
    logic [7:0] cpu_keycode;
    
    typedef enum logic [1:0] {
        STATE_START_SCREEN = 2'b00,
        STATE_GAMEPLAY     = 2'b01,
        STATE_GAME_OVER    = 2'b10
    } game_state_t;
    
    game_state_t game_state, game_state_next;
    
    logic key1_prev, key2_prev, r_key_prev;
    logic key1_pressed, key2_pressed, r_key_pressed;
    
    assign reset_ah = reset_rtl_0;
    
    assign hex_segA = 8'hFF;
    assign hex_gridA = 4'hF;
    assign hex_segB = 8'hFF;
    assign hex_gridB = 4'hF;
    
    always_ff @(posedge vsync or posedge reset_ah) begin
        if (reset_ah) begin
            game_state <= STATE_START_SCREEN;
            key1_prev <= 1'b0;
            key2_prev <= 1'b0;
            r_key_prev <= 1'b0;
            cpu_mode <= 1'b0;
        end
        else begin
            game_state <= game_state_next;
            key1_prev <= keycode1_gpio[5];
            key2_prev <= keycode1_gpio[6];
            r_key_prev <= keycode1_gpio[4];
            
            if (game_state == STATE_START_SCREEN) begin
                if (key1_pressed) begin
                    cpu_mode <= 1'b0;
                end
                else if (key2_pressed) begin
                    cpu_mode <= 1'b1;
                end
            end
            else if (return_to_menu) begin
                cpu_mode <= 1'b0;
            end
        end
    end
    
    assign key1_pressed = keycode1_gpio[5] && !key1_prev;
    assign key2_pressed = keycode1_gpio[6] && !key2_prev;
    assign r_key_pressed = keycode1_gpio[4] && !r_key_prev;
    
    always_comb begin
        game_state_next = game_state;
        game_restart = 1'b0;
        return_to_menu = 1'b0;
        
        case (game_state)
            STATE_START_SCREEN: begin
                if (key1_pressed) begin
                    game_state_next = STATE_GAMEPLAY;
                    game_restart = 1'b1;
                end
                else if (key2_pressed) begin
                    game_state_next = STATE_GAMEPLAY;
                    game_restart = 1'b1;
                end
            end
            
            STATE_GAMEPLAY: begin
                if (game_over) begin
                    game_state_next = STATE_GAME_OVER;
                end
            end
            
            STATE_GAME_OVER: begin
                if (r_key_pressed) begin
                    game_state_next = STATE_START_SCREEN;
                    return_to_menu = 1'b1;
                end
            end
            
            default: begin
                game_state_next = STATE_START_SCREEN;
            end
        endcase
    end
    
    logic show_start_screen;
    logic show_gameplay;
    logic show_game_over;
    
    assign show_start_screen = (game_state == STATE_START_SCREEN);
    assign show_gameplay = (game_state == STATE_GAMEPLAY);
    assign show_game_over = (game_state == STATE_GAME_OVER);
    
    logic full_reset;
    assign full_reset = goal_scored || game_restart || return_to_menu;
    
    logic [7:0] p1_keycode_gated;
    assign p1_keycode_gated = show_gameplay ? keycode0_gpio[7:0] : 8'h00;
    
    logic [7:0] p2_keycode_muxed;
    logic [7:0] p2_keycode_gated;
    
    assign p2_keycode_muxed = cpu_mode ? cpu_keycode : keycode1_gpio[7:0];
    
    assign p2_keycode_gated = show_gameplay ? p2_keycode_muxed : 8'h00;
    
    cpu_player cpu_inst (
        .Reset(reset_ah),
        .frame_clk(vsync),
        
        .ball_x(ball_x),
        .ball_y(ball_y),
        .ball_vel_x(ball_vel_x),
        .ball_vel_y(ball_vel_y),
        
        .cpu_x(player2_x),
        .cpu_y(player2_y),
        
        .player_x(player1_x),
        .player_y(player1_y),        

        .cpu_keycode(cpu_keycode)
    );
    
    mb_block mb_block_i (
        .clk_100MHz(Clk),
        .gpio_usb_int_tri_i(gpio_usb_int_tri_i),
        .gpio_usb_keycode_0_tri_o(keycode0_gpio),
        .gpio_usb_keycode_1_tri_o(keycode1_gpio),
        .gpio_usb_rst_tri_o(gpio_usb_rst_tri_o),
        .reset_rtl_0(~reset_ah),
        .uart_rtl_0_rxd(uart_rtl_0_rxd),
        .uart_rtl_0_txd(uart_rtl_0_txd),
        .usb_spi_miso(usb_spi_miso),
        .usb_spi_mosi(usb_spi_mosi),
        .usb_spi_sclk(usb_spi_sclk),
        .usb_spi_ss(usb_spi_ss)
    );
        
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .reset(reset_ah),
        .locked(locked),
        .clk_in1(Clk)
    );
    
    vga_controller vga (
        .pixel_clk(clk_25MHz),
        .reset(reset_ah),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );    

    hdmi_tx_0 vga_to_hdmi (
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        .rst(reset_ah),
        .red(red),
        .green(green),
        .blue(blue),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),
        
        .TMDS_CLK_P(hdmi_tmds_clk_p),          
        .TMDS_CLK_N(hdmi_tmds_clk_n),          
        .TMDS_DATA_P(hdmi_tmds_data_p),         
        .TMDS_DATA_N(hdmi_tmds_data_n)          
    );
    
    color_mapper color_instance(
        .vga_clk(clk_25MHz),
        .DrawX(drawX),
        .DrawY(drawY),
        .blank(vde),
        .Player1X(player1_x),
        .Player1Y(player1_y),
        .Player1_Kicking(player1_is_kicking),
        .Player2X(player2_x),
        .Player2Y(player2_y),
        .Player2_Kicking(player2_is_kicking),
        .BallX(ball_x),
        .BallY(ball_y),
        .BallS(ball_s),
        .P1Score(p1_score),
        .P2Score(p2_score),
        .game_over(show_game_over),
        .p1_wins(p1_wins),
        .show_start_screen(show_start_screen),
        .red(red),
        .green(green),
        .blue(blue)
    );
    
    player #(
        .INIT_X(150),
        .INIT_Y(257)
    ) player_1 (
        .Reset(reset_ah),
        .frame_clk(vsync),
        .keycode(p1_keycode_gated),
        .goal_reset(full_reset),
        .OtherPlayerX(player2_x),
        .OtherPlayerY(player2_y),
        .PlayerX(player1_x),
        .PlayerY(player1_y),
        .PlayerVelX(player1_vel_x),
        .PlayerVelY(player1_vel_y),
        .is_kicking(player1_is_kicking),
        .PlayerWidth(player1_width)
    );
    
    player #(
        .INIT_X(440),
        .INIT_Y(257)
    ) player_2 (
        .Reset(reset_ah),
        .frame_clk(vsync),
        .keycode(p2_keycode_gated),
        .goal_reset(full_reset),
        .OtherPlayerX(player1_x),
        .OtherPlayerY(player1_y),
        .PlayerX(player2_x),
        .PlayerY(player2_y),
        .PlayerVelX(player2_vel_x),
        .PlayerVelY(player2_vel_y),
        .is_kicking(player2_is_kicking),
        .PlayerWidth(player2_width)
    );
    
    ball ball_inst (
        .Reset(reset_ah),
        .frame_clk(vsync),
        .apply_force(force_sig && show_gameplay),
        .force_x(force_x_val),
        .force_y(force_y_val),
        .goal_reset(full_reset),
        .BallX(ball_x),
        .BallY(ball_y),
        .BallS(ball_s),
        .BallVelX(ball_vel_x),
        .BallVelY(ball_vel_y)
    );
    
    ball_collision collision_inst (
        .frame_clk(vsync),
        .p1_x(player1_x), 
        .p1_y(player1_y), 
        .p1_w(player1_width),
        .p1_h(63),
        .p1_vel_x(player1_vel_x),
        .p1_vel_y(player1_vel_y),
        .p1_is_kicking(player1_is_kicking),
        .p2_x(player2_x), 
        .p2_y(player2_y), 
        .p2_w(player2_width),
        .p2_h(63),
        .p2_vel_x(player2_vel_x),
        .p2_vel_y(player2_vel_y),
        .p2_is_kicking(player2_is_kicking),
        .ball_x(ball_x), 
        .ball_y(ball_y), 
        .ball_r(ball_s),
        .ball_vel_x(ball_vel_x),
        .ball_vel_y(ball_vel_y),
        .force_out(force_sig), 
        .force_x_out(force_x_val), 
        .force_y_out(force_y_val)
    );
    
    goal_detector goal_inst (
        .frame_clk(vsync),
        .Reset(reset_ah),
        .ball_x(ball_x),
        .ball_y(ball_y),
        .ball_r(ball_s),
        .game_restart(game_restart || return_to_menu),
        .goal_scored(goal_scored),
        .left_goal(left_goal),
        .p1_score(p1_score),
        .p2_score(p2_score),
        .game_over(game_over),
        .p1_wins(p1_wins)
    );
    
endmodule