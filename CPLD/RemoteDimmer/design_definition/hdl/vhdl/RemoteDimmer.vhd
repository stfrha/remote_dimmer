-----------------------------------------------------
-- Remote Dimmer
--
-- Klockfrekvens: 2 kHz
--
-----------------------------------------------------



package GEN_PACK is
    constant    MAX_FADE_COUNTER : integer := 42;
	constant    FADE_COUNTER_BITLEN : integer := 6;
end package;









----------------------------------------------
-- Följande entity är tillståndsmaskin för
-- dimmern
--------------------------------------------

package DF_PACK is
    TYPE DF_ST_TYPE is (ALL_ON, FADING_DOWN, FADING_UP, ALL_OFF);
end package;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.DF_PACK.all;

entity DIMMER_FSM is
	port (
        CLK             :   in std_logic;
		RESET           :   in std_logic;
		CM_FADE_UP      :   in std_logic;
		CM_FADE_DOWN    :   in std_logic;
		CM_PANIC_ON     :   in std_logic;
		COUNTER_TOP     :   in std_logic;
		COUNTER_BOTTOM  :   in std_logic;
		COUNT_UP        :   out std_logic;
		COUNT_SET       :   out std_logic;
		COUNT_ENABLE    :   out std_logic
	);
end entity;

architecture BEHAVIOUR of DIMMER_FSM is
    signal CURRENT_STATE : DF_ST_TYPE;
    signal NEXT_STATE : DF_ST_TYPE;
begin
    NXT_STATE : process(CURRENT_STATE, CM_FADE_UP, CM_FADE_DOWN, CM_PANIC_ON, COUNTER_TOP, COUNTER_BOTTOM)
	begin
	    COUNT_UP <= '0';
		COUNT_SET <= '0';
		COUNT_ENABLE <= '0';
	    case CURRENT_STATE is
		when ALL_ON =>
    		COUNT_SET <= '1';
		    if (CM_FADE_DOWN = '1') then
		        NEXT_sTATE <= FADING_DOWN;
			else
			    NEXT_STATE <= ALL_ON;
			end if;
		when FADING_DOWN =>
    	    COUNT_UP <= '0';
    		COUNT_ENABLE <= '1';
		    if (CM_PANIC_ON = '1') then
		        NEXT_STATE <= ALL_ON;
			elsif (COUNTER_BOTTOM = '1') then
			    NEXT_STATE <= ALL_OFF;
			elsif (CM_FADE_UP = '1') then
			    NEXT_STATE <= FADING_UP;
			else
			    NEXT_STATE <= FADING_DOWN;
			end if;
		when FADING_UP =>
    	    COUNT_UP <= '1';
    		COUNT_ENABLE <= '1';
		    if ((CM_PANIC_ON = '1') or (COUNTER_TOP = '1')) then
		        NEXT_STATE <= ALL_ON;
			elsif (CM_FADE_DOWN = '1') then
			    NEXT_STATE <= FADING_DOWN;
			else
			    NEXT_STATE <= FADING_UP;
			end if;
		when ALL_OFF =>
		    if (CM_PANIC_ON = '1') then
		        NEXT_STATE <= ALL_ON;
			elsif (CM_FADE_UP = '1') then
			    NEXT_STATE <= FADING_UP;
			else
			    NEXT_STATE <= ALL_OFF;
			end if;
		end case;
	end process;
	
	STATE_SYNC : process(CLK, RESET)
	begin
	    if (RESET = '1') then
	        CURRENT_STATE <= ALL_ON;
		elsif (rising_edge(CLK)) then
		    CURRENT_STATE <= NEXT_STATE;
		end if;
	end process;
	
end architecture;
		






----------------------------------------------
-- Följande entity är räknare för upp- och nedfadning
--------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.GEN_PACK.all;

entity FADE_COUNTER is
    port (
        CLK             :   in std_logic;
		COUNT_UP        :   in std_logic;
		COUNT_SET       :   in std_logic;
		COUNT_ENABLE    :   in std_logic;
		COUNTER_TOP     :   out std_logic;
		COUNTER_BOTTOM  :   out std_logic;
		LIGHT_VALUE     :   out unsigned(FADE_COUNTER_BITLEN-1 downto 0)
	);
end entity;

architecture BEHAVIOUR of FADE_COUNTER is
    signal  CNT : unsigned(13 downto 0);
