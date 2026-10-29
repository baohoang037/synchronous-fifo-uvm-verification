##################################################################################################
# Makefile mô phỏng SystemVerilog/UVM với QuestaSim
# Project: FIFO Sync UVM
##################################################################################################

SHELL := /bin/bash

#====================================================================================
# NẠP FILE CẤU HÌNH
#====================================================================================

ifeq ($(wildcard config.mk),)
$(error "Lỗi: Không tìm thấy file 'config.mk'. Vui lòng tạo file này và định nghĩa các biến cần thiết.")
endif

include config.mk

#====================================================================================
# BIẾN MÔI TRƯỜNG
#====================================================================================

PROJ_ROOT     = $(SRC_DIRS)

RTL_DIR       = $(PROJ_ROOT)/rtl
TB_DIR        = $(PROJ_ROOT)/tb
SIM_DIR       = $(PROJ_ROOT)/sim

TB_MODULE     ?= $(TB_NAME)
RADIX         ?= bin
COMPILE_FILE  = $(PROJ_ROOT)/compile.f

#====================================================================================
# CẤU HÌNH UVM
#====================================================================================

UVM_INC       = $(UVM_HOME)/src
UVM_VLOG_OPT  = -L $(UVM_LIB_NAME) +incdir+$(UVM_INC)
UVM_VSIM_OPT  = -L $(UVM_LIB_NAME)

DPI_GCC       = /usr/bin/gcc

#====================================================================================
# CÁC TARGET
#====================================================================================

.PHONY: \
    all \
    all_wave \
    all_mem \
    all_cov \
    build \
    build_cov \
    run \
    run_cov \
    wave \
    mem \
    gen_cov \
    gen_html \
    clean \
    help \
    init \
    check_uvm

#====================================================================================
# KIỂM TRA UVM
#====================================================================================

check_uvm:
	@echo "============================================================"
	@echo "Kiểm tra môi trường UVM 1.2"
	@echo "============================================================"
	@test -f "$(UVM_INC)/uvm_pkg.sv" || \
		(echo "Lỗi: Không tìm thấy $(UVM_INC)/uvm_pkg.sv"; exit 1)
	@test -f "$(UVM_INC)/uvm_macros.svh" || \
		(echo "Lỗi: Không tìm thấy $(UVM_INC)/uvm_macros.svh"; exit 1)
	@test -d "$(UVM_LIB)" || \
		(echo "Lỗi: Không tìm thấy UVM library: $(UVM_LIB)"; exit 1)
	@echo "UVM source : $(UVM_INC)"
	@echo "UVM library: $(UVM_LIB)"
	@echo "UVM 1.2 OK"
	@echo "============================================================"

#====================================================================================
# KHỞI TẠO CÂY THƯ MỤC
#====================================================================================

init:
	@echo "============================================================"
	@echo "Bắt đầu khởi tạo cây thư mục tại: $(PROJ_ROOT)"
	@echo "============================================================"
	@mkdir -p $(RTL_DIR) $(TB_DIR) $(SIM_DIR)
	@echo "Đã tạo các thư mục:"
	@echo "  rtl"
	@echo "  tb"
	@echo "  sim"
	@echo "Đang di chuyển các file mã nguồn..."
	@bash -c ' \
		for f in $(wildcard $(PROJ_ROOT)/*.v $(PROJ_ROOT)/*.sv); do \
			filename=$$(basename $$f); \
			if [[ "$$filename" == tb_* ]]; then \
				mv $$f $(TB_DIR)/; \
				echo "   -> $$filename -> $(TB_DIR)"; \
			else \
				mv $$f $(RTL_DIR)/; \
				echo "   -> $$filename -> $(RTL_DIR)"; \
			fi; \
		done \
	'
	@echo "Đang tạo compile.f ..."
	@( \
		echo "// --- RTL Files ---"; \
		find $(RTL_DIR) -type f \( -name "*.v" -o -name "*.sv" \); \
		echo ""; \
		echo "// --- Testbench top-level compilation units ---"; \
		echo "$(TB_DIR)/tb_fifo_if.sv"; \
		echo "$(TB_DIR)/tb_fifo_sync_pkg.sv"; \
		echo "$(TB_DIR)/$(TB_NAME).sv"; \
	) > $(COMPILE_FILE)
	@echo "Đã tạo file: $(COMPILE_FILE)"
	@echo "============================================================"
	@echo "Khởi tạo project hoàn tất."
	@echo "============================================================"

#====================================================================================
# FLOW CHÍNH
#====================================================================================

