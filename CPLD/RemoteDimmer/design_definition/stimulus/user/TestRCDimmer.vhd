library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity TEST_REMOTE_DIMMER is
end entity;

architecture TESTBENCH of TEST_REMOTE_DIMMER is

	component REMOTE_DIMMER is
		port (
	        CLK             :   in std_logic;
			RESET           :   in std_logic;
			IR_DETECT       :   in std_logic;
	        RC_ADDRESS      :   in std_logic_vector(3 downto 0);
			TRIAC_PULSE     :   out std_logic
		);
	end component;


begin
	

