# config.mk
#====================================================================================
# CẤU HÌNH DỰ ÁN
#====================================================================================

# Để portable khi giải nén project.
# Nếu muốn, có thể thay bằng absolute path như project cũ.
SRC_DIRS = $(CURDIR)

# Tên module DUT
TOP_MODULE = fifo_sync

# Tên module testbench top-level
TB_NAME = tb_fifo_sync


#====================================================================================
# CẤU HÌNH QUESTA + UVM 1.2
#====================================================================================

QUESTA_HOME = /usr/local/questasim/questasim
UVM_HOME = $(QUESTA_HOME)/verilog_src/uvm-1.2
UVM_LIB = $(QUESTA_HOME)/uvm-1.2
UVM_LIB_NAME = uvm
