class tb_fifo_coverage extends uvm_subscriber #(tb_fifo_transaction);
    `uvm_component_utils(tb_fifo_coverage)

    tb_fifo_transaction tr;

    covergroup fifo_cov;
        option.per_instance = 1;

        cp_wr_en: coverpoint tr.wr_en {
            bins wr_active = {1'b1};
            bins wr_idle   = {1'b0};
        }

        cp_rd_en: coverpoint tr.rd_en {
            bins rd_active = {1'b1};
            bins rd_idle   = {1'b0};
        }

        cp_empty: coverpoint tr.empty {
            bins is_empty     = {1'b1};
            bins is_not_empty = {1'b0};
        }

        cp_full: coverpoint tr.full {
            bins is_full     = {1'b1};
            bins is_not_full = {1'b0};
        }

        cp_din: coverpoint tr.din {
            bins all_zeros = {'0};
            bins all_ones  = {'1};
            bins alt_aa    = {8'hAA};
            bins alt_55    = {8'h55};
            bins others    = default;
        }

        cross_wr_full: cross cp_wr_en, cp_full {
            bins write_when_full     = binsof(cp_wr_en.wr_active) && binsof(cp_full.is_full);
            bins write_when_not_full = binsof(cp_wr_en.wr_active) && binsof(cp_full.is_not_full);
            ignore_bins wr_idle      = binsof(cp_wr_en.wr_idle);
        }

        cross_rd_empty: cross cp_rd_en, cp_empty {
            bins read_when_empty     = binsof(cp_rd_en.rd_active) && binsof(cp_empty.is_empty);
            bins read_when_not_empty = binsof(cp_rd_en.rd_active) && binsof(cp_empty.is_not_empty);
            ignore_bins rd_idle      = binsof(cp_rd_en.rd_idle);
        }

        cross_rw_modes: cross cp_wr_en, cp_rd_en;

    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        fifo_cov = new();
    endfunction

    function void write(tb_fifo_transaction t);
        this.tr = t;
        if (tr.rst_n) begin
            fifo_cov.sample();
        end
    endfunction
endclass