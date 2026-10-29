class tb_fifo_sequence extends uvm_sequence #(tb_fifo_transaction);
    `uvm_object_utils(tb_fifo_sequence)

    function new(string name = "tb_fifo_sequence");
        super.new(name);
    endfunction

    task send_item(bit rst_n, bit wr_en, bit rd_en, bit [DATA_WIDTH-1:0] din);
        tb_fifo_transaction tr = tb_fifo_transaction::type_id::create("tr");
        start_item(tr);
        tr.rst_n = rst_n;
        tr.wr_en = wr_en;
        tr.rd_en = rd_en;
        tr.din   = din;
        finish_item(tr);
    endtask

    task body();
        // 1. Initial Reset
        repeat (3) send_item(1'b0, 0, 0, '0);
        send_item(1'b1, 0, 0, '0);

        // 2. Corner Case: Reading when empty
        repeat (3) send_item(1'b1, 0, 1, '0);

        // 3. Corner Case: Simultaneous read and write when empty
        send_item(1'b1, 1, 1, 8'hA5);
        send_item(1'b1, 0, 1, '0);

        // 4. (Toggle test)
        send_item(1'b1, 1, 0, 8'h00);
        send_item(1'b1, 1, 0, 8'hFF);
        send_item(1'b1, 1, 0, 8'h55);
        send_item(1'b1, 1, 0, 8'hAA);
        send_item(1'b1, 1, 0, 8'h0F);
        send_item(1'b1, 1, 0, 8'hF0);
        send_item(1'b1, 1, 0, 8'h3C);
        send_item(1'b1, 1, 0, 8'hC3); // FIFO FULL

        // 5. Corner Case: Writing when full
        send_item(1'b1, 1, 0, 8'hDE);

        // 6. Corner Case: Simultaneous read and write when full
        send_item(1'b1, 1, 1, 8'hBE);

        // 7. Corner Case: Simultaneous read and write when not empty
        repeat (20) begin
            send_item(1'b1, 1, 1, $urandom_range(0, 255));
        end

        // 8. Corner Case: Reading and clearing the FIFO
        repeat (DEPTH + 2) send_item(1'b1, 0, 1, '0);

        // 9. Runtime Reset 
        for (int i = 0; i < 4; i++) send_item(1'b1, 1, 0, $urandom);
        send_item(1'b0, 0, 0, '0); // Hạ rst_n: 1 -> 0
        repeat (2) send_item(1'b0, 0, 0, '0);
        send_item(1'b1, 0, 0, '0); // Kéo rst_n: 0 -> 1

        // 10. Random Stress Test 
        repeat (250) begin
            bit rand_wr = $urandom_range(0, 1);
            bit rand_rd = $urandom_range(0, 1);
            bit [DATA_WIDTH-1:0] rand_data = $urandom;
            send_item(1'b1, rand_wr, rand_rd, rand_data);
        end
        repeat (DEPTH + 2) send_item(1'b1, 0, 1, '0);
        repeat (2)         send_item(1'b1, 0, 0, '0);
    endtask
endclass 