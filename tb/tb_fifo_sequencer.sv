class tb_fifo_sequencer
extends uvm_sequencer #(tb_fifo_transaction);

    `uvm_component_utils(tb_fifo_sequencer)


    function new(
        string        name,
        uvm_component parent
    );

        super.new(name, parent);

    endfunction
endclass