begin
    process(CLK, COUNT_SET)
	begin
	    if (COUNT_SET = '1') then
	        CNT <= to_unsigned(10752, 14); --(others => '1');
		elsif (rising_edge(CLK)) then
		    if (COUNT_ENABLE = '1') then
		        if (COUNT_UP = '1') then
		            if (CNT(13 downto 13 - FADE_COUNTER_BITLEN + 1) < MAX_FADE_COUNTER) then
		                CNT <= CNT + 1;
					end if;
				else
				    if (cnt > 0) then
				        CNT <= CNT - 1;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	LIGHT_VALUE <= CNT(13 downto 13 - FADE_COUNTER_BITLEN + 1);
	COUNTER_TOP <= '1' when CNT(13 downto 13 - FADE_COUNTER_BITLEN + 1) = MAX_FADE_COUNTER else '0';
	COUNTER_BOTTOM <= '1' when CNT = 0 else '0';
end architecture;


		                






----------------------------------------------
-- Följande entity är triacdrivaren
--------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.GEN_PACK.all;


entity  TRIAC_DRIVER is
    port (
	    CLK             :   in std_logic;
		RESET           :   in std_logic;
		ZERO_DETECT     :   in std_logic;
		LIGHT_VALUE     :   in unsigned(FADE_COUNTER_BITLEN-1 downto 0);
		TRIAC_TRIG      :   out std_logic
	);
end entity;

architecture BEHAVIOUR of TRIAC_DRIVER is
    signal  CNT : unsigned(FADE_COUNTER_BITLEN-1 downto 0);
begin
    TRIG_CNT : process(CLK, RESET, ZERO_DETECT)
	begin
	    if ((RESET = '1') or (ZERO_DETECT = '1')) then
	        CNT <= to_unsigned(MAX_FADE_COUNTER, 6);
		elsif (rising_edge(CLK)) then
		    CNT <= CNT - 1;
		end if;
	end process;

    TRIAC_TRIG <= '1' when CNT <= LIGHT_VALUE else '0';

end architecture;
		    
	    
		
    








----------------------------------------------
-- Följande entity är kommando- och address-
-- avkodaren
--------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RC_DECODE is
    port (
        CLK             :   in std_logic;
		RESET           :   in std_logic;
		RC_ADDRESS      :   in std_logic_vector(3 downto 0);
		RXD             :   in std_logic_vector(7 downto 0);
		RXD_READY       :   in std_logic;
		RXD_ACK         :   out std_logic;
		CM_FADE_DOWN    :   out std_logic;
		CM_FADE_UP      :   out std_logic;
		CM_PANIC_ON     :   out std_logic
	);
end entity;

architecture BEHAVIOUR of RC_DECODE is
    signal I_RXD_ACK    : std_logic;
begin
    process(CLK, RESET)
	begin
	    if (RESET = '1') then
            I_RXD_ACK <= '0';
            CM_FADE_DOWN <= '0';
			CM_FADE_UP <= '0';
			CM_PANIC_ON <= '0';
	    elsif rising_edge(CLK) then
		    if (I_RXD_ACK = '1') then
		        if (RXD_READY = '0') then
		            I_RXD_ACK <= '0';
				end if;
			elsif (RXD_READY = '1') then
		        if (RC_ADDRESS = RXD(7 downto 4)) then
		            if (RXD(3 downto 0) = "0001") then
		                CM_FADE_DOWN <= '1';
						CM_FADE_UP <= '0';
						CM_PANIC_ON <= '0';
					elsif (RXD(3 downto 0) = "0010") then
		                CM_FADE_DOWN <= '0';
						CM_FADE_UP <= '1';
						CM_PANIC_ON <= '0';
					elsif (RXD(3 downto 0) = "1000") then
		                CM_FADE_DOWN <= '0';
						CM_FADE_UP <= '0';
						CM_PANIC_ON <= '1';
					end if;
				end if;
				
				I_RXD_ACK <= '1';

			end if;
		end if;
	end process;
	
	RXD_ACK <= I_RXD_ACK;
	
end architecture;






----------------------------------------------
-- Följande tre entities bygger en UAR (inte 
-- UART) som den heter. 
--------------------------------------------

package BM_PACK is
    TYPE BM_ST_TYPE is (IDLE, S1, S2, S3, BLANK);
end package;



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.BM_PACK.all;

