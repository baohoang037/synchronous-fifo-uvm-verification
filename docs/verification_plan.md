# Verification Plan: Parameterizable Synchronous FIFO

| Document Information | Detail |
| :--- | :--- |
| **Design Under Verification (DUV)** | `fifo_sync` (Synchronous FIFO Core) |
| **Verification Methodology** | Universal Verification Methodology (UVM 1.2) / CRV / SVA |
| **Target Simulator** | Siemens QuestaSim / ModelSim |
| **Document Version** | 1.0.0 |
| **Status** | Approved / Closed |

---

## 1. Overview and Verification Objectives

The primary objective of this project is to implement a robust, production-grade UVM 1.2 constrained-random verification (CRV) environment for a parameterizable Synchronous FIFO (`fifo_sync`).

### Key Goals:
1. **Functional Integrity:** Ensure zero data loss, zero data corruption, and exact first-in, first-out (FIFO) ordering across all operational modes.
2. **Protocol Conformance:** Verify that illegal operations (write-while-full, read-while-empty) are strictly suppressed without state machine or pointer corruption.
3. **Coverage Closure:**
   * **100% Code Coverage:** Statement, Branch, Expression, Condition (with mathematically justified waivers), and Toggle coverage.
   * **100% Functional Coverage:** State coverage, corner-case boundary crossings, and alternating data patterns.
   * **100% Assertion Coverage:** Formal SystemVerilog Assertions (SVA) monitoring bus protocols and internal hardware invariants.

---

## 2. Design Under Verification (DUV) Specification

### 2.1 Parameters

| Parameter | Type | Default | Description |
| :--- | :---: | :---: | :--- |
| `DATA_WIDTH` | `int` | `8` | Bit-width of input data `din` and output data `dout`. |
| `DEPTH` | `int` | `8` | Total storage capacity of the internal memory array. |

---

### 2.2 Signal Interface

| Signal Name | Direction | Width | Clock / Domain | Description |
| :--- | :---: | :---: | :---: | :--- |
| `clk` | Input | `1` | Primary Clock | Master clock source governing all operations. |
| `rst_n` | Input | `1` | Asynchronous/Sync Active-Low | System reset. Clears pointers, occupancy counter, and outputs. |
| `wr_en` | Input | `1` | `clk` (posedge) | Write enable strobe. |
| `rd_en` | Input | `1` | `clk` (posedge) | Read enable strobe. |
| `din` | Input | `DATA_WIDTH` | `clk` (posedge) | Write data bus. |
| `dout` | Output | `DATA_WIDTH` | `clk` (posedge) | Read data bus. Outputs registered data on successful read. |
| `full` | Output | `1` | Combinational | Status flag indicating FIFO capacity is fully utilized (`count == DEPTH`). |
| `empty` | Output | `1` | Combinational | Status flag indicating FIFO contains zero elements (`count == 0`). |

---

### 2.3 Operational Truth Table

Let:
  write_ok = wr_en && !full  = 1 && !1 = 0  --> [Write is REJECTED]
  read_ok  = rd_en && !empty = 1 && !0 = 1  --> [Read is ACCEPTED]

| `rst_n` | `{write_ok, read_ok}` | Hardware Action | Counter Impact | Output `dout` |
| :---: | :---: | :--- | :---: | :--- |
| `0` | `2'bXX` | Pointers and count reset to zero. | `count <= '0` | Cleared to `'0` |
| `1` | `2'b00` | **Idle / Rejected Op:** No memory access. If `rd_en && empty`, read is rejected. | Unchanged | Held or zeroed on empty read |
| `1` | `2'b10` | **Write Only:** `mem[wr_ptr] <= din`, `wr_ptr <= next(wr_ptr)`. | `count <= count + 1` | Unchanged |
| `1` | `2'b01` | **Read Only:** `dout <= mem[rd_ptr]`, `rd_ptr <= next(rd_ptr)`. | `count <= count - 1` | `mem[rd_ptr]` |
| `1` | `2'b11` | **Simultaneous Read & Write:** Data written to `wr_ptr`, data read from `rd_ptr`. | Unchanged | `mem[rd_ptr]` |

---

## 3. Verification Environment Architecture

The verification environment strictly follows the standard UVM component hierarchy.

```
tb_fifo_sync (Top Testbench Module)
 ├── uvm_test_top (tb_fifo_test)
 │    └── env (tb_fifo_env)
 │         ├── agent (tb_fifo_agent - Active)
 │         │    ├── sequencer (tb_fifo_sequencer)
 │         │    ├── driver (tb_fifo_driver)
 │         │    └── monitor (tb_fifo_monitor)
 │         ├── sco (tb_fifo_scoreboard)
 │         └── cov (tb_fifo_coverage)
 ├── vif (tb_fifo_if) [Contains Clocking Blocks & SVA Assertions]
 └── dut (fifo_sync)  [DUT Instance]
```

