`default_nettype none

module tt_um_thanh31806_c06 (
    input  wire [7:0] ui_in,    // sample_in
    output wire [7:0] uo_out,   // result_count[7:0]
    input  wire [7:0] uio_in,   // threshold
    output wire [7:0] uio_out,  // result_count[8] và window_done
    output wire [7:0] uio_oe,   // Output enable cho uio
    input  wire       ena,      // Enable
    input  wire       clk,      // Clock
    input  wire       rst_n     // Reset
);

    // Ánh xạ tín hiệu
    wire [7:0] sample_in = ui_in;
    wire [7:0] threshold = uio_in;

    // Tín hiệu nội bộ
    logic       event_now;
    logic       terminal;
    logic [8:0] completed_count;
    logic [8:0] result_count_internal;
    logic       window_done_internal;
    
    // Thanh ghi trạng thái
    logic [7:0] window_count;
    logic [8:0] event_count;

    // Phần tổ hợp
    always_comb begin
        event_now = (sample_in > threshold);
        terminal  = (window_count == 8'd255);
        completed_count = {1'b0, event_count} + {{8{1'b0}}, event_now};
    end

    // Phần tuần tự
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            window_count <= 8'd0;
            event_count  <= 9'd0;
            result_count_internal <= 9'd0;
            window_done_internal  <= 1'b0;
        end else begin
            window_done_internal <= 1'b0; // Mặc định xóa xung
            if (terminal) begin
                result_count_internal <= completed_count;
                window_count <= 8'd0;
                event_count  <= 9'd0;
                window_done_internal  <= 1'b1;
            end else begin
                window_count <= window_count + 8'd1;
                event_count  <= completed_count;
            end
        end
    end

    // Ánh xạ ra cổng Tiny Tapeout
    assign uo_out = result_count_internal[7:0];
    assign uio_out[0] = window_done_internal;
    assign uio_out[1] = result_count_internal[8];
    assign uio_out[7:2] = 6'b0;
    assign uio_oe = 8'b00000011; // Chỉ bit 0 và 1 là output

endmodule

`default_nettype wire
  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};

endmodule
