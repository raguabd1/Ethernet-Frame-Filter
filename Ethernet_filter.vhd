----------------------------------------------------------------------------------
-- Company: Dexcel Electronics Designs.
-- Engineer: Raghavendra Mahalatkar B S
-- 
-- Create Date: 20.11.2025 12:06:00
-- Design Name: 
-- Module Name: Eth_buff - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

--Features Supported

--If incoming s_tlast arrives at capture state it will be considered as invalied frame.
--If s_tlast arrived at input, make s_tready=0 keep it till idle state till full frame gets transfered.
--Transition from send state to idle state happen only after transfering full incoming frame is finished.


----------------------------------------------------------------------------------
-- Company: Dexcel Electronics Designs.
-- Engineer: Raghavendra Mahalatkar B S
-- 
-- Create Date: 20.11.2025 12:06:00
-- Design Name: 
-- Module Name: Eth_buff - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

--Features Supported

--If incoming s_tlast arrives at capture state it will be considered as invalied frame.
--If s_tlast arrived at input, make s_tready=0 keep it till idle state till full frame gets transfered.
--Transition from send state to idle state happen only after transfering full incoming frame is finished.


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity eth_rx_buffer is
  port (
    clk       : in  std_logic;
    rst_n     : in  std_logic;

    -- AXI Stream Input (from MAC RX)
    s_tdata   : in  std_logic_vector(7 downto 0);
    s_tvalid  : in  std_logic;
    s_tready  : out std_logic;
    s_tlast   : in  std_logic;

    -- AXI Stream Output
    m_tdata   : out std_logic_vector(7 downto 0);
    m_tvalid  : out std_logic;
    m_tready  : in  std_logic;
    m_tlast   : out std_logic
  );
end eth_rx_buffer;

architecture rtl of eth_rx_buffer is
 signal test1 : std_logic_vector(3 downto 0):="1101";
  --defining states
  type state_t is (IDLE, CAPTURE, COMPARE, SEND);
  signal state : state_t := IDLE;

  -- Simple buffer RAM (12 locations, 9 bits (last + Data each))
  type buf_t is array(0 to 12) of std_logic_vector(8 downto 0); 
  signal buffer1 : buf_t;

  
  

  --pointers for memory location while storing
  signal ptr : integer range 0 to 15 := 0;

  -- Output registers
  signal m_tvalid_r : std_logic := '0';
  
  --variable to keep s_tready=0 till idle state after s_tlast came=1 occur
  signal flag : std_logic;


begin

--continuous assignments
  m_tdata  <= buffer1(0)(7 downto 0);
  m_tvalid <= m_tvalid_r;
  m_tlast  <= buffer1(0)(8);

  ------------------------------------------------------------------------
  -- Main FSM
  ------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then

      if rst_n = '0' then
        state      <= IDLE;
        ptr<=0;
        s_tready   <= '0';
        m_tvalid_r <= '0';
        buffer1(0)(8)  <= '0';
      else
        -- Default outputs
        m_tvalid_r <= '0';
--        m_tlast_r  <= '0';
        
        buffer1(0)(8)<='0';

        case state is

          --------------------------------------------------------------
          -- WAIT FOR START OF FRAME
          --------------------------------------------------------------
          when IDLE =>
            s_tready <= '1'; --get ready to accept the incoming bytes
            if s_tvalid = '1' then
              buffer1(0) <= s_tlast & s_tdata; --incoming data is buffered first time in capture state.
              ptr <= 1;
              state <= CAPTURE;
              if s_tlast = '1' then
                state<= IDLE;
              end if;
            end if;

          --------------------------------------------------------------
          -- CAPTURE ALL BYTES UNTIL EXPECTED FRAME SIZE
          --------------------------------------------------------------
          when CAPTURE => --Here FSM can either remain in capture state till all 12 bytes received.
            s_tready <= '1'; --assert for continuous capture
            if s_tvalid = '1' then
              buffer1(ptr) <= s_tlast & s_tdata;
              ptr <= ptr + 1;
              if ptr = 11 then --Frame has reached the end of the line.
                ptr <= 0;
                state <= COMPARE;
              end if;
              --if last byte received before first 12 bytes=>invalid frame, make s_tready <= '0';.
              if (s_tlast='1')  then
                state <= IDLE;
                s_tready <= '0'; 
              end if;
            end if;
            
             

        when COMPARE =>
        s_tready <= '1';
        buffer1(12)<=s_tlast & s_tdata;
        flag<='0';
         if ((buffer1(6) = '0' & x"66" and buffer1(7)= '0' & x"0C" and buffer1(8) = '0' & x"0d" and buffer1(9)='0' & x"0E" and buffer1(10) = '0' & x"0F" and buffer1(11)= '0' & x"10") or 
            (buffer1(6) = '0' & x"01" and buffer1(7)= '0' & x"02" and buffer1(8) = '0' & x"03" and buffer1(9)='0' & x"04" and buffer1(10) = '0' & x"05" and buffer1(11)= '0' & x"06") or 
            (buffer1(6) = '0' & x"05" and buffer1(7)= '0' & x"06" and buffer1(8) = '0' & x"07" and buffer1(9)='0' & x"08" and buffer1(10) = '0' & x"09" and buffer1(11)= '0' & x"0a") or 
            (buffer1(6) = '0' & x"07" and buffer1(7)= '0' & x"08" and buffer1(8) = '0' & x"09" and buffer1(9)='0' & x"0a" and buffer1(10) = '0' & x"0b" and buffer1(11)= '0' & x"0c") or 
            (buffer1(6) = '0' & x"0a" and buffer1(7)= '0' & x"0b" and buffer1(8) = '0' & x"0c" and buffer1(9)='0' & x"0d" and buffer1(10) = '0' & x"0e" and buffer1(11)= '0' & x"0f")) then
            s_tready    <= '1'; --ready to receive next byte at input while send state
            state       <= SEND;
            m_tvalid_r<='1';
         else 
            state <= IDLE;
            s_tready <= '0';
         end if;
          --------------------------------------------------------------
          -- SEND OUT BUFFERED FRAME
          --------------------------------------------------------------
          when SEND =>
            s_tready <= '1'; 
            m_tvalid_r<='0';
            --when the last byte of the packet received, FSM should not receive furthur frames till idle state
            if s_tlast= '1' or flag= '1' then
                s_tready <= '0';
                flag<='1';
            end if;
                
            if m_tready = '1' then
               m_tvalid_r <= '1';
            --store the incoming data.
               buffer1(12)<=s_tlast & s_tdata;
               buffer1(11)<= buffer1(12);
               buffer1(10)<=buffer1(11);
                buffer1(9)  <= buffer1(10);
                buffer1(8)  <= buffer1(9);
                buffer1(7)  <= buffer1(8);
                buffer1(6)  <= buffer1(7);
                buffer1(5)  <= buffer1(6);
                buffer1(4)  <= buffer1(5);
                buffer1(3)  <= buffer1(4);
                buffer1(2)  <= buffer1(3);
                buffer1(1)  <= buffer1(2);
                buffer1(0)  <= buffer1(1);
                
                

                if buffer1(0)(8)='1' then --last byte arrived 
                  state <= IDLE;
                  m_tvalid_r <= '0';
                end if;
            
            elsif m_tready = '0' then
              s_tready <= '0'; --Back pressure the master port.
              end if; --  for m_tready

        end case;
      end if;
    end if;
  end process;
end rtl;
 

 

