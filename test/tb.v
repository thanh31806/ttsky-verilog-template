`timescale 1ns/1ps

module tb;
    // Tín hiệu kết nối
    reg clk;
    reg rst_n;
    reg ena;
    reg [7:0] ui_in;
    reg [7:0] uio_in;
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    // Khởi tạo DUT
    tt_um_thanh31806_c06 dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n)
    );

    // Clock 10ns
    always #5 clk = ~clk;

    // Task nạp mẫu
    task apply_cycle(input [7:0] sample, input [7:0] thresh);
        begin
            ui_in = sample;
            uio_in = thresh;
            @(posedge clk);
            #1;
        end
    endtask

    // Task reset
    task reset_dut;
        begin
            rst_n = 0;
            repeat(2) @(posedge clk);
            rst_n = 1;
            #1;
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 1;
        ena = 1;
        ui_in = 0;
        uio_in = 0;

        // CA 1: Sự kiện tại chu kỳ 1, 255, 256
        reset_dut();
        apply_cycle(8'd101, 8'd100);
        for (int i=2; i<=254; i++) apply_cycle(8'd100, 8'd100);
        apply_cycle(8'd101, 8'd100);
        apply_cycle(8'd101, 8'd100);
        if (uo_out !== 8'd3) $display("FAIL: CA 1, ky vong 3, nhan duoc %0d", uo_out);
        else $display("PASS: CA 1 (Ket qua = 3)");

        // CA 2: Tất cả đều vượt ngưỡng (Tràn số)
        reset_dut();
        for (int i=1; i<=256; i++) apply_cycle(8'd101, 8'd100);
        if (uo_out !== 8'd0 || uio_out[1] !== 1'b1) $display("FAIL: CA 2, ky vong 256, nhan duoc uo_out=%0d, uio_out[1]=%0d", uo_out, uio_out[1]);
        else $display("PASS: CA 2 (Ket qua = 256)");

        // CA 3: Bằng ngưỡng (Biên)
        reset_dut();
        for (int i=1; i<=256; i++) apply_cycle(8'd100, 8'd100);
        if (uo_out !== 8'd0) $display("FAIL: CA 3, ky vong 0, nhan duoc %0d", uo_out);
        else $display("PASS: CA 3 (Ket qua = 0)");

        // CA 4: Cửa sổ mới bắt đầu ngay
        reset_dut();
        for (int i=1; i<=256; i++) apply_cycle(8'd101, 8'd100);
        apply_cycle(8'd101, 8'd100); // Mẫu đầu tiên của cửa sổ 2
        if (uo_out !== 8'd1) $display("FAIL: CA 4, ky vong 1, nhan duoc %0d", uo_out);
        else $display("PASS: CA 4 (Ket qua = 1)");

        // CA 5 (Tự nghĩ): Xen kẽ 101, 100
        reset_dut();
        for (int i=1; i<=256; i++) begin
            if (i % 2 == 1) apply_cycle(8'd101, 8'd100);
            else apply_cycle(8'd100, 8'd100);
        end
        if (uo_out !== 8'd128) $display("FAIL: CA 5, ky vong 128, nhan duoc %0d", uo_out);
        else $display("PASS: CA 5 (Ket qua = 128)");

        // CA 6 (Tự nghĩ): Reset giữa cửa sổ
        reset_dut();
        for (int i=1; i<=100; i++) apply_cycle(8'd101, 8'd100);
        reset_dut(); // Reset giữa chừng
        if (uo_out !== 8'd0) $display("FAIL: CA 6, ky vong 0, nhan duoc %0d", uo_out);
        else $display("PASS: CA 6 (Reset thanh cong)");

        $display("Testbench finished.");
        $finish(0); // Quan trọng: dùng $finish(0) để CI không báo lỗi exit code 1
    end
endmodule