entity BIT_MEASURE is
    port (
        CLK             :   in std_logic;
		RESET           :   in std_logic;
		DATA_IN         :   in std_logic;
		CYCLE_MEASURE   :   in std_logic;
		DONE            :   out std_logic;
		BM_DATA         :   out std_logic;
		FAIL            :   out std_logic
	);
end entity;

architecture BEHAVIOUR of BIT_MEASURE is
    signal CURRENT_STATE : BM_ST_TYPE;
	signal NEXT_STATE : BM_ST_TYPE;
	signal SAMPLED_BITS : std_logic_vector(2 downto 0);
	signal I_DATA : std_logic;
	signal I_FAIL : std_logic;
begin
    NXT_ST : process(CURRENT_STATE, DATA_IN, CYCLE_MEASURE, I_DATA, I_FAIL)
	begin
	    DONE <= '0';
		BM_DATA <= '0';
		FAIL <= '0';

    	case CURRENT_STATE is
		when IDLE =>
		    --Detta hopp tas enbart på startbiten i en
			--överföring. Därför måste DATA_IN vara '1'.
		    if (DATA_IN = '1') then 
			    NEXT_STATE <= S1;
		    else
			    NEXT_STATE <= IDLE;
			end if;
		when S1 =>
			if (CYCLE_MEASURE = '0') then NEXT_STATE <= IDLE;
			else NEXT_STATE <= S2;
			end if;
		when S2 =>
			if (CYCLE_MEASURE = '0') then
			    NEXT_STATE <= IDLE;
			else 
			    NEXT_STATE <= S3;
			end if;
		when S3 =>
			if (CYCLE_MEASURE = '0') then
			    NEXT_STATE <= IDLE;
			else 
			    NEXT_STATE <= BLANK;
			end if;
		when BLANK =>
		    DONE <= '1';
			BM_DATA <= I_DATA;
			FAIL <= I_FAIL;
			if (CYCLE_MEASURE = '0') then
			    NEXT_STATE <= IDLE;
			else 
			    NEXT_STATE <= S1;
			end if;
		end case;
	end process;
	
	STATE_SYNC : process(CLK, RESET)
	begin
	    if (RESET = '1') then
	        CURRENT_STATE <= IDLE;
			SAMPLED_BITS <= (others => '0');
		elsif rising_edge(CLK) then
		    if (CURRENT_STATE = S1) then
		        SAMPLED_BITS(0) <= DATA_IN;
			end if;
		    if (CURRENT_STATE = S2) then
		        SAMPLED_BITS(1) <= DATA_IN;
			end if;
		    if (CURRENT_STATE = S3) then
		        SAMPLED_BITS(2) <= DATA_IN;
			end if;

			
		    CURRENT_STATE <= NEXT_STATE after 1 ns;

		end if;
	end process;
	
	I_DATA <= '1' when (SAMPLED_BITS = "111") else '0';
	I_FAIL <= '0' when (SAMPLED_BITS = "111") or (SAMPLED_BITS = "000") else '1';
	
end architecture;


package BC_PACK is
    TYPE BC_ST_TYPE is (IDLE, START, BIT0, BIT1, BIT2, BIT3,
	                    BIT4, BIT5, BIT6, BIT7, STOP, PRESENT);
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.BC_PACK.all;

entity BIT_COLLECTOR is
    port (
        CLK             :   in std_logic;
		RESET           :   in std_logic;
		DATA_IN         :   in std_logic;
		DONE            :   in std_logic;
		BM_DATA         :   in std_logic;
		FAIL            :   in std_logic;
		CYCLE_MEASURE   :   out std_logic;
		BYTE_OUT        :   out std_logic_vector(7 downto 0);
		BYTE_AVAIL      :   out std_logic
	);
end entity;

architecture BEHAVIOUR of BIT_COLLECTOR is
    signal CURRENT_STATE : BC_ST_TYPE;
	signal NEXT_STATE : BC_ST_TYPE;
