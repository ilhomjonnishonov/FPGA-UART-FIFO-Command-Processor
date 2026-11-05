`timescale 1ns / 1ps

// ============================================================================

// Modul nomi: fifo_sync

// Vazifasi   : Parametrlashgan Sinxron FIFO (Circular Buffer)

// Platforma  : Xilinx Zynq UltraScale+ / Har qanday FPGA

// ============================================================================

module fifo_sync #(

    parameter DATA_WIDTH = 8,   // Har bir ma'lumot necha bit (UART uchun 8 bit)

    parameter FIFO_DEPTH = 16   // Nechta bayt sig'ishi kerak (2 ning darajasi bo'lsin: 16, 32, 64, 256)

)(

    input  wire                  clk,

    input  wire                  rst_n,      // Active-low reset (0 bo'lganda reset)

    // --- Yozish interfeysi (Write Interface) ---

    input  wire                  wr_en,      // 1 bo'lsa, din dagi ma'lumot xotiraga yoziladi

    input  wire [DATA_WIDTH-1:0] din,        // Yozilayotgan bayt

    output wire                  full,       // 1 bo'lsa, FIFO to'lgan, yozib bo'lmaydi

    // --- O'qish interfeysi (Read Interface) ---

    input  wire                  rd_en,      // 1 bo'lsa, navbatdagi bayt o'qiladi

    output reg  [DATA_WIDTH-1:0] dout,       // O'qib olingan bayt

    output wire                  empty,      // 1 bo'lsa, FIFO bo'sh, o'qib bo'lmaydi

    // --- Monitoring (Ixtiyoriy, hozir nechta element borligi) ---

    output wire [$clog2(FIFO_DEPTH):0] data_cnt

);

    // Manzil bitlari sonini avtomatik hisoblash: masalan FIFO_DEPTH=16 bo'lsa, ADDR_WIDTH = 4

    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);

    // 1. Ichki xotira massivi (RAM / Registers)

    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

    // 2. Yozish va O'qish ko'rsatkichlari ((ADDR_WIDTH + 1) bitli)

    reg [ADDR_WIDTH:0] wr_ptr;

    reg [ADDR_WIDTH:0] rd_ptr;

    // ------------------------------------------------------------------------

    // YOZISH MANTIQI (Write Logic)

    // ------------------------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            wr_ptr <= {(ADDR_WIDTH+1){1'b0}};

        end else if (wr_en && !full) begin

            // Faqat FIFO to'lmagan bo'lsagina pastki manzilga yozamiz

            mem[wr_ptr[ADDR_WIDTH-1:0]] <= din;

            wr_ptr <= wr_ptr + 1'b1; // Ko'rsatkich 1 qadam siljiydi

        end

    end

    // ------------------------------------------------------------------------

    // O'QISH MANTIQI (Read Logic)

    // ------------------------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            rd_ptr <= {(ADDR_WIDTH+1){1'b0}};

            dout   <= {DATA_WIDTH{1'b0}};

        end else if (rd_en && !empty) begin

            // Faqat FIFO bo'sh bo'lmagandagina o'qiymiz

            dout   <= mem[rd_ptr[ADDR_WIDTH-1:0]];

            rd_ptr <= rd_ptr + 1'b1; // Ko'rsatkich 1 qadam siljiydi

        end

    end

    // ------------------------------------------------------------------------

    // BAYROQLAR (Flags): EMPTY, FULL va DATA_CNT

    // ------------------------------------------------------------------------

    // Barcha bitlar teng bo'lsa -> Bo'sh

    assign empty = (wr_ptr == rd_ptr);

    // Pastki manzil teng, lekin MSB (doira biti) har xil bo'lsa -> To'la

    assign full  = (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]) &&

                   (wr_ptr[ADDR_WIDTH]     != rd_ptr[ADDR_WIDTH]);

    // Hozirda ichida nechta bayt navbatda turganini ko'rsatuvchi hisoblagich

    assign data_cnt = wr_ptr - rd_ptr;

endmodule
