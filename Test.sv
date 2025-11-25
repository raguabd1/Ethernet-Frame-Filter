`timescale 1ns/1ps

module tb_eth_rx_buffer;

  // DUT Interface Signals
  logic        clk;
  logic        rst_n;

  logic [7:0]  s_tdata;
  logic        s_tvalid;
  logic        s_tlast;
  logic        s_tready;

  logic [7:0]  m_tdata;
  logic        m_tvalid;
  logic        m_tlast;
  logic        m_tready;

  // Clock Generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100MHz clock
  end

  // Instantiate DUT (VHDL)
  eth_rx_buffer dut (
    .clk(clk),
    .rst_n(rst_n),
    .s_tdata(s_tdata),
    .s_tvalid(s_tvalid),
    .s_tready(s_tready),
    .s_tlast(s_tlast),
    .m_tdata(m_tdata),
    .m_tvalid(m_tvalid),
    .m_tready(m_tready),
    .m_tlast(m_tlast)
  );

  // Reset
  initial begin
    rst_n = 0;
    s_tdata = 0;
    s_tvalid = 0;
    s_tlast = 0;
    m_tready = 1;

    #50;
    rst_n = 1;
  end

  // Task to send a byte
  task send_byte(input byte data, input bit last);
  begin
    @(posedge clk);
    s_tdata  <= data;
    s_tvalid <= 1;
    s_tlast  <= last;

    // Wait until DUT ready
    while (!s_tready) @(posedge clk);

//    @(posedge clk);
//    s_tvalid <= 0;
//    s_tlast  <= 0;
  end
  endtask

  // Stimulus
  initial begin
    @(posedge rst_n);

    // ----------------------------
  
    // ----------------------------
    send_byte(8'h11, 0);
    send_byte(8'h22, 0);
    send_byte(8'h33, 0);
    send_byte(8'h44, 0);
    send_byte(8'h55, 0);
    
    //matching destination byte(66, 0C, 0D, 0E, 0F, 10)
    send_byte(8'h66, 0); 
    send_byte(8'h0C, 0);
     send_byte(8'h0D, 0);
      send_byte(8'h0E, 0);
       send_byte(8'h0F, 0); 
       send_byte(8'h10, 0);
       
       //extra frames
    for (int i = 5; i <= 14; i++) begin
      send_byte(i, (i == 14));
      end
      
      //sending extra frames to flushout the buffer
    send_byte(8'h00, 0);
    send_byte(8'h00, 0);
    send_byte(8'h00, 0);
    send_byte(8'h00, 0);
    send_byte(8'h00, 0);
    send_byte(8'h00, 0);
    
    
     send_byte(8'h11, 0);
    send_byte(8'h22, 0);
    send_byte(8'h33, 0);
    send_byte(8'h44, 0);
    send_byte(8'h55, 0);
    send_byte(8'h66, 0);
    
    //matching destination byte(01, 02, 03, 04, 05, 06)
    send_byte(8'h01, 0); 
    send_byte(8'h02, 0);
     send_byte(8'h03, 0);
      send_byte(8'h04, 0);
       send_byte(8'h05, 0); 
       send_byte(8'h06, 0);
       
       //extra frames
    for (int i = 5; i <= 14; i++) begin
      send_byte(i, (i == 14));
      end
      
      //sending extra frames to flushout the buffer
    send_byte(8'h00, 0);
    send_byte(8'h00, 0);
    send_byte(8'h00, 0);
    send_byte(8'h00, 0);
    send_byte(8'h00, 0);
    send_byte(8'h00, 0);


    #200;
    $finish;
  end

  // Monitoring Output
  always @(posedge clk) begin
    if (m_tvalid && m_tready) begin
      $display("TX OUT: data=%h  last=%b  time=%0t", m_tdata, m_tlast, $time);
    end
  end

endmodule