all: build run

all_wave: build run wave

all_mem: build run mem

all_cov: build_cov run_cov

#====================================================================================
# BUILD
#====================================================================================

build: check_uvm
	@mkdir -p $(SIM_DIR)/log
	@echo "============================================================"
	@echo " BUILD"
	@echo "Top module: $(TB_MODULE)"
	@echo "============================================================"

	# Xóa work cũ để tránh chạy nhầm compiled design cũ
	rm -rf $(SIM_DIR)/work

	# Tạo work library
	cd $(SIM_DIR) && vlib work

	# Map work library
	cd $(SIM_DIR) && vmap work work

	# Map UVM 1.2 precompiled library
	cd $(SIM_DIR) && vmap $(UVM_LIB_NAME) $(UVM_LIB)

	# Compile theo thứ tự: RTL -> interface -> UVM package -> top
	cd $(SIM_DIR) && \
	set -o pipefail; \
	vlog \
		-sv \
		$(UVM_VLOG_OPT) \
		+incdir+../rtl \
		+incdir+../tb \
		../rtl/$(TOP_MODULE).sv \
		../tb/tb_fifo_if.sv \
		../tb/tb_fifo_sync_pkg.sv \
		../tb/$(TB_NAME).sv \
		2>&1 | tee log/compile.log

	@echo "============================================================"
	@echo "Biên dịch hoàn tất"
	@echo "Log: $(SIM_DIR)/log/compile.log"
	@echo "============================================================"

#====================================================================================
# BUILD COVERAGE
#====================================================================================

build_cov: check_uvm
	@mkdir -p $(SIM_DIR)/log
	@echo "============================================================"
	@echo " BUILD WITH COVERAGE (DUT scoped)"
	@echo "============================================================"
	rm -rf $(SIM_DIR)/work
	cd $(SIM_DIR) && vlib work
	cd $(SIM_DIR) && vmap work work
	cd $(SIM_DIR) && vmap $(UVM_LIB_NAME) $(UVM_LIB)

	# Biên dịch RTL có coverage
	cd $(SIM_DIR) && vlog -sv +cover=bcesft +incdir+../rtl ../rtl/$(TOP_MODULE).sv 2>&1 | tee log/compile_rtl.log

	# Biên dịch TB và UVM KHÔNG bật code coverage
	cd $(SIM_DIR) && vlog -sv $(UVM_VLOG_OPT) +incdir+../tb ../tb/tb_fifo_if.sv ../tb/tb_fifo_sync_pkg.sv ../tb/$(TB_NAME).sv 2>&1 | tee -a log/compile.log

	@echo "============================================================"
	@echo "Biên dịch coverage hoàn tất"
	@echo "============================================================"

#====================================================================================
# RUN
#====================================================================================

run:
	@echo "============================================================"
	@echo " RUN SIMULATION"
	@echo "Top module: $(TB_MODULE)"
	@echo "============================================================"

	cd $(SIM_DIR) && \
	vsim \
		$(UVM_VSIM_OPT) \
		+UVM_NO_RELNOTES \
		-dpicpppath $(DPI_GCC) \
		-debugDB \
		-l sim.log \
		-voptargs="+acc" \
		-assertdebug \
		-c $(TB_MODULE) \
		-do "log -r /*; run -all; quit"

	@echo "============================================================"
	@echo "Mô phỏng hoàn tất"
	@echo "Log: $(SIM_DIR)/sim.log"
	@echo "============================================================"

#====================================================================================
# RUN COVERAGE
#====================================================================================

run_cov:
	cd $(SIM_DIR) && \
	vsim \
		$(UVM_VSIM_OPT) \
		-dpicpppath $(DPI_GCC) \
		-coverage \
		-l sim.log \
		-c $(TB_MODULE) \
		-voptargs="+cover=bcesft" \
		-assertdebug \
		-do "coverage save -onexit coverage.ucdb; log -r /*; run -all; quit"

	@echo "============================================================"
	@echo "Coverage database:"
	@echo "$(SIM_DIR)/coverage.ucdb"
	@echo "============================================================"

#====================================================================================
# MEMORY VIEW
#====================================================================================

mem:
	@echo "============================================================"
	@echo " LIVE MEMORY SIMULATION"
	@echo "============================================================"

	cd $(SIM_DIR) && \
	vsim \
		$(UVM_VSIM_OPT) \
		+UVM_NO_RELNOTES \
		-dpicpppath $(DPI_GCC) \
		-gui \
		-voptargs="+acc" \
		-assertdebug \
		$(TB_MODULE) \
		-do "view memory; add wave -r /*; run -all"