begin
    NXT_STATE : process(CURRENT_STATE, DATA_IN, DONE, BM_DATA, FAIL)
	begin
	    CYCLE_MEASURE <= '0';
		BYTE_AVAIL <= '0';
	    case (CURRENT_STATE) is
		when IDLE =>
		    if (DATA_IN = '1') then
		        NEXT_STATE <= START;
		    else
			    NEXT_STATE <= IDLE;		
			end if;
		when START =>
		    CYCLE_MEASURE <= '1';
			if (DONE = '1') then
			    if (BM_DATA = '1') and (FAIL = '0') then
    			    NEXT_STATE <= BIT0;
				else 
				    NEXT_STATE <= IDLE;
				end if;
		    else
			    NEXT_STATE <= START;
			end if;
        when BIT0 =>
		    CYCLE_MEASURE <= '1';
			if (DONE = '1') then
			    if  (FAIL = '0') then
    			    NEXT_STATE <= BIT1;
				else 
				    NEXT_STATE <= IDLE;
				end if;
		    else
			    NEXT_STATE <= BIT0;
			end if;
        when BIT1 =>
		    CYCLE_MEASURE <= '1';
			if (DONE = '1') then
			    if  (FAIL = '0') then
    			    NEXT_STATE <= BIT2;
				else 
				    NEXT_STATE <= IDLE;
				end if;
		    else
			    NEXT_STATE <= BIT1;
			end if;
        when BIT2 =>
		    CYCLE_MEASURE <= '1';
			if (DONE = '1') then
			    if  (FAIL = '0') then
    			    NEXT_STATE <= BIT3;
				else 
				    NEXT_STATE <= IDLE;
				end if;
		    else
			    NEXT_STATE <= BIT2;
			end if;
        when BIT3 =>
		    CYCLE_MEASURE <= '1';
			if (DONE = '1') then
			    if  (FAIL = '0') then
    			    NEXT_STATE <= BIT4;
				else 
				    NEXT_STATE <= IDLE;
				end if;
		    else
			    NEXT_STATE <= BIT3;
			end if;
        when BIT4 =>
		    CYCLE_MEASURE <= '1';
			if (DONE = '1') then
			    if  (FAIL = '0') then
    			    NEXT_STATE <= BIT5;
				else 
				    NEXT_STATE <= IDLE;
				end if;
		    else
			    NEXT_STATE <= BIT4;
			end if;
        when BIT5 =>
		    CYCLE_MEASURE <= '1';
			if (DONE = '1') then
			    if  (FAIL = '0') then
    			    NEXT_STATE <= BIT6;
				else 
				    NEXT_STATE <= IDLE;
				end if;
		    else
			    NEXT_STATE <= BIT5;
			end if;
        when BIT6 =>
		    CYCLE_MEASURE <= '1';
			if (DONE = '1') then
			    if  (FAIL = '0') then
    			    NEXT_STATE <= BIT7;
				else 
				    NEXT_STATE <= IDLE;
				end if;
		    else
			    NEXT_STATE <= BIT6;
			end if;
        when BIT7 =>
		    CYCLE_MEASURE <= '1';
			if (DONE = '1') then
			    if  (FAIL = '0') then
    			    NEXT_STATE <= STOP;
				else 
				    NEXT_STATE <= IDLE;
				end if;
		    else
			    NEXT_STATE <= BIT7;
			end if;
		when STOP =>
		    CYCLE_MEASURE <= '1';
			if (DONE = '1') then
			    if (BM_DATA = '0') and (FAIL = '0') then
    			    NEXT_STATE <= PRESENT;
				else 
				    NEXT_STATE <= IDLE;
				end if;
		    else
			    NEXT_STATE <= STOP;
			end if;
		when PRESENT =>
			NEXT_STATE <= IDLE;
			BYTE_AVAIL <= '1';
		end case;
	end process;
	
	STATE_SYNC : process(CLK, RESET)
	begin
	    if (RESET = '1') then
			BYTE_OUT <= (others => '0');
	        CURRENT_STATE <= IDLE;
		elsif (rising_edge(CLK)) then
		    if (CURRENT_STATE = BIT0) then
		        BYTE_OUT(0) <= BM_DATA;
		    end if;
		    if (CURRENT_STATE = BIT1) then
		        BYTE_OUT(1) <= BM_DATA;
		    end if;
		    if (CURRENT_STATE = BIT2) then
		        BYTE_OUT(2) <= BM_DATA;
		    end if;
		    if (CURRENT_STATE = BIT3) then
		        BYTE_OUT(3) <= BM_DATA;
		    end if;
		    if (CURRENT_STATE = BIT4) then
		        BYTE_OUT(4) <= BM_DATA;
		    end if;
		    if (CURRENT_STATE = BIT5) then
		        BYTE_OUT(5) <= BM_DATA;
		    end if;
		    if (CURRENT_STATE = BIT6) then
		        BYTE_OUT(6) <= BM_DATA;
		    end if;
		    if (CURRENT_STATE = BIT7) then
		        BYTE_OUT(7) <= BM_DATA;
		    end if;
			
		    CURRENT_STATE <= NEXT_STATE after 1 ns;
		end if;
	end process;
