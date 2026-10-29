`timescale 1ns/1ps

interface tb_fifo_if #(
    parameter int DATA_WIDTH = 8
);
    logic                  clk;
    logic                  rst_n;
    logic                  wr_en;
    logic                  rd_en;
    logic [DATA_WIDTH-1:0] din;
    logic [DATA_WIDTH-1:0] dout;
    logic                  full;
    logic                  empty;

    // Clocking block cho Driver
    clocking drv_cb @(posedge clk);
        default input #1ns output #1ns;
        output rst_n, wr_en, rd_en, din;
        input  dout, full, empty;
    endclocking

    // Clocking block cho Monitor
    clocking mon_cb @(posedge clk);
        default input #1step output #0;
        input rst_n, wr_en, rd_en, din, dout, full, empty;
    endclocking

    // ====================================================
    // SYSTEMVERILOG ASSERTIONS (SVA)
    // ====================================================
    // 1. Full and Empty are never synchronized to equal 1.
    property p_mutex_full_empty;
        @(posedge clk) disable iff (!rst_n)
        !(full && empty);
    endproperty
    assert_mutex_full_empty: assert property (p_mutex_full_empty)
        else $error("[SVA FAIL] FIFO cannot be full and empty simultaneously!");

    // 2. When reset is asserted, empty must be 1 and full must be 0 in the next cycle
    property p_reset_flags;
        @(posedge clk)
        !rst_n |=> (empty && !full);
    endproperty
    assert_reset_flags: assert property (p_reset_flags)
        else $error("[SVA FAIL] Reset state failed: empty must be 1, full must be 0");

    // 3. When empty = 1 and there is no write, reading further does not change empty
    property p_empty_read_guard;
        @(posedge clk) disable iff (!rst_n)
        (empty && rd_en && !wr_en) |=> empty;
    endproperty
    assert_empty_read_guard: assert property (p_empty_read_guard)
        else $error("[SVA FAIL] FIFO empty state violated on invalid read!");

    // 4. When full = 1 and there is no read, writing further does not change full
    property p_full_write_guard;
        @(posedge clk) disable iff (!rst_n)
        (full && wr_en && !rd_en) |=> full;
    endproperty
    assert_full_write_guard: assert property (p_full_write_guard)
        else $error("[SVA FAIL] FIFO full state violated on invalid write!");

endinterface