LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY apb_protocol_checker IS
    PORT (
        -- APB INterface
        clk             : IN  std_logic;
        rst_n           : IN  std_logic;

        psel            : IN  std_logic;
        penable         : IN  std_logic;
        pwrite          : IN  std_logic;
        pready          : IN  std_logic;
        pslverr         : IN  std_logic;
        paddr           : IN  std_logic_vector(31 DOWNTO 0);
        pwdata          : IN  std_logic_vector(31 DOWNTO 0);
        prdata          : IN  std_logic_vector(31 DOWNTO 0);

        -- Forwarded signals (optional debug output)
        psel_out        : OUT std_logic;
        penable_out     : OUT std_logic;
        pwrite_out      : OUT std_logic;
        pready_out      : OUT  std_logic;
        pslverr_out     : OUT  std_logic;
        paddr_out       : OUT std_logic_vector(31 DOWNTO 0);
        pwdata_out      : OUT std_logic_vector(31 DOWNTO 0);
        prdata_out      : OUT  std_logic_vector(31 DOWNTO 0)

    );
END apb_protocol_checker;

ARCHITECTURE bhv OF apb_protocol_checker IS
    TYPE state_type IS (IDLE, SETUP, ACC);
    SIGNAL current_state : state_type := IDLE;
BEGIN

    -- Immediate signal forwardINg
    psel_out    <= psel;
    penable_out <= penable;
    pwrite_out  <= pwrite;
    pready_out  <= pready;
    pslverr_out <= pslverr;
    paddr_out   <= paddr;
    pwdata_out  <= pwdata;
    prdata_out  <= prdata;

    check_protocol_proc : PROCESS(clk, rst_n)

      VARIABLE write_latch     : STD_LOGIC := '0';
      VARIABLE paddr_latch     : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
      VARIABLE pwdata_latch    : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
      VARIABLE prdata_latch    : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');

      VARIABLE error_flag      : STD_LOGIC := '0';
      VARIABLE using_pready    : STD_LOGIC := '0';

    BEGIN

      IF rst_n = '0' THEN

        current_state  <= IDLE;
        write_latch    := '0';
        paddr_latch    := (OTHERS => '0');
        pwdata_latch   := (OTHERS => '0');
        prdata_latch   := (OTHERS => '0');
        error_flag     := '0';
        using_pready   := '0';

      ELSIF RISING_EDGE(clk) THEN
        
        -- If pready is ever low then pready is used
        IF pready = '0' THEN
          
          using_pready := '1';
          
        ELSE
          NULL;
        
        END IF;

        CASE current_state IS

          WHEN IDLE =>
            
            error_flag      := '0';

            IF psel = '1' AND penable = '0' THEN

              current_state <= SETUP;
              write_latch    := pwrite;
              pwdata_latch   := pwdata;
              paddr_latch    := paddr;
            
            ELSE
              NULL;
            
            END IF;

          WHEN SETUP =>

            current_state <= ACC;

          WHEN ACC =>

            IF using_pready = '1' THEN

              IF pready = '1' THEN

                current_state  <= IDLE;

              ELSE
                NULL;
                
              END IF;
              
            ELSE
            
              IF psel = '1' AND penable = '0' THEN
                
                current_state  <= SETUP;
                write_latch    := pwrite;
                paddr_latch    := paddr;
                pwdata_latch   := pwdata;
                
              ELSIF psel = '0' THEN
                
                current_state  <= IDLE;
                
              ELSE
                NULL;

              END IF;

            END IF;

        END CASE;

        -- Protocol checks
        IF psel = '1' THEN
          

          IF current_state = IDLE AND penable = '1' THEN

            error_flag  := '1';
            ASSERT false REPORT "Penable high during idle phase" SEVERITY ERROR;

          ELSE
            NULL;

          END IF;

          IF current_state = SETUP AND penable = '0' THEN

            error_flag  := '1';
            ASSERT false REPORT "Penable should be high in access phase" SEVERITY ERROR;

          ELSE
            NULL;

          END IF;


          IF current_state = ACC THEN

            IF write_latch /= pwrite THEN

              error_flag  := '1';
              ASSERT FALSE REPORT "Pwrite changed value during access phase" SEVERITY ERROR;
             
            ELSE
              NULL;

            END IF;

            IF pwrite = '1' THEN 

              IF pwdata_latch /= pwdata  THEN

                error_flag  := '1';
               ASSERT FALSE REPORT "Pwdata changed during access phase" SEVERITY ERROR;
               
              ELSE
                NULL;

              END IF;

            ELSE
              NULL;

            END IF;

            IF paddr_latch /= paddr THEN

              error_flag  := '1';
             ASSERT FALSE REPORT "Paddr changed during access phase" SEVERITY ERROR;
             
            ELSE
              NULL;

            END IF;

            IF penable = '0' AND pready = '0' THEN

              error_flag  := '1';
              ASSERT FALSE REPORT "Penable changed during access phase when pready was low" SEVERITY ERROR;

            ELSE
              NULL;

            END IF;

          ELSE
            NULL;

          END IF;

        ELSE
          NULL;

        END IF;

      ELSE
        NULL;

      END IF;

    END PROCESS;

END bhv;
