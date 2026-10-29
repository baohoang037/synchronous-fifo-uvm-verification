class tb_fifo_driver extends uvm_driver #(tb_fifo_transaction);
    `uvm_component_utils(tb_fifo_driver)

    virtual tb_fifo_if #(DATA_WIDTH) vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual tb_fifo_if #(DATA_WIDTH))::get(this, "", "vif", vif)) begin
            `uvm_fatal("DRV", "Cannot get virtual interface")
        end
    endfunction

    task run_phase(uvm_phase phase);
        tb_fifo_transaction tr;
        vif.rst_n <= 1'b0;
        vif.wr_en <= 1'b0;
        vif.rd_en <= 1'b0;
        vif.din   <= '0;

        forever begin
            seq_item_port.get_next_item(tr);
            @(negedge vif.clk);
            vif.rst_n <= tr.rst_n;
            vif.wr_en <= tr.wr_en;
            vif.rd_en <= tr.rd_en;
            vif.din   <= tr.din;

            @(posedge vif.clk);
            seq_item_port.item_done();
        end
    endtask
endclass