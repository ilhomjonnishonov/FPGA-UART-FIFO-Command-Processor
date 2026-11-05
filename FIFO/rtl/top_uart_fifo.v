`timescale 1ns / 1ps
module top_uart_fifo (
    input wire clk,   // Zynq PS dan keluvchi 100 MHz soat
    input wire rst_n  // Tizim reset signali
);
    // ------------------------------------------------------------------------
    // 1. VIO VIRTUAL BOSHQARUV SIGNALLARI
    // ------------------------------------------------------------------------
    wire [7:0] vio_tx_byte;
    wire       vio_send_btn;
    wire [7:0] reg_leds;
    reg  [7:0] last_resp_byte;
    reg  [7:0] resp_counter;
    // Tugmani bosish detektori (Rising edge pulse)
    reg btn_d1, btn_d2;
    wire send_pulse;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_d1 <= 1'b0;
            btn_d2 <= 1'b0;
        end else begin
            btn_d1 <= vio_send_btn;
            btn_d2 <= btn_d1;
        end
    end
    assign send_pulse = (btn_d1 == 1'b1) && (btn_d2 == 1'b0);
    // ------------------------------------------------------------------------
    // 2. ICHKI VIRTUAL SIMLAR
    // ------------------------------------------------------------------------
    wire serial_host_to_fpga; // Kompyuter buyrug'ini uzatuvchi ichki sim
    wire serial_fpga_to_host; // FPGA javobini qaytaruvchi ichki sim
    // Virtual Kompyuter uzatgichi (Host TX)
    wire host_tx_busy;
    uart_tx #(
        .CLK_FREQ(100_000_000), .BAUD_RATE(115_200)
    ) u_host_tx (
        .clk(clk), .rst_n(rst_n),
        .tx_start(send_pulse), .tx_data(vio_tx_byte),
        .tx_line(serial_host_to_fpga), .tx_busy(host_tx_busy)
    );
    // ------------------------------------------------------------------------
    // 3. ASOSIY FPGA TIZIMI (RX -> FIFO -> CMD_PROCESSOR -> TX)
    // ------------------------------------------------------------------------
    wire [7:0] rx_data;
    wire       rx_done;
    wire       fifo_wr_en;
    wire [7:0] fifo_din;
    wire       fifo_rd_en;
    wire [7:0] fifo_dout;
    wire       fifo_full, fifo_empty;
    wire       fpga_tx_start;
    wire [7:0] fpga_tx_data;
    wire       fpga_tx_busy;
    // FPGA RX
    uart_rx #(
        .CLK_FREQ(100_000_000), .BAUD_RATE(115_200)
    ) u_fpga_rx (
        .clk(clk), .rst_n(rst_n),
        .rx_line(serial_host_to_fpga),
        .rx_data(rx_data), .rx_done(rx_done)
    );
    // FIFO
    assign fifo_din   = rx_data;
    assign fifo_wr_en = rx_done && !fifo_full;
    fifo_generator_0 u_fifo (
        .clk(clk), .srst(~rst_n),
        .din(fifo_din), .wr_en(fifo_wr_en), .rd_en(fifo_rd_en),
        .dout(fifo_dout), .full(fifo_full), .empty(fifo_empty),
        .wr_rst_busy(), .rd_rst_busy()
    );
    // Buyruqlar protsessori (FSM)
    cmd_processor u_cmd_proc (
        .clk(clk), .rst_n(rst_n),
        .fifo_empty(fifo_empty), .fifo_dout(fifo_dout), .fifo_rd_en(fifo_rd_en),
        .tx_busy(fpga_tx_busy), .tx_start(fpga_tx_start), .tx_data(fpga_tx_data),
        .reg_leds(reg_leds)
    );
    // FPGA TX (Javob qaytaruvchi)
    uart_tx #(
        .CLK_FREQ(100_000_000), .BAUD_RATE(115_200)
    ) u_fpga_tx (
        .clk(clk), .rst_n(rst_n),
        .tx_start(fpga_tx_start), .tx_data(fpga_tx_data),
        .tx_line(serial_fpga_to_host), .tx_busy(fpga_tx_busy)
    );
    // ------------------------------------------------------------------------
    // 4. JAVOBNI QABUL QILIB, EKRANDA KO'RSATISH (Host RX)
    // ------------------------------------------------------------------------
    wire [7:0] host_rx_data;
    wire       host_rx_done;
    uart_rx #(
        .CLK_FREQ(100_000_000), .BAUD_RATE(115_200)
    ) u_host_rx (
        .clk(clk), .rst_n(rst_n),
        .rx_line(serial_fpga_to_host),
        .rx_data(host_rx_data), .rx_done(host_rx_done)
    );
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_resp_byte <= 8'h00;
            resp_counter   <= 8'd0;
        end else if (host_rx_done) begin
            last_resp_byte <= host_rx_data;
            resp_counter   <= resp_counter + 1'b1;
        end
    end
    // ------------------------------------------------------------------------
    // 5. VIO (VIRTUAL PANEL)
    // ------------------------------------------------------------------------
    vio_0 u_vio (
        .clk(clk),
        .probe_out0(vio_tx_byte),    // 8 bit: Buyruq kodi
        .probe_out1(vio_send_btn),   // 1 bit: "Send" tugmasi
        .probe_in0 (last_resp_byte), // 8 bit: FPGA qaytargan javob
        .probe_in1 (reg_leds),       // 8 bit: Virtual LEDlar
        .probe_in2 (resp_counter)    // 8 bit: Javoblar soni
    );
endmodule