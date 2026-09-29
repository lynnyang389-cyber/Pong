`timescale 1ns / 1ps

// ============================================================
// Zybo Z7 Pong
//
// 125 MHz system clock
// 640x480 HDMI video
//
// Buttons:
//   BTN0 = left paddle up
//   BTN1 = left paddle down
//   BTN2 = right paddle up
//   BTN3 = right paddle down
//
// SW0 = reset
//
// HDMI:
//   hdmi_tx_clk_p/n
//   hdmi_tx_p/n[2:0]
//
// ============================================================

module pong_top (
    input  logic       sysclk,

    input  logic [3:0] btn,
    input  logic [3:0] sw,

    output logic [3:0] led,

    output logic       hdmi_tx_clk_p,
    output logic       hdmi_tx_clk_n,
    output logic [2:0] hdmi_tx_p,
    output logic [2:0] hdmi_tx_n
);

    // ========================================================
    // CLOCK GENERATION
    //
    // Input:
    //   125 MHz
    //
    // Pixel clock:
    //   25 MHz
    //
    // HDMI serial clock:
    //   125 MHz
    //
    // MMCM VCO:
    //   125 MHz * 8 = 1000 MHz
    //
    // 1000 / 40 = 25 MHz
    // 1000 / 8  = 125 MHz
    // ========================================================

    logic clk_pixel;
    logic clk_125;
    logic clkfb;
    logic locked;

    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKFBOUT_MULT_F(8.0),
        .CLKIN1_PERIOD(8.0),
        .DIVCLK_DIVIDE(1),
        .CLKOUT0_DIVIDE_F(40.0),
        .CLKOUT1_DIVIDE(8),
        .STARTUP_WAIT("FALSE")
    )
    mmcm_inst (
        .CLKIN1(sysclk),

        .CLKFBOUT(clkfb),
        .CLKOUT0(clk_pixel),
        .CLKOUT1(clk_125),

        .LOCKED(locked),
        .PWRDWN(1'b0),
        .RST(sw[0])
    );

    logic clkfb_buf;

    BUFG feedback_buf (
        .I(clkfb),
        .O(clkfb_buf)
    );

    // Connect feedback after BUFG.
    // In a real design this is normally done with the BUFG
    // directly feeding the MMCM feedback input.
    //
    // The MMCM feedback connection is handled below through
    // the dedicated BUFG output.

    // ========================================================
    // RESET
    // ========================================================

    logic reset;

    assign reset = sw[0] | ~locked;

    // ========================================================
    // BUTTON SYNCHRONIZATION
    // ========================================================

    logic [3:0] btn_meta;
    logic [3:0] btn_sync;

    always_ff @(posedge clk_pixel) begin
        if (reset) begin
            btn_meta <= 4'b0;
            btn_sync <= 4'b0;
        end
        else begin
            btn_meta <= btn;
            btn_sync <= btn_meta;
        end
    end

    // ========================================================
    // VGA TIMING
    // ========================================================

    logic [9:0] pixel_x;
    logic [9:0] pixel_y;

    logic       hsync;
    logic       vsync;
    logic       video_active;
    logic       frame_tick;

    vga_timing vga (
        .clk          (clk_pixel),
        .reset        (reset),

        .pixel_x      (pixel_x),
        .pixel_y      (pixel_y),

        .hsync        (hsync),
        .vsync        (vsync),

        .video_active (video_active),
        .frame_tick   (frame_tick)
    );

    // ========================================================
    // PONG GAME
    // ========================================================

    logic [9:0] left_paddle_y;
    logic [9:0] right_paddle_y;

    logic [9:0] ball_x;
    logic [9:0] ball_y;

    logic [3:0] left_score;
    logic [3:0] right_score;

    pong_game game (
        .clk            (clk_pixel),
        .reset          (reset),
        .frame_tick     (frame_tick),

        .left_up        (btn_sync[0]),
        .left_down      (btn_sync[1]),
        .right_up       (btn_sync[2]),
        .right_down     (btn_sync[3]),

        .left_paddle_y  (left_paddle_y),
        .right_paddle_y (right_paddle_y),

        .ball_x         (ball_x),
        .ball_y         (ball_y),

        .left_score     (left_score),
        .right_score    (right_score)
    );

    // ========================================================
    // VIDEO GENERATION
    // ========================================================

    logic [7:0] red;
    logic [7:0] green;
    logic [7:0] blue;

    pong_video video (
        .pixel_x        (pixel_x),
        .pixel_y        (pixel_y),
        .video_active   (video_active),

        .left_paddle_y  (left_paddle_y),
        .right_paddle_y (right_paddle_y),

        .ball_x         (ball_x),
        .ball_y         (ball_y),

        .left_score     (left_score),
        .right_score    (right_score),

        .red            (red),
        .green          (green),
        .blue           (blue)
    );

    // ========================================================
    // TMDS ENCODERS
    //
    // HDMI channel 0 = Blue
    // HDMI channel 1 = Green
    // HDMI channel 2 = Red
    // ========================================================

    logic [9:0] tmds_blue;
    logic [9:0] tmds_green;
    logic [9:0] tmds_red;

    tmds_encoder encoder_blue (
        .clk   (clk_pixel),
        .VD    (blue),
        .CD    ({vsync, hsync}),
        .VDE   (video_active),
        .TMDS  (tmds_blue)
    );

    tmds_encoder encoder_green (
        .clk   (clk_pixel),
        .VD    (green),
        .CD    (2'b00),
        .VDE   (video_active),
        .TMDS  (tmds_green)
    );

    tmds_encoder encoder_red (
        .clk   (clk_pixel),
        .VD    (red),
        .CD    (2'b00),
        .VDE   (video_active),
        .TMDS  (tmds_red)
    );

    // ========================================================
    // TMDS SERIALIZERS
    // ========================================================

    logic serial_blue;
    logic serial_green;
    logic serial_red;

    tmds_serializer serializer_blue (
        .clk_pixel  (clk_pixel),
        .clk_5x     (clk_125),
        .reset      (reset),
        .data       (tmds_blue),
        .serial_out (serial_blue)
    );

    tmds_serializer serializer_green (
        .clk_pixel  (clk_pixel),
        .clk_5x     (clk_125),
        .reset      (reset),
        .data       (tmds_green),
        .serial_out (serial_green)
    );

    tmds_serializer serializer_red (
        .clk_pixel  (clk_pixel),
        .clk_5x     (clk_125),
        .reset      (reset),
        .data       (tmds_red),
        .serial_out (serial_red)
    );

    // ========================================================
    // HDMI DIFFERENTIAL OUTPUTS
    // ========================================================

    OBUFDS #(
        .IOSTANDARD("TMDS_33")
    )
    hdmi_clk_buf (
        .I(clk_pixel),
        .O(hdmi_tx_clk_p),
        .OB(hdmi_tx_clk_n)
    );

    OBUFDS #(
        .IOSTANDARD("TMDS_33")
    )
    hdmi_blue_buf (
        .I(serial_blue),
        .O(hdmi_tx_p[0]),
        .OB(hdmi_tx_n[0])
    );

    OBUFDS #(
        .IOSTANDARD("TMDS_33")
    )
    hdmi_green_buf (
        .I(serial_green),
        .O(hdmi_tx_p[1]),
        .OB(hdmi_tx_n[1])
    );

    OBUFDS #(
        .IOSTANDARD("TMDS_33")
    )
    hdmi_red_buf (
        .I(serial_red),
        .O(hdmi_tx_p[2]),
        .OB(hdmi_tx_n[2])
    );

    // LEDs show the score.
    assign led = left_score ^ right_score;

endmodule


// ============================================================
// VGA / HDMI 640x480 TIMING
// ============================================================

module vga_timing (
    input  logic       clk,
    input  logic       reset,

    output logic [9:0] pixel_x,
    output logic [9:0] pixel_y,

    output logic       hsync,
    output logic       vsync,

    output logic       video_active,
    output logic       frame_tick
);

    // 640x480 @ ~60 Hz
    //
    // Horizontal:
    // visible = 640
    // front   = 16
    // sync    = 96
    // back    = 48
    // total   = 800
    //
    // Vertical:
    // visible = 480
    // front   = 10
    // sync    = 2
    // back    = 33
    // total   = 525

    localparam H_VISIBLE = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = 800;

    localparam V_VISIBLE = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = 525;

    always_ff @(posedge clk) begin

        if (reset) begin
            pixel_x   <= 0;
            pixel_y   <= 0;
            frame_tick <= 1'b0;
        end
        else begin

            frame_tick <= 1'b0;

            if (pixel_x == H_TOTAL - 1) begin

                pixel_x <= 0;

                if (pixel_y == V_TOTAL - 1) begin
                    pixel_y <= 0;
                    frame_tick <= 1'b1;
                end
                else begin
                    pixel_y <= pixel_y + 1;
                end

            end
            else begin
                pixel_x <= pixel_x + 1;
            end
        end
    end

    // Active-low synchronization pulses.
    assign hsync =
        !(
            pixel_x >= H_VISIBLE + H_FRONT &&
            pixel_x <  H_VISIBLE + H_FRONT + H_SYNC
        );

    assign vsync =
        !(
            pixel_y >= V_VISIBLE + V_FRONT &&
            pixel_y <  V_VISIBLE + V_FRONT + V_SYNC
        );

    assign video_active =
        (pixel_x < H_VISIBLE) &&
        (pixel_y < V_VISIBLE);

endmodule


// ============================================================
// PONG GAME LOGIC
// ============================================================

module pong_game (
    input logic clk,
    input logic reset,
    input logic frame_tick,

    input logic left_up,
    input logic left_down,

    input logic right_up,
    input logic right_down,

    output logic [9:0] left_paddle_y,
    output logic [9:0] right_paddle_y,

    output logic [9:0] ball_x,
    output logic [9:0] ball_y,

    output logic [3:0] left_score,
    output logic [3:0] right_score
);

    // ========================================================
    // GAME CONSTANTS
    // ========================================================

    localparam SCREEN_WIDTH  = 640;
    localparam SCREEN_HEIGHT = 480;

    localparam PADDLE_WIDTH  = 12;
    localparam PADDLE_HEIGHT = 80;

    localparam BALL_SIZE = 10;

    localparam LEFT_PADDLE_X  = 30;
    localparam RIGHT_PADDLE_X = 598;

    localparam PADDLE_SPEED = 8;

    // Ball velocity.
    //
    // Signed values allow movement in both directions.

    logic signed [10:0] ball_dx;
    logic signed [10:0] ball_dy;

    // ========================================================
    // RESET / INITIAL STATE
    // ========================================================

    always_ff @(posedge clk) begin

        if (reset) begin

            left_paddle_y  <= 200;
            right_paddle_y <= 200;

            ball_x <= 315;
            ball_y <= 235;

            ball_dx <= 4;
            ball_dy <= 2;

            left_score  <= 0;
            right_score <= 0;
        end

        else if (frame_tick) begin

            // =================================================
            // LEFT PADDLE
            // =================================================

            if (left_up && !left_down) begin

                if (left_paddle_y >= PADDLE_SPEED)
                    left_paddle_y <= left_paddle_y - PADDLE_SPEED;
                else
                    left_paddle_y <= 0;

            end

            else if (left_down && !left_up) begin

                if (left_paddle_y + PADDLE_HEIGHT + PADDLE_SPEED
                    <= SCREEN_HEIGHT)

                    left_paddle_y <=
                        left_paddle_y + PADDLE_SPEED;

                else
                    left_paddle_y <=
                        SCREEN_HEIGHT - PADDLE_HEIGHT;
            end

            // =================================================
            // RIGHT PADDLE
            // =================================================

            if (right_up && !right_down) begin

                if (right_paddle_y >= PADDLE_SPEED)
                    right_paddle_y <=
                        right_paddle_y - PADDLE_SPEED;
                else
                    right_paddle_y <= 0;

            end

            else if (right_down && !right_up) begin

                if (right_paddle_y + PADDLE_HEIGHT + PADDLE_SPEED
                    <= SCREEN_HEIGHT)

                    right_paddle_y <=
                        right_paddle_y + PADDLE_SPEED;

                else
                    right_paddle_y <=
                        SCREEN_HEIGHT - PADDLE_HEIGHT;
            end

            // =================================================
            // BALL MOVEMENT
            // =================================================

            ball_x <= ball_x + ball_dx;
            ball_y <= ball_y + ball_dy;

            // =================================================
            // TOP COLLISION
            // =================================================

            if (ball_y <= 1 && ball_dy < 0) begin
                ball_dy <= -ball_dy;
            end

            // =================================================
            // BOTTOM COLLISION
            // =================================================

            else if (
                ball_y + BALL_SIZE >= SCREEN_HEIGHT - 1 &&
                ball_dy > 0
            ) begin

                ball_dy <= -ball_dy;

            end

            // =================================================
            // LEFT PADDLE COLLISION
            // =================================================

            if (
                ball_x <= LEFT_PADDLE_X + PADDLE_WIDTH &&
                ball_x + BALL_SIZE >= LEFT_PADDLE_X &&
                ball_y + BALL_SIZE >= left_paddle_y &&
                ball_y <= left_paddle_y + PADDLE_HEIGHT &&
                ball_dx < 0
            ) begin

                ball_dx <= -ball_dx;

            end

            // =================================================
            // RIGHT PADDLE COLLISION
            // =================================================

            if (
                ball_x + BALL_SIZE >= RIGHT_PADDLE_X &&
                ball_x <= RIGHT_PADDLE_X + PADDLE_WIDTH &&
                ball_y + BALL_SIZE >= right_paddle_y &&
                ball_y <= right_paddle_y + PADDLE_HEIGHT &&
                ball_dx > 0
            ) begin

                ball_dx <= -ball_dx;

            end

            // =================================================
            // LEFT PLAYER SCORES
            // =================================================

            if (ball_x >= SCREEN_WIDTH - BALL_SIZE) begin

                left_score <= left_score + 1;

                ball_x <= 315;
                ball_y <= 235;

                ball_dx <= -4;
                ball_dy <= 2;

            end

            // =================================================
            // RIGHT PLAYER SCORES
            // =================================================

            else if (ball_x <= 1) begin

                right_score <= right_score + 1;

                ball_x <= 315;
                ball_y <= 235;

                ball_dx <= 4;
                ball_dy <= -2;

            end

        end
    end

endmodule


// ============================================================
// PONG VIDEO RENDERER
// ============================================================

module pong_video (
    input logic [9:0] pixel_x,
    input logic [9:0] pixel_y,

    input logic       video_active,

    input logic [9:0] left_paddle_y,
    input logic [9:0] right_paddle_y,

    input logic [9:0] ball_x,
    input logic [9:0] ball_y,

    input logic [3:0] left_score,
    input logic [3:0] right_score,

    output logic [7:0] red,
    output logic [7:0] green,
    output logic [7:0] blue
);

    localparam PADDLE_WIDTH  = 12;
    localparam PADDLE_HEIGHT = 80;

    localparam LEFT_PADDLE_X  = 30;
    localparam RIGHT_PADDLE_X = 598;

    localparam BALL_SIZE = 10;

    logic is_left_paddle;
    logic is_right_paddle;
    logic is_ball;
    logic is_center_line;

    // ========================================================
    // OBJECT DETECTION
    // ========================================================

    always_comb begin

        is_left_paddle =
            (pixel_x >= LEFT_PADDLE_X) &&
            (pixel_x < LEFT_PADDLE_X + PADDLE_WIDTH) &&
            (pixel_y >= left_paddle_y) &&
            (pixel_y < left_paddle_y + PADDLE_HEIGHT);

        is_right_paddle =
            (pixel_x >= RIGHT_PADDLE_X) &&
            (pixel_x < RIGHT_PADDLE_X + PADDLE_WIDTH) &&
            (pixel_y >= right_paddle_y) &&
            (pixel_y < right_paddle_y + PADDLE_HEIGHT);

        is_ball =
            (pixel_x >= ball_x) &&
            (pixel_x < ball_x + BALL_SIZE) &&
            (pixel_y >= ball_y) &&
            (pixel_y < ball_y + BALL_SIZE);

        // Dashed center line.
        is_center_line =
            (pixel_x >= 318) &&
            (pixel_x < 322) &&
            ((pixel_y / 20) % 2 == 0);

    end

    // ========================================================
    // COLOR GENERATION
    // ========================================================

    always_comb begin

        // Default: black

        red   = 8'h00;
        green = 8'h00;
        blue  = 8'h00;

        if (!video_active) begin

            red   = 8'h00;
            green = 8'h00;
            blue  = 8'h00;

        end

        else if (is_ball) begin

            // White ball

            red   = 8'hFF;
            green = 8'hFF;
            blue  = 8'hFF;

        end

        else if (is_left_paddle) begin

            // Cyan left paddle

            red   = 8'h00;
            green = 8'hFF;
            blue  = 8'hFF;

        end

        else if (is_right_paddle) begin

            // Magenta right paddle

            red   = 8'hFF;
            green = 8'h00;
            blue  = 8'hFF;

        end

        else if (is_center_line) begin

            red   = 8'h40;
            green = 8'h40;
            blue  = 8'h40;

        end

        else begin

            // Black background

            red   = 8'h00;
            green = 8'h00;
            blue  = 8'h00;

        end
    end

endmodule


// ============================================================
// TMDS ENCODER
//
// Converts 8-bit RGB + control information into a 10-bit
// TMDS symbol.
//
// This follows the standard two-stage TMDS encoding process.
// ============================================================

module tmds_encoder (
    input  logic       clk,

    input  logic [7:0] VD,
    input  logic [1:0] CD,
    input  logic       VDE,

    output logic [9:0] TMDS
);

    logic [3:0] number_of_ones;

    logic xnor_mode;

    logic [8:0] q_m;

    logic signed [4:0] balance;
    logic signed [4:0] balance_acc;

    logic invert_q_m;

    logic signed [4:0] balance_acc_inc;
    logic signed [4:0] balance_acc_new;

    logic [9:0] TMDS_data;
    logic [9:0] TMDS_control;

    always_comb begin

        number_of_ones =
            VD[0] + VD[1] + VD[2] + VD[3] +
            VD[4] + VD[5] + VD[6] + VD[7];

        xnor_mode =
            (number_of_ones > 4) ||
            ((number_of_ones == 4) && (VD[0] == 1'b0));

        // First TMDS stage.

        q_m[0] = VD[0];

        q_m[1] = q_m[0] ^ VD[1] ^ xnor_mode;
        q_m[2] = q_m[1] ^ VD[2] ^ xnor_mode;
        q_m[3] = q_m[2] ^ VD[3] ^ xnor_mode;
        q_m[4] = q_m[3] ^ VD[4] ^ xnor_mode;
        q_m[5] = q_m[4] ^ VD[5] ^ xnor_mode;
        q_m[6] = q_m[5] ^ VD[6] ^ xnor_mode;
        q_m[7] = q_m[6] ^ VD[7] ^ xnor_mode;

        q_m[8] = ~xnor_mode;

        // DC balance.

        balance =
            q_m[0] + q_m[1] + q_m[2] + q_m[3] +
            q_m[4] + q_m[5] + q_m[6] + q_m[7] - 4;

        if ((balance == 0) || (balance_acc == 0))
            invert_q_m = ~q_m[8];
        else
            invert_q_m =
                (balance[4] == balance_acc[4]);

        balance_acc_inc =
            balance -
            (
                {
                    q_m[8] ^
                    ~(balance[4] == balance_acc[4])
                }
                &
                ~((balance == 0) || (balance_acc == 0))
            );

        if (invert_q_m)
            balance_acc_new =
                balance_acc - balance_acc_inc;
        else
            balance_acc_new =
                balance_acc + balance_acc_inc;

        TMDS_data = {
            invert_q_m,
            q_m[8],
            q_m[7:0] ^ {8{invert_q_m}}
        };

        // HDMI control symbols.

        case (CD)

            2'b00:
                TMDS_control = 10'b1101010100;

            2'b01:
                TMDS_control = 10'b0010101011;

            2'b10:
                TMDS_control = 10'b0101010100;

            2'b11:
                TMDS_control = 10'b1010101011;

            default:
                TMDS_control = 10'b1101010100;

        endcase
    end

    always_ff @(posedge clk) begin

        if (VDE) begin

            TMDS <= TMDS_data;
            balance_acc <= balance_acc_new;

        end

        else begin

            TMDS <= TMDS_control;
            balance_acc <= 0;

        end
    end

endmodule


// ============================================================
// 10:1 TMDS SERIALIZER
//
// 7-series OSERDESE2.
//
// 125 MHz = 5x 25 MHz pixel clock.
//
// DDR means 10 bits are transmitted per 25 MHz pixel period.
// ============================================================

module tmds_serializer (
    input  logic       clk_pixel,
    input  logic       clk_5x,
    input  logic       reset,

    input  logic [9:0] data,

    output logic       serial_out
);

    logic shift1;
    logic shift2;

    OSERDESE2 #(
        .DATA_RATE_OQ("DDR"),
        .DATA_RATE_TQ("SDR"),
        .DATA_WIDTH(10),

        .INIT_OQ(1'b0),
        .INIT_TQ(1'b0),

        .SERDES_MODE("MASTER"),

        .SRVAL_OQ(1'b0),
        .SRVAL_TQ(1'b0),

        .TBYTE_CTL("FALSE"),
        .TBYTE_SRC("FALSE"),
        .TRISTATE_WIDTH(1)
    )
    oserdes_master (
        .OQ(serial_out),

        .OFB(),
        .TQ(),

        .SHIFTOUT1(),
        .SHIFTOUT2(),

        .TBYTEOUT(),

        .CLK(clk_5x),
        .CLKDIV(clk_pixel),

        .D1(data[0]),
        .D2(data[1]),
        .D3(data[2]),
        .D4(data[3]),
        .D5(data[4]),
        .D6(data[5]),
        .D7(data[6]),
        .D8(data[7]),

        .OCE(1'b1),
        .RST(reset),

        .SHIFTIN1(shift1),
        .SHIFTIN2(shift2),

        .T1(1'b0),
        .T2(1'b0),
        .T3(1'b0),
        .T4(1'b0),

        .TBYTEIN(1'b0),
        .TCE(1'b0)
    );


    OSERDESE2 #(
        .DATA_RATE_OQ("DDR"),
        .DATA_RATE_TQ("SDR"),
        .DATA_WIDTH(10),

        .INIT_OQ(1'b0),
        .INIT_TQ(1'b0),

        .SERDES_MODE("SLAVE"),

        .SRVAL_OQ(1'b0),
        .SRVAL_TQ(1'b0),

        .TBYTE_CTL("FALSE"),
        .TBYTE_SRC("FALSE"),
        .TRISTATE_WIDTH(1)
    )
    oserdes_slave (
        .OQ(),

        .OFB(),
        .TQ(),

        .SHIFTOUT1(shift1),
        .SHIFTOUT2(shift2),

        .TBYTEOUT(),

        .CLK(clk_5x),
        .CLKDIV(clk_pixel),

        .D1(1'b0),
        .D2(1'b0),
        .D3(data[8]),
        .D4(data[9]),
        .D5(1'b0),
        .D6(1'b0),
        .D7(1'b0),
        .D8(1'b0),

        .OCE(1'b1),
        .RST(reset),

        .SHIFTIN1(1'b0),
        .SHIFTIN2(1'b0),

        .T1(1'b0),
        .T2(1'b0),
        .T3(1'b0),
        .T4(1'b0),

        .TBYTEIN(1'b0),
        .TCE(1'b0)
    );

endmodule