#====================================================================================
# WAVEFORM
#====================================================================================

wave:
	@echo "============================================================"
	@echo " OPEN WAVEFORM"
	@echo "============================================================"

	cd $(SIM_DIR) && \
	vsim \
		-i \
		-view vsim.wlf \
		-do "add wave -r /*; radix -$(RADIX)" &

#====================================================================================
# COVERAGE REPORT - TEXT
#====================================================================================

gen_cov:
	@echo "============================================================"
	@echo " GENERATE COVERAGE REPORT (WITH WAIVERS)"
	@echo "============================================================"

	@mkdir -p $(SIM_DIR)/coverage

	# 1. Gom database coverage
	cd $(SIM_DIR) && vcover merge coverage/IP.ucdb coverage.ucdb

	# 2. Áp dụng waiver từ thư mục gốc vào database
	cd $(SIM_DIR) && vsim -c -viewcov coverage/IP.ucdb -do "do ../waivers.do; coverage save coverage/IP.ucdb; quit -f"

	# 3. Xuất báo cáo tổng thể
	cd $(SIM_DIR) && \
	vcover report \
		coverage/IP.ucdb \
		-output coverage/summary_report.txt

	# 4. Xuất báo cáo chi tiết toàn bộ project
	cd $(SIM_DIR) && \
	vcover report \
		-zeros \
		-details \
		-code bcesft \
		-annotate \
		-all \
		-codeAll \
		coverage/IP.ucdb \
		-output coverage/detail_report.txt

	# 5. Xuất báo cáo chi tiết riêng cho DUT
	cd $(SIM_DIR) && \
	vcover report \
		-instance=/tb_fifo_sync/dut \
		-all \
		-details \
		-code bcesft \
		-annotate \
		coverage/IP.ucdb \
		-output coverage/dut_details.txt

	@echo "============================================================"
	@echo "Báo cáo chi tiết DUT: $(SIM_DIR)/coverage/dut_details.txt"
	@echo "============================================================"

#====================================================================================
# COVERAGE REPORT - HTML
#====================================================================================

gen_html:
	@mkdir -p $(SIM_DIR)/coverage
	cd $(SIM_DIR) && \
	vcover report \
		-zeros \
		-details \
		-code bcesft \
		-annotate \
		-testhitdataAll \
		-html \
		coverage/IP.ucdb
	@echo "HTML report: $(SIM_DIR)/coverage/covhtmlreport/index.html"

#====================================================================================
# CLEAN
#====================================================================================

clean:
	@echo "============================================================"
	@echo " CLEAN"
	@echo "============================================================"

	rm -rf $(SIM_DIR)

	@echo "Đã dọn dẹp thư mục mô phỏng."

#====================================================================================
# HELP
#====================================================================================

help:
	@echo ""
	@echo "********************************************************************"
	@echo "** HƯỚNG DẪN SỬ DỤNG MAKEFILE                                     **"
	@echo "********************************************************************"
	@echo "**"
	@echo "** make init"
	@echo "**   Khởi tạo cây thư mục và compile.f"
	@echo "**"
	@echo "** make check_uvm"
	@echo "**   Kiểm tra source và library UVM 1.2"
	@echo "**"
	@echo "** make build"
	@echo "**   Compile RTL + interface + UVM package + top"
	@echo "**"
	@echo "** make run"
	@echo "**   Chạy simulation"
	@echo "**"
	@echo "** make all"
	@echo "**   build + run"
	@echo "**"
	@echo "** make all_wave"
	@echo "**   build + run + waveform"
	@echo "**"
	@echo "** make all_mem"
	@echo "**   build + run + memory view"
	@echo "**"
	@echo "** make build_cov"
	@echo "**   Compile với code coverage"
	@echo "**"
	@echo "** make run_cov"
	@echo "**   Simulation + lưu coverage.ucdb"
	@echo "**"
	@echo "** make all_cov"
	@echo "**   build_cov + run_cov"
	@echo "**"
	@echo "** make gen_cov"
	@echo "**   Xuất coverage dạng text"
	@echo "**"
	@echo "** make gen_html"
	@echo "**   Xuất coverage dạng HTML"
	@echo "**"
	@echo "** make wave"
	@echo "**   Mở waveform"
	@echo "**"
	@echo "** make clean"
	@echo "**   Xóa thư mục simulation"
	@echo "**"
	@echo "********************************************************************"
	@echo ""
