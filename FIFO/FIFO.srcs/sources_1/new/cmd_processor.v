`timescale 1ns / 1ps

module cmd_processor (

    input  wire       clk,

    input  wire       rst_n,

    // FIFO bilan aloqa (O'qish)

    input  wire       fifo_empty,

    input  wire [7:0] fifo_dout,

    output reg        fifo_rd_en,

    // UART TX bilan aloqa (Uzatish)

    input  wire       tx_busy,

    output reg        tx_start,

    output reg  [7:0] tx_data,

    // Boshqariladigan apparat registrlari

    output reg  [7:0] reg_leds

);

    // ------------------------------------------------------------------------

    // Ichki erkin sanovchi hisoblagich (Uptime Counter)

    // ------------------------------------------------------------------------

    reg [23:0] prescaler;

    reg [7:0]  uptime_counter;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            prescaler      <= 24'd0;

            uptime_counter <= 8'd0;

        end else begin

            prescaler <= prescaler + 1'b1;

            if (prescaler == 24'd100_000) begin // Davriy ravishda oshib boradi

                prescaler      <= 24'd0;

                uptime_counter <= uptime_counter + 1'b1;

            end

        end

    end

    // ------------------------------------------------------------------------

    // FSM (Holatlar Mashinasi)

    // ------------------------------------------------------------------------

    localparam S_IDLE            = 3'd0;

    localparam S_READ_CMD        = 3'd1;

    localparam S_WAIT_CMD        = 3'd2;

    localparam S_DECODE          = 3'd3;

    localparam S_WAIT_ARG        = 3'd4;

    localparam S_FETCH_ARG       = 3'd5;

    localparam S_EXECUTE_ARG     = 3'd6;

    localparam S_WAIT_TX         = 3'd7;

    reg [2:0] state;

    reg [7:0] current_cmd;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            state       <= S_IDLE;

            fifo_rd_en  <= 1'b0;

            tx_start    <= 1'b0;

            tx_data     <= 8'd0;

            reg_leds    <= 8'h00; // Dastlab hamma LEDlar o'chiq

            current_cmd <= 8'd0;

        end else begin

            case (state)

                // 1. Yangi buyruq kutish

                S_IDLE: begin

                    tx_start <= 1'b0;

                    if (!fifo_empty && !tx_busy) begin

                        fifo_rd_en <= 1'b1; // FIFO dan buyruq baytini o'qish

                        state      <= S_READ_CMD;

                    end

                end

                // 2. O'qish impulsi

                S_READ_CMD: begin

                    fifo_rd_en <= 1'b0;

                    state      <= S_WAIT_CMD;

                end

                // 3. FIFO dout barqarorlashishi

                S_WAIT_CMD: begin

                    current_cmd <= fifo_dout;

                    state       <= S_DECODE;

                end

                // 4. Buyruqni tahlil qilish (Dekodlash)

                S_DECODE: begin

                    case (current_cmd)

                        // 0x01: PING -> 0xAA javob

                        8'h01: begin

                            tx_data  <= 8'hAA;

                            tx_start <= 1'b1;

                            state    <= S_WAIT_TX;

                        end

                        // 0x02: SET_LEDS -> 2-bayt (argument) kerak

                        8'h02: begin

                            state <= S_WAIT_ARG;

                        end

                        // 0x03: READ_LEDS -> LED holatini qaytarish

                        8'h03: begin

                            tx_data  <= reg_leds;

                            tx_start <= 1'b1;

                            state    <= S_WAIT_TX;

                        end

                        // 0x04: READ_COUNTER -> Hisoblagichni qaytarish

                        8'h04: begin

                            tx_data  <= uptime_counter;

                            tx_start <= 1'b1;

                            state    <= S_WAIT_TX;

                        end

                        // 0x05: MATH (2 ga ko'paytirish) -> 2-bayt (argument) kerak

                        8'h05: begin

                            state <= S_WAIT_ARG;

                        end

                        // Noma'lum buyruq -> 0xEE xato kodi

                        default: begin

                            tx_data  <= 8'hEE;

                            tx_start <= 1'b1;

                            state    <= S_WAIT_TX;

                        end

                    endcase

                end

                // 5. 2-baytli buyruqlar uchun argument kutish

                S_WAIT_ARG: begin

                    if (!fifo_empty) begin

                        fifo_rd_en <= 1'b1;

                        state      <= S_FETCH_ARG;

                    end

                end

                S_FETCH_ARG: begin

                    fifo_rd_en <= 1'b0;

                    state      <= S_EXECUTE_ARG;

                end

                // 6. Argument keldi -> Vazifani bajarish

                S_EXECUTE_ARG: begin

                    if (current_cmd == 8'h02) begin

                        reg_leds <= fifo_dout; // LEDlarni yangilaymiz

                        tx_data  <= 8'h06;     // 0x06 = ACK (Bajarildi)

                    end else if (current_cmd == 8'h05) begin

                        tx_data  <= (fifo_dout << 1); // 2 ga ko'paytirish!

                    end

                    tx_start <= 1'b1;

                    state    <= S_WAIT_TX;

                end

                // 7. TX jo'natib bo'lishini kutish

                S_WAIT_TX: begin

                    tx_start <= 1'b0;

                    if (!tx_busy) begin

                        state <= S_IDLE;

                    end

                end

                default: state <= S_IDLE;

            endcase

        end

    end

endmodule