`timescale 1ns / 1ps

module uart_tx #(

    parameter CLK_FREQ  = 100_000_000, // Tizim soati: 100 MHz

    parameter BAUD_RATE = 115_200      // Aloqa tezligi: 115200 bps

)(

    input  wire       clk,        // Tizim soati

    input  wire       rst_n,      // Asinxron reset (active-low)

    input  wire       tx_start,   // Uzatishni boshlash signali (1 taktlik impuls)

    input  wire [7:0] tx_data,    // Uzatilishi kerak bo'lgan 1 bayt ma'lumot

    output reg        tx_line,    // Tashqi fizik chiqish simi (UART TX)

    output wire       tx_busy     // Modul bandligini bildiruvchi signal

);

    // 1 bit uchun kerak bo'ladigan taktlar soni

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    // FSM (Holatlar) ro'yxati - One-Hot yoki Binary kodlash

    localparam STATE_IDLE  = 2'b00;

    localparam STATE_START = 2'b01;

    localparam STATE_DATA  = 2'b10;

    localparam STATE_STOP  = 2'b11;

    reg [1:0]  state;

    reg [15:0] clk_cnt;   // 868 gacha sanovchi hisoblagich

    reg [2:0]  bit_idx;   // 0 dan 7 gacha qaysi bit uzatilayotganini sanaydi

    reg [7:0]  data_buf;  // Uzatilayotgan ma'lumotning xotirasi (bufer)

    // Modul qachon band? IDLE dan boshqa har qanday holatda band!

    assign tx_busy = (state != STATE_IDLE);

    // Sanoatda qabul qilingan 1-protsessli FSM mantiqi

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            state    <= STATE_IDLE;

            tx_line  <= 1'b1; // Tinch holatda doimo 1

            clk_cnt  <= 16'd0;

            bit_idx  <= 3'd0;

            data_buf <= 8'd0;

        end 
        else begin

            case (state)

                // ----------------------------------------------------

                // 1-HOLAT: KUTISH REJIMI

                // ----------------------------------------------------

                STATE_IDLE: begin

                    tx_line <= 1'b1;

                    clk_cnt <= 16'd0;

                    bit_idx <= 3'd0;

                    if (tx_start) begin

                        data_buf <= tx_data;   // Ma'lumotni buferga olamiz

                        state    <= STATE_START; // Start berishga o'tamiz

                    end

                end

                // ----------------------------------------------------

                // 2-HOLAT: START BITI (Liniyaga 0 chiqarish)

                // ----------------------------------------------------

                STATE_START: begin

                    tx_line <= 1'b0; // Start bit = 0

                    if (clk_cnt < CLKS_PER_BIT - 1) begin

                        clk_cnt <= clk_cnt + 1'b1;

                    end else begin

                        clk_cnt <= 16'd0;

                        state   <= STATE_DATA; // 8 bit ma'lumotga o'tamiz

                    end

                end

                // ----------------------------------------------------

                // 3-HOLAT: DATA BITLARI (8 ta bitni uzatish)

                // ----------------------------------------------------

                STATE_DATA: begin

                    tx_line <= data_buf[bit_idx]; // Hozirgi bitni chiqaramiz

                    if (clk_cnt < CLKS_PER_BIT - 1) begin

                        clk_cnt <= clk_cnt + 1'b1;

                    end else begin

                        clk_cnt <= 16'd0;

                        if (bit_idx < 3'd7) begin

                            bit_idx <= bit_idx + 1'b1; // Keyingi bitga o'tish

                        end else begin

                            bit_idx <= 3'd0;

                            state   <= STATE_STOP;     // Stop bitga o'tish

                        end

                    end

                end

                // ----------------------------------------------------

                // 4-HOLAT: STOP BITI (Liniyaga 1 chiqarish)

                // ----------------------------------------------------

                STATE_STOP: begin

                    tx_line <= 1'b1; // Stop bit = 1

                    if (clk_cnt < CLKS_PER_BIT - 1) begin

                        clk_cnt <= clk_cnt + 1'b1;

                    end else begin

                        clk_cnt <= 16'd0;

                        state   <= STATE_IDLE; // Uzatish tugadi, yana kutish rejimiga

                    end

                end

                default: state <= STATE_IDLE;

            endcase

        end

    end

endmodule