### 3.1 Timing & Clocking Synchronization Strategy
To prevent zero-time non-blocking race conditions across the simulator:
* **Driver:** Drives all stimulus on the falling edge (`negedge clk`), satisfying setup times prior to the rising edge.
* **DUT:** Samples control inputs and updates internal state registers on the rising edge (`posedge clk`).
* **Monitor:** Observes bus state on `posedge clk` with a discrete delta-delay margin (`#1ps`), guaranteeing stable registered outputs and flags before TLM broadcasting.

### 3.2 Scoreboard Golden Reference Architecture
The scoreboard implements a synchronized reference queue:
$$\text{Queue Model: } \text{logic } [DATA\_WIDTH-1:0] \quad fifo\_model[\$]$$
* **Write Path:** When $write\_ok = 1$, transaction data is pushed back (`push_back(tr.din)`).
* **Read Path:** When $read\_ok = 1$, expected data is popped front (`pop_front()`) and asserted against `tr.dout`.
* **Flag Invariant Checking:** Dynamically cross-checks hardware flags:
  $$empty \iff (fifo\_model.size() == 0)$$
  $$full \iff (fifo\_model.size() == DEPTH)$$
* **Reporting:** Any data mismatch immediately increments an internal `error_count` and throws `uvm_error`. Simulation terminates with fatal exit if critical failures occur.

---

## 4. Test Scenarios & Verification Matrix

| Test ID | Scenario Identifier | Description & Corner Conditions | Expected Hardware Behavior | Pass Criteria |
| :--- | :--- | :--- | :--- | :--- |
| **TC_01** | `POWER_ON_RESET` | Apply reset at simulation initialization; verify clean state. | `wr_ptr=0`, `rd_ptr=0`, `count=0`, `empty=1`, `full=0`, `dout=0`. | Scoreboard reset checks pass. |
| **TC_02** | `UNDERFLOW_GUARD` | Issue multiple consecutive read requests (`rd_en=1`) while `empty=1`. | Read commands rejected; pointers do not advance; `dout` forced to `'0`. | `UVM_INFO [SCO] READ EMPTY PASS`. |
| **TC_03** | `BURST_FILL_FULL` | Issue continuous back-to-back writes until capacity ($DEPTH = 8$) is reached. | `count` increments from $0 \rightarrow 8$; `empty` deasserts; `full` asserts. | `full=1` on $8^{\text{th}}$ write cycle. |
| **TC_04** | `OVERFLOW_GUARD` | Issue write commands (`wr_en=1`) while FIFO is completely full (`full=1`). | Write rejected; memory contents preserved; pointers frozen. | `UVM_INFO [SCO] WRITE REJECTED: FIFO FULL`. |
| **TC_05** | `BURST_DRAIN_EMPTY`| Read continuously until FIFO drains completely. | `count` decrements $8 \rightarrow 0$; all data matches in exact FIFO order. | Zero data mismatches; `empty=1`. |
| **TC_06** | `SIMULTANEOUS_RW` | Drive `wr_en=1` and `rd_en=1` concurrently across variable fill levels ($0 < count < DEPTH$). | Count remains constant; simultaneous write and read complete in parallel. | Both write acceptance and read validity pass. |
| **TC_07** | `FULL_RW_HAZARD` | Issue simultaneous write and read when FIFO is full (`count = DEPTH`). | Write rejected; read allowed; count drops from $DEPTH \rightarrow DEPTH - 1$; `full` clears. | `full` drops to `0`; read data accurate. |
| **TC_08** | `DATA_PATTERNS` | Stream alternating patterns (`0x00`, `0xFF`, `0x55`, `0xAA`, walking 1s/0s). | Full bit-toggle on all data bus pins without stuck-at faults. | 100% Toggle Coverage on `din` and `dout`. |
| **TC_09** | `RUNTIME_RESET` | Assert reset pulse asynchronously during active data stream. | Instant flush of internal pointers and memory counters. | Toggle on `rst_n` ($1 \rightarrow 0 \rightarrow 1$); recovery without lockup. |
| **TC_10** | `CRV_RANDOM_STRESS`| Constrained random transfers with randomized delays and operation mixes. | Long-term stability under heavy randomized traffic. | Final check: $error\_count == 0$. |

---

## 5. SystemVerilog Assertions (SVA) Specification

Assertions are embedded directly inside `tb_fifo_if.sv` to detect hardware protocol violations on every active clock cycle.