end architecture;
		    			    
		
        


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UAR is
    port (
        CLK         : in std_logic;
        RESET       : in std_logic;
		IR_DETECT   : in std_logic;
		RXD         : out std_logic_vector(7 downto 0);
		RXD_READY   : out std_logic;
		RXD_ACK     : in std_logic
	);
end entity;

architecture STRUCTURE of UAR is
    component BIT_MEASURE is
        port (
            CLK             :   in std_logic;
    		RESET           :   in std_logic;
    		DATA_IN         :   in std_logic;
    		CYCLE_MEASURE   :   in std_logic;
    		DONE            :   out std_logic;
    		BM_DATA         :   out std_logic;
    		FAIL            :   out std_logic
    	);
    end component;

    component BIT_COLLECTOR is
        port (
            CLK             :   in std_logic;
    		RESET           :   in std_logic;
    		DATA_IN         :   in std_logic;
    		DONE            :   in std_logic;
    		BM_DATA         :   in std_logic;
    		FAIL            :   in std_logic;
    		CYCLE_MEASURE   :   out std_logic;
    		BYTE_OUT        :   out std_logic_vector(7 downto 0);
    		BYTE_AVAIL      :   out std_logic
    	);
    end component;

    signal DATA_IN          :   std_logic;
    signal CYCLE_MEASURE    :   std_logic;
    signal BIT_DONE         :   std_logic;
    signal BM_DATA          :   std_logic;
    signal BIT_FAIL         :   std_logic;
    signal BYTE_AVAIL       :   std_logic;
	signal BYTE_OUT         :   std_logic_vector(7 downto 0);

begin
    BM1 : BIT_MEASURE port map (
	    CLK => CLK,
		RESET => RESET,
	    DATA_IN => DATA_IN,
		CYCLE_MEASURE => CYCLE_MEASURE,
		DONE => BIT_DONE,
		BM_DATA => BM_DATA,
		FAIL => BIT_FAIL
	);

    BC1 : BIT_COLLECTOR port map (
	    CLK => CLK,
		RESET => RESET,
	    DATA_IN => DATA_IN,
		DONE => BIT_DONE,
		BM_DATA => BM_DATA,
		FAIL => BIT_FAIL,
		CYCLE_MEASURE => CYCLE_MEASURE,
		BYTE_AVAIL => BYTE_AVAIL,
        BYTE_OUT => BYTE_OUT
	);
	
	SYNC : process(CLK, RESET)
	begin
	    if (RESET = '1') then
	        RXD <= (others => '0');
			RXD_READY <= '0';
			DATA_IN <= '0';
		elsif (rising_edge(CLK)) then
		    if (RXD_ACK = '1') then
		        RXD_READY <= '0';
			elsif (BYTE_AVAIL = '1') then
		        RXD <= BYTE_OUT;
				RXD_READY <= '1';
			end if;
			
			DATA_IN <= IR_DETECT;
			
		end if;
	end process;

end architecture;


					
    
----------------------------------------------
-- Följande entity är huvudkomponenten i 
-- RemoteDimmer
--------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.GEN_PACK.all;

entity REMOTE_DIMMER is
	port (
        CLK             :   in std_logic;
		RESET           :   in std_logic;
		IR_DETECT       :   in std_logic;
        RC_ADDRESS      :   in std_logic_vector(3 downto 0);
		ZERO_DETECT     :   in std_logic;
		TRIAC_PULSE     :   out std_logic
	);
end entity;


