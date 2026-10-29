class tb_fifo_monitor extends uvm_monitor;
    `uvm_component_utils(tb_fifo_monitor)

    virtual tb_fifo_if #(DATA_WIDTH) vif;
    uvm_analysis_port #(tb_fifo_transaction) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual tb_fifo_if #(DATA_WIDTH))::get(this, "", "vif", vif)) begin
            `uvm_fatal("MON", "Cannot get virtual interface")
        end
    endfunction

    task run_phase(uvm_phase phase);
        tb_fifo_transaction tr;
        forever begin
            @(posedge vif.clk);
            #1ps; // Waiting for DUT to update the output
            tr = tb_fifo_transaction::type_id::create("tr");
            tr.rst_n = vif.rst_n;
            tr.wr_en = vif.wr_en;
            tr.rd_en = vif.rd_en;
            tr.din   = vif.din;
            tr.dout  = vif.dout;
            tr.full  = vif.full;
            tr.empty = vif.empty;
            ap.write(tr);
        end
    endtask
endclass