| Assertion Label | Property Definition | Verification Intent | Target Action on Fail |
| :--- | :--- | :--- | :--- |
| `SVA_OVERFLOW_CHECK` | `@(posedge clk) disable iff(!rst_n) (full && wr_en && !rd_en) \|=> $stable(dut.wr_ptr)` | Prevents write pointer increment when attempting to write to a full FIFO. | `$error("SVA: Write pointer advanced on full FIFO")` |
| `SVA_UNDERFLOW_CHECK`| `@(posedge clk) disable iff(!rst_n) (empty && rd_en) \|=> (dut.dout == '0)` | Enforces output bus clearance and pointer hold on invalid empty read. | `$error("SVA: Read succeeded on empty FIFO")` |
| `SVA_MUTEX_FLAGS` | `@(posedge clk) disable iff(!rst_n) !(full && empty)` | Proves `full` and `empty` are mutually exclusive for $DEPTH \ge 2$. | `$fatal("SVA: Full and Empty asserted concurrently")` |
| `SVA_RESET_STATE` | `@(negedge rst_n) \|-> (dut.count == '0 && dut.empty == 1'b1 && dut.full == 1'b0)` | Asserts hardware returns to ground state immediately on reset. | `$error("SVA: Reset state incorrect")` |
| `SVA_COUNT_BOUND` | `@(posedge clk) disable iff(!rst_n) (dut.count <= DEPTH)` | Guarantees internal occupancy tracker never exceeds physical storage depth. | `$fatal("SVA: FIFO counter exceeded maximum depth")` |

---

## 6. Functional Coverage Model

The functional coverage model is implemented inside `tb_fifo_coverage` using a dedicated `covergroup fifo_cov` sampled on every valid interface transaction where $rst\_n = 1$.

### 6.1 Coverpoints

```systemverilog
// 1. Control Signals
cp_wr_en : coverpoint tr.wr_en {
    bins wr_active = {1'b1};
    bins wr_idle   = {1'b0};
}

cp_rd_en : coverpoint tr.rd_en {
    bins rd_active = {1'b1};
    bins rd_idle   = {1'b0};
}

// 2. Status Flags
cp_empty : coverpoint tr.empty {
    bins is_empty     = {1'b1};
    bins is_not_empty = {1'b0};
}

cp_full : coverpoint tr.full {
    bins is_full     = {1'b1};
    bins is_not_full = {1'b0};
}

// 3. Data Patterns (Boundary & Walking Patterns)
cp_din : coverpoint tr.din {
    bins all_zeros = {'0};
    bins all_ones  = {'1};
    bins alt_aa    = {8'hAA};
    bins alt_55    = {8'h55};
    bins others    = default;
}
```

### 6.2 Cross Coverage Matrices

* **`cross_wr_full` (`cp_wr_en` $\times$ `cp_full`):** Validates write attempts when FIFO is full (`write_when_full`) versus normal capacity writes (`write_when_not_full`).
* **`cross_rd_empty` (`cp_rd_en` $\times$ `cp_empty`):** Validates read attempts when FIFO is empty (`read_when_empty`) versus populated reads (`read_when_not_empty`).
* **`cross_rw_modes` (`cp_wr_en` $\times$ `cp_rd_en`):** Verifies all 4 quadrant operational states:
  1. `Idle` (`wr=0, rd=0`)
  2. `Write Only` (`wr=1, rd=0`)
  3. `Read Only` (`wr=0, rd=1`)
  4. `Simultaneous Read/Write` (`wr=1, rd=1`)

---

## 7. Code Coverage Targets & Waiver Criteria

### 7.1 Target Metrics

| Coverage Metric | Target | Verification Method |
| :--- | :---: | :--- |
| **Statement Coverage** | **100%** | Full execution of all procedural lines in `fifo_sync.sv`. |
| **Branch Coverage** | **100%** | All `if/else` and `case` paths exercised across both branches. |
| **Condition Coverage** | **100%** | All Boolean input combinations evaluated (with justified waivers). |
| **Expression Coverage** | **100%** | Focused Expression Coverage (FEC) fully covered for compound terms. |
| **Toggle Coverage** | **100%** | All port bits toggle $0 \rightarrow 1$ and $1 \rightarrow 0$ transitions. |

### 7.2 Waiver Justification Policy
Where RTL logic exhibits unreachable condition vectors due to upstream Boolean dependencies, an automated waiver script (`waivers.do`) is applied:
* **Line 59 (`if (rd_en && empty)` in case `2'b10`):** In case `2'b10`, `write_ok = 1` and `read_ok = 0`. By definition, $read\_ok = (rd\_en \ \&\&\ !empty)$. When $rd\_en = 1$, the condition $read\_ok = 0$ mathematically requires $empty = 1$. The state $(rd\_en=1, empty=0)$ cannot occur within this case arm.
* **Line 78 (`if (rd_en && empty)` in `default`):** Under `default` where $read\_ok = 0$, the identical logic applies. Condition $empty = 0$ while $rd\_en = 1$ is unreachable.

---

## 8. Sign-Off & Verification Closure Criteria

The verification cycle is declared **COMPLETE** and production-ready when the following quantitative gates are reached simultaneously:

1. **Simulation Cleanliness:** Zero UVM errors, zero UVM warnings, zero fatal errors (`UVM_ERROR : 0`, `UVM_FATAL : 0`).
2. **Scoreboard Result:** Final test reporting confirms: `[SCO] TEST RESULT: PASS`.
3. **Protocol Checks:** 100% pass rate across all 5 SystemVerilog Assertions without assertion failure logs.
4. **Functional Coverage:** 100.00% coverage across all coverpoints and defined cross bins.
5. **DUT Code Coverage:** 100.00% across Statement, Branch, Expression, Condition, and Toggle coverage models.