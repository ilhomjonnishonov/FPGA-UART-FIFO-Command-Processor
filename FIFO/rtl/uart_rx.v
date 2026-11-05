`timescale 1ns / 1ps

module uart_rx #(

    // Parametrlar: Kodni boshqa tezlik va soatlarga oson moslashuvchan qilish uchun

    parameter CLK_FREQ  = 100_000_000, // Tizim soati: 100 MHz

    parameter BAUD_RATE = 115_200      // Aloqa tezligi: 115200 bps

)(

    // Portlar: Modulning tashqi oyoqchalari

    input  wire       clk,      // 100 MHz tizim soati

    input  wire       rst_n,    // Asinxron reset (0 bo'lganda tozalaydi)

    input  wire       rx_line,  // Tashqi simdan kelayotgan UART signali (RX)

    output reg  [7:0] rx_data,  // Qabul qilingan 1 bayt ma'lumot

    output reg        rx_done   // "Yangi bayt qabul qilindi!" degan 1 taktlik bayroqcha (flag)

);

    // 1 bit uchun kerak bo'ladigan taktlar soni (100_000_000 / 115_200 = 868)

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    // FSM (Holatlar mashinasi) ro'yxati

    localparam STATE_IDLE  = 2'b00; // Tinch holat (liniyada 1 turibdi)

    localparam STATE_START = 2'b01; // Start bitini tekshirish (o'rtasigacha sanash)

    localparam STATE_DATA  = 2'b10; // 8 ta bitni o'qib olish

    localparam STATE_STOP  = 2'b11; // Stop bitini kutish

    reg [1:0]  state;

    reg [15:0] clk_cnt;      // Taktlarni sanovchi hisoblagich

    reg [2:0]  bit_idx;      // Qaysi bit o'qilayotganini sanaydi (0 dan 7 gacha)

    reg [7:0]  rx_data_buf;  // Bitlar yig'ilib turadigan vaqtinchalik bufer

    // Asinxron keluvchi signalni barqarorlashtirish (Metastabillikka qarshi 2 ta Flip-Flop)

    // Sanoatda tashqi simdan kelgan har qanday signal avval 2 ta registr orqali o'tkaziladi

    reg rx_sync1;

    reg rx_sync2;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            rx_sync1 <= 1'b1;

            rx_sync2 <= 1'b1;

        end else begin

            rx_sync1 <= rx_line;

            rx_sync2 <= rx_sync1;

        end

    end

    // FSM ning asosiy mantiqiy bloki

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            state       <= STATE_IDLE;

            clk_cnt     <= 16'd0;

            bit_idx     <= 3'd0;

            rx_data_buf <= 8'd0;

            rx_data     <= 8'd0;

            rx_done     <= 1'b0;

        end else begin

            // rx_done flagi faqat 1 takt davomida 1 bo'lib turishi kerak

            rx_done <= 1'b0;

            case (state)

                // ----------------------------------------------------

                // 1-HOLAT: KUTISH REJIMI

                // ----------------------------------------------------

                STATE_IDLE: begin

                    clk_cnt <= 16'd0;

                    bit_idx <= 3'd0;

                    // Agar liniya 1 dan 0 ga tushsa, demak kimdir ma'lumot jo'natmoqchi!

                    if (rx_sync2 == 1'b0) begin

                        state <= STATE_START;

                    end

                end

                // ----------------------------------------------------

                // 2-HOLAT: START BITINING QOQ O'RTASINI TOPISH

                // ----------------------------------------------------

                STATE_START: begin

                    // Bitning qoq o'rtasigacha (868 / 2 = 434) sanaymiz

                    if (clk_cnt == (CLKS_PER_BIT / 2)) begin

                        // 434-taktda yana qaraymiz: rostdan ham 0 turibdimi?

                        if (rx_sync2 == 1'b0) begin

                            clk_cnt <= 16'd0;       // Hisoblagichni nollab,

                            state   <= STATE_DATA;  // Haqiqiy ma'lumotni o'qishga o'tamiz

                        end else begin

                            state   <= STATE_IDLE;  // Agar 1 bo'lib qolgan bo'lsa, bu shovqin ekan, kutishga qayt

                        end

                    end else begin

                        clk_cnt <= clk_cnt + 1'b1;

                    end

                end

                // ----------------------------------------------------

                // 3-HOLAT: 8 TA MA'LUMOT BITINI O'QISH

                // ----------------------------------------------------

                STATE_DATA: begin

                    // Har bir to'liq bit vaqti (868 takt) o'tganda (yana o'rtasiga tushamiz)

                    if (clk_cnt < CLKS_PER_BIT - 1) begin

                        clk_cnt <= clk_cnt + 1'b1;

                    end else begin

                        clk_cnt <= 16'd0;

                        // Simdagi bitni buferga yozib olamiz!

                        rx_data_buf[bit_idx] <= rx_sync2;

                        if (bit_idx < 3'd7) begin

                            bit_idx <= bit_idx + 1'b1; // Keyingi bitga o'tish

                        end else begin

                            bit_idx <= 3'd0;

                            state   <= STATE_STOP;     // 8 bit tugadi, Stop ga o'tish

                        end

                    end

                end

                // ----------------------------------------------------

                // 4-HOLAT: STOP BITINI TEKSHIRISH VA YAKUNLASH

                // ----------------------------------------------------

                STATE_STOP: begin

                    if (clk_cnt < CLKS_PER_BIT - 1) begin

                        clk_cnt <= clk_cnt + 1'b1;

                    end else begin

                        clk_cnt <= 16'd0;

                        rx_data <= rx_data_buf; // Butun baytni asosiy chiqishga uzatamiz

                        rx_done <= 1'b1;        // "Yangi bayt tayyor!" deb signal beramiz

                        state   <= STATE_IDLE;  // Yana kutishga qaytamiz

                    end

                end

                default: state <= STATE_IDLE;

            endcase

        end

    end

endmodule