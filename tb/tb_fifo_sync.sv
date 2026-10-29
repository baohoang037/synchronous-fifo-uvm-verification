`timescale 1ns/1ps

module tb_fifo_sync;
    import uvm_pkg::*;
    import tb_fifo_sync_pkg::*;
    tb_fifo_if #(.DATA_WIDTH(DATA_WIDTH)) vif(); //real interface

    fifo_sync #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk   (vif.clk),
        .rst_n (vif.rst_n),
        .wr_en (vif.wr_en),
        .rd_en (vif.rd_en),
        .din   (vif.din),
        .dout  (vif.dout),
        .full  (vif.full),
        .empty (vif.empty)
    );

    // 100 MHz clock

    initial vif.clk = 0;

    always #5ns vif.clk = ~vif.clk; //200mhz

    initial begin
        vif.rst_n = 0;
        vif.wr_en = 0;
        vif.rd_en = 0;
        vif.din = 0;

        uvm_config_db #(
            virtual tb_fifo_if #(DATA_WIDTH)
        )::set(
            null,
            "*",
            "vif",
            vif
        );
       //start uvm
        run_test("tb_fifo_test");
    end


endmodule