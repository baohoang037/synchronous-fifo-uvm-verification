# ==============================================================================
# Coverage Waiver File for fifo_sync DUT
# ==============================================================================

# Loại trừ điều kiện bất khả thi ở Dòng 59 (Row 3: empty_0 khi rd_en=1)
coverage exclude -instance /tb_fifo_sync/dut -line 59 -code c \
    -comment "Unreachable: In case 2'b10, rd_en=1 and read_ok=0 strictly implies empty=1"

# Loại trừ điều kiện bất khả thi ở Dòng 78 (Row 3: empty_0 khi rd_en=1)
coverage exclude -instance /tb_fifo_sync/dut -line 78 -code c \
    -comment "Unreachable: In default case, rd_en=1 and read_ok=0 strictly implies empty=1"