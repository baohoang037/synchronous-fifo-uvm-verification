class tb_fifo_transaction extends uvm_sequence_item;

    `uvm_object_utils(tb_fifo_transaction)

    // Input
         bit                  rst_n;
    rand bit                  wr_en;
    rand bit                  rd_en;
    rand bit [DATA_WIDTH-1:0] din;

    // Output
    bit   [DATA_WIDTH-1:0]    dout;
    bit                       full;
    bit                       empty;


    function new(string name = "tb_fifo_transaction");
        super.new(name);
    endfunction

endclass