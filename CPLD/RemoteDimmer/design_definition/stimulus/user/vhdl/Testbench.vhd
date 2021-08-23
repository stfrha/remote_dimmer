


architecture TESTBENCH of TEST_REMOTR_DIMMER is
	component REMOTE_DIMMER is
		port (
			CLK		: 	in std_logic;
			RESET	:	in std_logic;
			IR_DETECT	:	in std_logic;
			RC_ADDRESS :	in std_logic_vector(3 downto 0);
			TRIAC_TRIG :	out std_logic
		);
	end component;

	signal CLK		: 	std_logic := '0';
	signal RESET		:	std_logic := '1';
	signal IR_DETECT	:	std_logic;
	signal RC_ADDRESS 	:	std_logic_vector(3 downto 0);
	signal TRIAC_TRIG 	:	std_logic;

	signal I_IR_DET	:	std_logic;
	signal ENABLE_CODE	:	std_logic;
	signal I_IR_RND	:	std_logic;

	file	INFILE : ......;

begin
	RESET <= '1', '0' after 10 ms;

	CLK <= not CLK after .... ns;

	process ()
		variable IN_LINE	: ..........
		variable CHAR		: character;
		variable VAL		: integer;
		variable HOLD_TIME	: time;
		variable CODE		: std_logic_vector(7 downto 0);
	begin
		I_IR_DET <= '0';
		ENABLE_CODE <= '0';
		wait until falling_edge(RESET);
		while (not eof(INFILE)) loop
			readline(IN_LINE, INFILE);
			read(CHAR, IN_LINE);
			case CHAR is
			when 'W' =>
				read(TIME, IN_LINE);
				wait for TIME;
			when 'R' =>
				read(VAL, IN_LINE);
				CODE := std_logic_vector(to_unsigned(VAL, 8));
				ENABLE_CODE <= '1';
				I_IR_DET <= '0';
				wait for 2 ms;
				I_IR_DET <= '1';			-- Startpulse
				wait for 2 ms;
				for n in 0 to 7 loop
					I_IR_DET <= CODE(n);	-- Bit n
					wait for 2 ms;
				end loop;
				I_IR_DET <= '0';			-- Stoppulse
				wait for 2 ms;
				ENABLE_CODE <= '0';
			end case;
		end loop;
		while (1) loop;
		end loop;
	end process;

	I_IR_RND <= not I_IR_RND after 25 ms;

	IR_DETECT <= I_IR_DET when ENABLE_CODE = '1' else I_IR_RND;

end architecture;