architecture STRUCTURE of REMOTE_DIMMER is
    component UAR is
        port (
            CLK         : in std_logic;
            RESET       : in std_logic;
    		IR_DETECT   : in std_logic;
    		RXD         : out std_logic_vector(7 downto 0);
    		RXD_READY   : out std_logic;
    		RXD_ACK     : in std_logic
    	);
    end component;

    component RC_DECODE is
        port (
            CLK             :   in std_logic;
    		RESET           :   in std_logic;
    		RC_ADDRESS      :   in std_logic_vector(3 downto 0);
    		RXD             :   in std_logic_vector(7 downto 0);
    		RXD_READY       :   in std_logic;
    		RXD_ACK         :   out std_logic;
    		CM_FADE_DOWN    :   out std_logic;
    		CM_FADE_UP      :   out std_logic;
    		CM_PANIC_ON     :   out std_logic
    	);
    end component;

    component DIMMER_FSM is
    	port (
            CLK             :   in std_logic;
    		RESET           :   in std_logic;
    		CM_FADE_UP      :   in std_logic;
    		CM_FADE_DOWN    :   in std_logic;
    		CM_PANIC_ON     :   in std_logic;
    		COUNTER_TOP     :   in std_logic;
    		COUNTER_BOTTOM  :   in std_logic;
    		COUNT_UP        :   out std_logic;
    		COUNT_SET       :   out std_logic;
    		COUNT_ENABLE    :   out std_logic
    	);
    end component;

    component FADE_COUNTER is
        port (
            CLK             :   in std_logic;
    		COUNT_UP        :   in std_logic;
    		COUNT_SET       :   in std_logic;
    		COUNT_ENABLE    :   in std_logic;
    		COUNTER_TOP     :   out std_logic;
    		COUNTER_BOTTOM  :   out std_logic;
    		LIGHT_VALUE     :   out unsigned(FADE_COUNTER_BITLEN-1 downto 0)
    	);
    end component;

    component  triac_DRIVER is
        port (
    	    CLK             :   in std_logic;
    		RESET           :   in std_logic;
    		ZERO_DETECT     :   in std_logic;
    		LIGHT_VALUE     :   in unsigned(FADE_COUNTER_BITLEN-1 downto 0);
    		TRIAC_TRIG      :   out std_logic
    	);
    end component;

    signal RXD              :   std_logic_vector(7 downto 0);
    signal RXD_READY        :   std_logic;
    signal RXD_ACK          :   std_logic;
    signal CM_FADE_DOWN     :   std_logic;
    signal CM_FADE_UP       :   std_logic;
    signal CM_PANIC_ON      :   std_logic;
    signal COUNTER_TOP      :   std_logic;
    signal COUNTER_BOTTOM   :   std_logic;
    signal COUNT_UP         :   std_logic;
    signal COUNT_SET        :   std_logic;
    signal COUNT_ENABLE     :   std_logic;
    signal LIGHT_VALUE      :   unsigned(FADE_COUNTER_BITLEN-1 downto 0);

begin

	UAR1 : UAR port map (
	    CLK => CLK,
		RESET => RESET,
		IR_DETECT => IR_DETECT,
		RXD => RXD,
		RXD_READY => RXD_READY,
		RXD_ACK => RXD_ACK
	);
	
	RCD1 : RC_DECODE port map (
	    CLK => CLK,
		RESET => RESET,
		RC_ADDRESS => RC_ADDRESS,
		RXD => RXD,
		RXD_READY => RXD_READY,
		RXD_ACK => RXD_ACK,
		CM_FADE_DOWN => CM_FADE_DOWN,
		CM_FADE_UP => CM_FADE_UP,
		CM_PANIC_ON => CM_PANIC_ON
	);
		
    DFSM1 :  DIMMER_FSM port map (
	    CLK => CLK,
		RESET => RESET,
    	CM_FADE_UP => CM_FADE_UP,
    	CM_FADE_DOWN => CM_FADE_DOWN,
    	CM_PANIC_ON => CM_PANIC_ON,
    	COUNTER_TOP => COUNTER_TOP,
    	COUNTER_BOTTOM => COUNTER_BOTTOM,
    	COUNT_UP => COUNT_UP,
    	COUNT_SET => COUNT_SET,
    	COUNT_ENABLE => COUNT_ENABLE
    );
	
    FC1 : FADE_COUNTER port map (
	    CLK => CLK,
    	COUNT_UP => COUNT_UP,
    	COUNT_SET => COUNT_SET,
    	COUNT_ENABLE => COUNT_ENABLE,
    	COUNTER_TOP => COUNTER_TOP,
    	COUNTER_BOTTOM => COUNTER_BOTTOM,
    	LIGHT_VALUE => LIGHT_VALUE
    );
	
    TD1 :  TRIAC_DRIVER port map (
	    CLK => CLK,
		RESET => RESET,
    	ZERO_DETECT => ZERO_DETECT,
    	LIGHT_VALUE => LIGHT_VALUE,
    	TRIAC_TRIG => TRIAC_PULSE
    );
end architecture;

		