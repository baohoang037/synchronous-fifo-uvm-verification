class tb_fifo_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(tb_fifo_scoreboard)
    uvm_analysis_imp #(
        tb_fifo_transaction,
        tb_fifo_scoreboard
    ) analysis_export;

    bit [DATA_WIDTH-1:0] fifo_model[$];
    int error_count = 0;

    function new(
        string        name,
        uvm_component parent
    );
        super.new(name, parent);

        analysis_export =
            new(
                "analysis_export",
                this
            );

    endfunction

    function void write(
        tb_fifo_transaction tr
    );
        bit read_ok;
        bit write_ok;

        bit [DATA_WIDTH-1:0] expected_dout;

        // ====================================================
        // RESET
        // ====================================================

        if (!tr.rst_n) begin
            fifo_model.delete();
            if (tr.dout !== '0) begin
                `uvm_error(
                    "SCO",
                    "Reset: dout should be 0"
                )

                error_count++;

            end
            if (tr.empty !== 1'b1) begin

                `uvm_error(
                    "SCO",
                    "Reset: empty should be 1"
                )

                error_count++;

            end
            if (tr.full !== 1'b0) begin

                `uvm_error(
                    "SCO",
                    "Reset: full should be 0"
                )

                error_count++;

            end
            return;

        end

        // ====================================================
        // CHECK VALID
        // ====================================================

        read_ok =
            tr.rd_en &&
            (fifo_model.size() > 0);


        write_ok =
            tr.wr_en &&
            (fifo_model.size() < DEPTH);

        // ====================================================
        // READ
        // ====================================================

        if (read_ok) begin

            expected_dout =
                fifo_model.pop_front();


            if (tr.dout !== expected_dout) begin

                `uvm_error(
                    "SCO",
                    $sformatf(
                        "READ FAIL: expected=%h actual=%h",
                        expected_dout,
                        tr.dout
                    )
                )

                error_count++;

            end
            else begin

                `uvm_info(
                    "SCO",
                    $sformatf(
                        "READ PASS: dout=%h",
                        tr.dout
                    ),
                    UVM_LOW
                )

            end

        end

        // Read while empty
        else if (tr.rd_en) begin

            if (tr.dout !== '0) begin

                `uvm_error(
                    "SCO",
                    $sformatf(
                        "READ EMPTY FAIL: dout=%h",
                        tr.dout
                    )
                )

                error_count++;

            end
            else begin

                `uvm_info(
                    "SCO",
                    "READ EMPTY PASS",
                    UVM_LOW
                )

            end

        end

        // ====================================================
        // WRITE
        // ====================================================

        if (write_ok) begin

            fifo_model.push_back(
                tr.din
            );


            `uvm_info(
                "SCO",
                $sformatf(
                    "WRITE: din=%h",
                    tr.din
                ),
                UVM_LOW
            )

        end

        // Write while full
        else if (tr.wr_en) begin

            `uvm_info(
                "SCO",
                "WRITE REJECTED: FIFO FULL",
                UVM_LOW
            )

        end

        // ====================================================
        // CHECK EMPTY FLAG
        // ====================================================

        if (
            tr.empty !==
            (fifo_model.size() == 0)
        ) begin

            `uvm_error(
                "SCO",
                "EMPTY FLAG FAIL"
            )

            error_count++;

        end

        // ====================================================
        // CHECK FULL FLAG
        // ====================================================

        if (
            tr.full !==
            (fifo_model.size() == DEPTH)
        ) begin

            `uvm_error(
                "SCO",
                "FULL FLAG FAIL"
            )

            error_count++;

        end

    endfunction


    function void report_phase(
        uvm_phase phase
    );

        super.report_phase(phase);


        if (error_count == 0) begin

            `uvm_info(
                "SCO",
                "TEST RESULT: PASS",
                UVM_NONE
            )

        end
        else begin

            `uvm_error(
                "SCO",
                $sformatf(
                    "TEST RESULT: FAIL - %0d error(s)",
                    error_count
                )
            )

        end

    endfunction

endclass