class tb_fifo_test extends uvm_test;
    `uvm_component_utils(tb_fifo_test)
    tb_fifo_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = tb_fifo_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        tb_fifo_sequence seq;
        phase.raise_objection(this);
        seq = tb_fifo_sequence::type_id::create("seq");
        seq.start(env.agent.seqr);
        #100ns;
        phase.drop_objection(this);
    endtask
endclass