`timescale 1ns/1ps

import axi_vip_pkg::*;
import design_1_axi_vip_0_0_pkg::*;
import axi_pkg::*;

module tb;

  axi_transaction wr_txn;
  axi_transaction rd_txn;
  logic [31:0] rdata;

  // Clock and Reset
  logic aclk;
  logic aresetn;

  // APB Signals
  logic [31:0] prdata;
  logic        pready;
  logic        pslverr;

  // Simple scoreboard
  typedef struct {
    logic [31:0] addr;
    logic [31:0] expected_data;
  } scoreboard_entry_t;

  scoreboard_entry_t scoreboard[$]; // Dynamic array

  // Instantiate the DUT
  design_1_wrapper DUT (
    .aclk(aclk),
    .aresetn(aresetn),
    .prdata(prdata),
    .pready(pready),
    .pslverr(pslverr)
  );

  // Clock generation
  initial begin
    aclk = 0;
    forever #5 aclk = ~aclk; // 100MHz
  end

  // Reset generation
  initial begin
    aresetn = 0;
    #100;
    aresetn = 1;
  end

  // APB Slave behavior
  initial begin
    pready = 1;
    pslverr = 0;
    prdata = 32'hDEADBEEF;
  end

  // Control tasks
  task automatic axi_write(input [31:0] addr, input [31:0] data);
    design_1_axi_vip_0_0_mst_t my_axi;
    my_axi = new("AXI VIP Master", DUT.design_1_i.axi_vip_0.inst.IF);

    wr_txn = my_axi.wr_txn();
    wr_txn.set_addr(addr);
    wr_txn.set_data(data);
    wr_txn.set_prot(3'b000);
    wr_txn.set_id(0);
    wr_txn.set_user(0);
    wr_txn.set_strb(4'b1111);
    wr_txn.set_burst(BURST_FIXED);
    wr_txn.set_size(SIZE_4BYTE);
    wr_txn.set_len(0);

    my_axi.send(wr_txn);

    $display("AXI WRITE: Addr=0x%08h Data=0x%08h", addr, data);
  endtask

  task automatic axi_read(input [31:0] addr, output [31:0] data);
    design_1_axi_vip_0_0_mst_t my_axi;
    my_axi = new("AXI VIP Master", DUT.design_1_i.axi_vip_0.inst.IF);

    rd_txn = my_axi.rd_txn();
    rd_txn.set_addr(addr);
    rd_txn.set_prot(3'b000);
    rd_txn.set_id(0);
    rd_txn.set_user(0);
    rd_txn.set_burst(BURST_FIXED);
    rd_txn.set_size(SIZE_4BYTE);
    rd_txn.set_len(0);

    my_axi.send(rd_txn);

    data = rd_txn.get_data();
    $display("AXI READ: Addr=0x%08h Data=0x%08h", addr, data);
  endtask

  // Scoreboard check
  task automatic check_scoreboard();
    foreach (scoreboard[i]) begin
      logic [31:0] actual_data;
      axi_read(scoreboard[i].addr, actual_data);

      if (actual_data !== scoreboard[i].expected_data) begin
        $error("SCOREBOARD MISMATCH: Addr=0x%08h Expected=0x%08h Got=0x%08h",
               scoreboard[i].addr, scoreboard[i].expected_data, actual_data);
      end else begin
        $display("SCOREBOARD MATCH: Addr=0x%08h Data=0x%08h OK!",
                 scoreboard[i].addr, actual_data);
      end
    end
  endtask

  // Main test process
  initial begin
    wait(aresetn == 1);

    #100;

    // Write and expect
    axi_write(32'h0000_0004, 32'hCAFEBABE);
    scoreboard.push_back('{addr: 32'h0000_0004, expected_data: 32'hDEADBEEF});

    #100;

    // Check all expected read data
    check_scoreboard();

    #100;
    $finish;
  end

endmodule
