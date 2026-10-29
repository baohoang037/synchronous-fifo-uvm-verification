package tb_fifo_sync_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh" 

    parameter int DATA_WIDTH = 8;
    parameter int DEPTH      = 8;

    `include "tb_fifo_transaction.sv"
    `include "tb_fifo_sequence.sv"
    `include "tb_fifo_sequencer.sv"
    `include "tb_fifo_driver.sv"
    `include "tb_fifo_monitor.sv"
    `include "tb_fifo_coverage.sv"
    `include "tb_fifo_scoreboard.sv"
    `include "tb_fifo_agent.sv"
    `include "tb_fifo_env.sv"
    `include "tb_fifo_test.sv"
endpackage