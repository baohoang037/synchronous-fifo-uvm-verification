class tb_fifo_agent extends uvm_agent;
    `uvm_component_utils(tb_fifo_agent)

    tb_fifo_sequencer seqr;
    tb_fifo_driver    drv;
    tb_fifo_monitor   mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = tb_fifo_monitor::type_id::create("mon", this);
        if (get_is_active() == UVM_ACTIVE) begin
            seqr = tb_fifo_sequencer::type_id::create("seqr", this);
            drv  = tb_fifo_driver::type_id::create("drv", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(seqr.seq_item_export);
        end
    endfunction
endclass