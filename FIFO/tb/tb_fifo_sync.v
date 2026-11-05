`timescale 1ns / 1ps

module tb_fifo_sync;

    parameter DATA_WIDTH = 8;

    parameter FIFO_DEPTH = 16;

    reg                   clk;

    reg                   rst_n;

    reg                   wr_en;

    reg  [DATA_WIDTH-1:0] din;

    wire                  full;

    reg                   rd_en;

    wire [DATA_WIDTH-1:0] dout;

    wire                  empty;

    wire [$clog2(FIFO_DEPTH):0] data_cnt;

    // Unit Under Test (UUT)

    fifo_sync #(

        .DATA_WIDTH(DATA_WIDTH),

        .FIFO_DEPTH(FIFO_DEPTH)

    ) uut (

        .clk(clk),

        .rst_n(rst_n),

        .wr_en(wr_en),

        .din(din),

        .full(full),

        .rd_en(rd_en),

        .dout(dout),

        .empty(empty),

        .data_cnt(data_cnt)

    );

    // 100 MHz Soat signali (davri 10ns)

    always #5 clk = ~clk;

    integer i;

    initial begin

        // Boshlang'ich holat

        clk   = 0;

        rst_n = 0;

        wr_en = 0;

        din   = 0;

        rd_en = 0;

        #20;

        rst_n = 1; // Resetdan chiqaramiz

        #10;

        $display("=== 1-TEST: Ketma-ket 16 ta bayt yozish (To'lguncha) ===");

        for (i = 0; i < 16; i = i + 1) begin

            @(posedge clk);

            wr_en = 1;

            din   = 8'hA0 + i; // 0xA0, 0xA1, 0xA2 ... 0xAF

        end

        @(posedge clk);

        wr_en = 0; // Yozish to'xtatildi

        #10;

        if (full) 

            $display("[MUVAFFAQIYATLI]: FIFO to'ldi (full = 1), data_cnt = %d", data_cnt);

        else 

            $display("[XATO]: FIFO to'lmadi!");

        #20;

        $display("=== 2-TEST: To'lgan FIFO'ga yana yozishga urinish (Overflow tekshiruvi) ===");

        @(posedge clk);

        wr_en = 1;

        din   = 8'hFF;

        @(posedge clk);

        wr_en = 0;

        #10;

        $display("=== 3-TEST: Ketma-ket 16 ta baytni o'qib olish (Bo'shaguncha) ===");

        for (i = 0; i < 16; i = i + 1) begin

            @(posedge clk);

            rd_en = 1;

            @(posedge clk);

            rd_en = 0;

            $display("O'qilgan bayt: 0x%02X (Qolgan baytlar soni: %d)", dout, data_cnt);

            #10;

        end

        if (empty)

            $display("[MUVAFFAQIYATLI]: FIFO to'liq bo'shadi (empty = 1)!");

        else

            $display("[XATO]: FIFO hali ham bo'sh emas!");

        #50;

        $display("BARCHA TESTLAR YAKUNLANDI!");

        $finish;

    end

endmodule