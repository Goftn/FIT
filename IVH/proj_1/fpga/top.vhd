-- VHDL projekt - Hodiny + bud�k na VGA v�stup pomoc� za��zen� FitKit 2.0
-- Aplikace po nahr�n� do FitKitu zobrazuje na VGA v�stupu hodiny.
-- Ty na za��tku po��taj� od 00:00:00. Hodiny lze nastavit pomoc� kl�vesnice na FitKitu.
-- Aplikace t� um� funkci bud�ku (pouze vizu�ln�). Po nastaven� �asu pro bud�k kontroluje,
-- zda se ji� shoduje aktu�ln� �as s t�m bud�kov�m. Pokud ano, hodiny blikaj� s periodou 0.5 s.

-- Ovl�d�n�:
-- #   - vstup do nastaven� hodin, potvrzen� nastaven� hodin, potvrzen� nastaven� bud�ku
-- *   - vstup do nastaven� bud�ku
-- A   - zapnut�/vypnut� bud�ku (indikace te�kou nalevo od hodin) + vypnut� blik�n� bud�ku
-- 0-9 - nastaven� konkr�tn� hodnoty na zv�razn�n� pozici p�i editaci

-- Aplikace byla vytvo�ena jako semestr�ln� projekt do p�edm�tu IVH na FIT VUT, 2012/2013.
-- N�le�� k n� i dokumentace s podrobn�j��mi informacemi.
-- Datum vytvo�en�: 1.5.2013
-- Datum posledn� editace: 26.5.2013

-- Vytvo�ili:
-- Michal Kozub�k, xkozub03, student 1BIA FIT VUT Brno, xkozub03@stud.fit.vutbr.cz
-- Marek Hurta, xhurta01, student 1BIA FIT VUT Brno, xhurta01@stud.fit.vutbr.cz

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.vga_controller_cfg.all;
use work.clkgen_cfg.all;

entity fsm is
port(
   CLK         : in  std_logic;
	RESET			: in  std_logic;
   KEY         : in  std_logic_vector(15 downto 0);
	value			: out integer range 0 to 15;
	CNTS			: out std_logic_vector(13 downto 0)
);
end entity fsm;

architecture main of tlv_pc_ifc is
-- perioda pro ��ta�, kter� p�i pou�it�m CLK generuje sign�l s periodou 1 sekunda
  constant period: integer := 7372800;
  
-- vektor pro data z kl�vesnice
  signal kb_data_out: std_logic_vector(15 downto 0);
  
-- hodnoty jednotliv�ch ��slic hodin a bud�ku
  subtype small is integer range 0 to 10;
  signal cnt: integer := 0;
  signal cnt_sj: small := 0;
  signal cnt_mj: small := 0;
  signal cnt_hj: small := 0;
  signal cnt_sd: small := 0;
  signal cnt_md: small := 0;
  signal cnt_hd: small := 0;
  signal al_sj:  small := 0;
  signal al_sd:  small := 0;
  signal al_mj:  small := 0;
  signal al_md:  small := 0;
  signal al_hj:  small := 0;
  signal al_hd:  small := 0;
  
-- signaly zna��c� vygenerov�n� sekundy, minuty, hodiny
  signal sec : std_logic := '0';
  signal min: std_logic := '0';
  signal hour: std_logic := '0';
  
-- hodnota zm��knut� kl�vesy p�ijata z kone�n�ho automatu
  signal value: integer range 0 to 15 := 0;
  
-- sign�ly pro identifikaci pr�ce kone�n�ho automatu (ve kter� f�zi se nach�z�)
-- CNTS(0) = '1' => z�pis do des�tkov� pozice hodin (cnt_hd nebo al_hd)
-- CNTS(1) = '1' => z�pis do jednotkov� pozice hodin (cnt_hj nebo al_hj)
-- CNTS(2) = '1' => z�pis do des�tkov� pozice minut (cnt_md nebo al_md)
-- CNTS(3) = '1' => z�pis do jednotkov� pozice minut (cnt_mj nebo al_mj)
-- CNTS(4) = '1' => z�pis do des�tkov� pozice sekund (cnt_sd nebo al_sd)
-- CNTS(5) = '1' => z�pis do jednotkov� pozice sekund (cnt_sj nebo al_sj)
-- CNTS(6) = '1' => �ek�n� na z�pis na des�tkovou pozici hodin (zv�razn�na prvn� pozice na VGA v�stupu)
-- CNTS(7) = '1' => �ek�n� na z�pis na jednotkovou pozici hodin (zv�razn�na druh� pozice na VGA v�stupu)
-- CNTS(8) = '1' => �ek�n� na z�pis na des�tkovou pozici minut (zv�razn�na t�et� pozice na VGA v�stupu)
-- CNTS(9) = '1' => �ek�n� na z�pis na jednotkovou pozici minut (zv�razn�na �tvrt� pozice na VGA v�stupu)
-- CNTS(10) = '1' => �ek�n� na z�pis na des�tkovou pozici sekund (zv�razn�na p�t� pozice na VGA v�stupu)
-- CNTS(11) = '1' => �ek�n� na z�pis na jednotkovou pozici sekund (zv�razn�na �est� pozice na VGA v�stupu)
-- CNTS(12) => '0' => prob�h� nastavov�n� hodin, '1' => prob�h� nastavov�n� bud�ku
-- CNTS(13) => '0' => bud�k je neaktivn�, '1' => bud�k je aktivov�n
  signal CNTS: std_logic_vector(13 downto 0) := (others => '0');

-- BLINK(0) => blik�n� hodin ('0' viditeln� na v�stupu, '1' v�stup pr�zdn�)
-- BLINK(1) = '1' => blik�n� hodin zapnuto
  signal BLINK: std_logic_vector(1 downto 0) := (others => '1');
  
-- sign�ly pot�ebn� pro pr�ci s VGA v�stupem
  signal vga_mode: std_logic_vector (60 downto 0);
  signal red: std_logic_vector (2 downto 0);
  signal green: std_logic_vector (2 downto 0);
  signal blue: std_logic_vector (2 downto 0);
  
  signal rgb_sj: std_logic_vector (8 downto 0);
  signal rgb_mj: std_logic_vector (8 downto 0);
  signal rgb_hj: std_logic_vector (8 downto 0);
  signal rgb_sd: std_logic_vector (8 downto 0);
  signal rgb_md: std_logic_vector (8 downto 0);
  signal rgb_hd: std_logic_vector (8 downto 0);
  signal rgbf: std_logic_vector (8 downto 0);
  
  signal vga_row: std_logic_vector (11 downto 0);
  signal vga_col: std_logic_vector (11 downto 0);
  
  signal rom_col: integer range 0 to 8;
  
  signal sec_wrj: std_logic := '0';
  signal min_wrj: std_logic := '0';
  signal hr_wrj: std_logic := '0';
  signal sec_wrd: std_logic := '0';
  signal min_wrd: std_logic := '0';
  signal hr_wrd: std_logic := '0';
  
-- ROM pam� s ulo�en�mi ��slicemi 0 - 9
  type pamet is array(0 to 8*10-1) of std_logic_vector (0 to 7);
  
  signal rom_digit: pamet := ("00000000", -- 0
										"00111100",
										"00100100",
										"00100100",
										"00100100",
										"00111100",
										"00000000",
										(others => '0'),
										"00000000", -- 1
										"00000100",
										"00000100",
										"00000100",
										"00000100",
										"00000100",
										"00000000",
										(others => '0'),
										"00000000", -- 2
										"00111100",
										"00000100",
										"00111100",
										"00100000",
										"00111100",
										"00000000",
										(others => '0'),
										"00000000", -- 3
										"00111100",
										"00000100",
										"00111100",
										"00000100",
										"00111100",
										"00000000",
										(others => '0'),
										"00000000", -- 4
										"00100100",
										"00100100",
										"00111100",
										"00000100",
										"00000100",
										"00000000",
										(others => '0'),
										"00000000", -- 5
										"00111100",
										"00100000",
										"00111100",
										"00000100",
										"00111100",
										"00000000",
										(others => '0'),
										"00000000", -- 6
										"00111100",
										"00100000",
										"00111100",
										"00100100",
										"00111100",
										"00000000",
										(others => '0'),
										"00000000", -- 7
										"00111100",
										"00000100",
										"00000100",
										"00000100",
										"00000100",
										"00000000",
										(others => '0'),
										"00000000", -- 8
										"00111100",
										"00100100",
										"00111100",
										"00100100",
										"00111100",
										"00000000",
										(others => '0'),
										"00000000", -- 9
										"00111100",
										"00100100",
										"00111100",
										"00000100",
										"00111100",
										"00000000",
										(others => '0'));
begin

-- namapov�n� entity pro pr�ci s kl�vesnic� na FitKitu
	kbc_u : entity work.keyboard_controller_high
	-- pragma translate off
	generic map(	
		READ_INTERVAL => 32
	)
	-- pragma translate on
	port map(
		CLK         => SMCLK,
		RST			=> RESET,
		DATA_OUT    => kb_data_out,
		KB_KIN      => KIN,
		KB_KOUT     => KOUT
	);
-- namapov�n� entity pro pr�ci s kone�n�m automatem
   fistma: entity fsm
   port map(
		CLK			=> SMCLK,
	   RESET			=> RESET,
		KEY			=> kb_data_out,
		value			=> value,
		CNTS			=> CNTS
		);
-- namapov�n� entity pro pr�ci s VGA v�stupem
  vga: entity work.vga_controller(arch_vga_controller)
	port map(
		CLK 			=> CLK,
		RST 			=> RESET,
		ENABLE 		=> '1',
		MODE 			=> vga_mode,
		DATA_RED 	=> red,
		DATA_GREEN 	=> green,
		DATA_BLUE	=> blue,
		ADDR_COLUMN => vga_col,
		ADDR_ROW		=> vga_row,
		VGA_RED		=> RED_V,
		VGA_GREEN	=> GREEN_V,
		VGA_BLUE		=> BLUE_V,
		VGA_HSYNC	=> HSYNC_V,
		VGA_VSYNC	=> VSYNC_V
		);
		
  setmode(r640x480x60, vga_mode);
  
  rom_col <= conv_integer(vga_col(5 downto 3));
  
-- zji�t�n� pro ka�d� counter jestli se pro n�j v pam�t� nach�z� '1' nebo '0'
-- tak� se rozhoduje, jestli se zobrazuj� ��slice hodin nebo bud�ku (p�o jeho nastavov�n�)
  sec_wrj <= rom_digit(al_sj*8 + conv_integer(vga_row(5 downto 3)))(rom_col) when (CNTS(12) = '1') else
 				 rom_digit(cnt_sj*8 + conv_integer(vga_row(5 downto 3)))(rom_col);
				 
  sec_wrd <= rom_digit(al_sd*8 + conv_integer(vga_row(5 downto 3)))(rom_col) when (CNTS(12) = '1') else
				 rom_digit(cnt_sd*8 + conv_integer(vga_row(5 downto 3)))(rom_col);
  
  min_wrj <= rom_digit(al_mj*8 + conv_integer(vga_row(5 downto 3)))(rom_col) when (CNTS(12) = '1') else
				 rom_digit(cnt_mj*8 + conv_integer(vga_row(5 downto 3)))(rom_col);
				 
  min_wrd <= rom_digit(al_md*8 + conv_integer(vga_row(5 downto 3)))(rom_col) when (CNTS(12) = '1') else
				 rom_digit(cnt_md*8 + conv_integer(vga_row(5 downto 3)))(rom_col);
  
  hr_wrj <= rom_digit(al_hj*8 + conv_integer(vga_row(5 downto 3)))(rom_col) when (CNTS(12) = '1') else
			   rom_digit(cnt_hj*8 + conv_integer(vga_row(5 downto 3)))(rom_col);
				
  hr_wrd <= rom_digit(al_hd*8 + conv_integer(vga_row(5 downto 3)))(rom_col) when (CNTS(12) = '1') else
				rom_digit(cnt_hd*8 + conv_integer(vga_row(5 downto 3)))(rom_col);

-- nastaven� barev pro v�echny zji�t�n� hodnoty
-- aktu�ln� nastavovan� ��slice je zv�razn�na mod�e
-- klasick� hodinov� ��slice jsou zelen� a ��slice bud�ku fialov�
  rgb_sj  <= 	"000"&"101"&"000" when (sec_wrj = '1') and (CNTS(11) = '0') and (CNTS(12) = '0') else
					"101"&"000"&"101" when (sec_wrj = '1') and (CNTS(11) = '0') and (CNTS(12) = '1') else
					"000"&"000"&"101" when (sec_wrj = '1') and (CNTS(11) = '1') else
					"000"&"000"&"000";
					
  rgb_sd  <= 	"000"&"101"&"000" when (sec_wrd = '1') and (CNTS(10) = '0') and (CNTS(12) = '0') else
					"101"&"000"&"101" when (sec_wrd = '1') and (CNTS(10) = '0') and (CNTS(12) = '1') else
					"000"&"000"&"101" when (sec_wrd = '1') and (CNTS(10) = '1') else
					"000"&"000"&"000";

  rgb_mj  <= 	"000"&"101"&"000" when (min_wrj = '1') and (CNTS(9) = '0') and (CNTS(12) = '0') else
					"101"&"000"&"101" when (min_wrj = '1') and (CNTS(9) = '0') and (CNTS(12) = '1') else
					"000"&"000"&"101" when (min_wrj = '1') and (CNTS(9) = '1') else
					"000"&"000"&"000";
					
  rgb_md  <= 	"000"&"101"&"000" when (min_wrd = '1') and (CNTS(8) = '0') and (CNTS(12) = '0') else
					"101"&"000"&"101" when (min_wrd = '1') and (CNTS(8) = '0') and (CNTS(12) = '1') else
					"000"&"000"&"101" when (min_wrd = '1') and (CNTS(8) = '1') else
					"000"&"000"&"000";
			
  rgb_hj  <= 	"000"&"101"&"000" when (hr_wrj = '1') and (CNTS(7) = '0') and (CNTS(12) = '0') else
					"101"&"000"&"101" when (hr_wrj = '1') and (CNTS(7) = '0') and (CNTS(12) = '1') else
					"000"&"000"&"101" when (hr_wrj = '1') and (CNTS(7) = '1') else
					"000"&"000"&"000";
					
  rgb_hd  <= 	"000"&"101"&"000" when (hr_wrd = '1') and (CNTS(6) = '0') and (CNTS(12) = '0') else
					"101"&"000"&"101" when (hr_wrd = '1') and (CNTS(6) = '0') and (CNTS(12) = '1') else
					"000"&"000"&"101" when (hr_wrd = '1') and (CNTS(6) = '1') else
					"000"&"000"&"000";

-- p�i aktivn�m probliknut� se nezobraz� nic			
  rgbf <= "000"&"000"&"000" when BLINK(0) = '1' else
-- Tecka indikujici nastaveni alarmu:
			 "000"&"101"&"101" when (vga_row(11 downto 2) = "0000111011") and ((vga_col(9 downto 2)= "00011111")) and (CNTS(13) = '1') else
-- Dvojtecka mezi minutami a sekundami:
			 "101"&"000"&"000" when (vga_row(11 downto 3) = "000011101") and ((vga_col(8 downto 2) = "1011111")) else
			 "101"&"000"&"000" when (vga_row(11 downto 3) = "000011001") and ((vga_col(8 downto 2) = "1011111")) else
-- Dvojtecka mezi Hodinami a minutami:
			 "101"&"000"&"000" when (vga_row(11 downto 3) = "000011101") and ((vga_col(8 downto 2) = "0111111")) else
			 "101"&"000"&"000" when (vga_row(11 downto 3) = "000011001") and ((vga_col(8 downto 2) = "0111111")) else
-- Samotne cislice dle pozice na v�stupu:			 
			 rgb_sj when (vga_row(11 downto 6) = "000011") and ((vga_col(8 downto 6) = "111")) else 
			 rgb_sd when (vga_row(11 downto 6) = "000011") and ((vga_col(8 downto 6) = "110")) else 
			 rgb_mj when (vga_row(11 downto 6) = "000011") and ((vga_col(8 downto 6) = "101")) else 
			 rgb_md when (vga_row(11 downto 6) = "000011") and ((vga_col(8 downto 6) = "100")) else 
			 rgb_hj when (vga_row(11 downto 6) = "000011") and ((vga_col(8 downto 6) = "011")) else 
			 rgb_hd when (vga_row(11 downto 6) = "000011") and ((vga_col(8 downto 6) = "010")) else 
			 "000"&"000"&"000";
			 
  red 	<= rgbf(8 downto 6);
  green 	<= rgbf(5 downto 3);
  blue 	<= rgbf(2 downto 0);
  
  -- GENERATOR SEKUNDOVEHO SIGNALU
  process (SMCLK)
  begin
    if (SMCLK'event) and (SMCLK = '1') then
      sec <= '0';
		-- nastaven� blik�n� p�i aktivovan�m bud�ku a p�i shod� hodin a minut
		-- hodiny blikaj� minutu a nebo do zm��knut� '#', '*' nebo 'A'
		if ((cnt = period -1) or (cnt = period / 2)) then
		  if ((CNTS(13) = '1') and (cnt_hd = al_hd) and (cnt_hj = al_hj) and (cnt_md = al_md) and (cnt_mj = al_mj)) then
				BLINK(1) <= '1';
		  else 
				BLINK(1) <= '0';
		  end if;
		  if (CNTS(6) = '1') then
				BLINK(1) <= '0';
				BLINK(0) <= '0';
		  elsif (BLINK(1) = '1') then
				BLINK(0) <= not BLINK(0);
		  else
				BLINK(0) <= '0';
		  end if;
		 end if;
		if (cnt = period -1) then
        cnt <= 0;
        sec <= '1';
		else
        cnt <= cnt + 1;
      end if;
    end if;
  end process;
  
  -- GENERATOR MINUTOVEHO SIGNALU + nastaveni sekundovych pozic
  process (SMCLK)
  begin
    if (SMCLK'event) and (SMCLK = '1') then
		min <= '0';
		if (CNTS(4) = '1') then
			if (CNTS(12) = '1') then
				al_sd <= value;
			else 
				cnt_sd <= value;
			end if;
		elsif (CNTS(5) = '1') then
			if (CNTS(12) = '1') then
				al_sj <= value;
			else 
				cnt_sj <= value;
			end if;
		end if;
      if (sec = '1') then
        if (cnt_sj = 9) and (cnt_sd = 5) then
          cnt_sj <= 0;
			 cnt_sd <= 0;
          min <= '1';
        else
			 cnt_sj <= cnt_sj +1;
			 if (cnt_sj = 9) then
				cnt_sj <= 0;
				cnt_sd <= cnt_sd + 1;
			 end if;
        end if;
      end if;
    end if;
  end process;
  
  -- GENERATOR HODINOVEHO SIGNALU + nastaveni minutov�ch pozic
  process (SMCLK)
  begin
    if (SMCLK'event) and (SMCLK = '1') then
		hour <= '0';
		if (CNTS(2) = '1') then
			if (CNTS(12) = '1') then
				al_md <= value;
			else
				cnt_md <= value;
			end if;
		elsif (CNTS(3) = '1') then
			if (CNTS(12) = '1') then
				al_mj <= value;
			else
				cnt_mj <= value;
			end if;
		end if;
      if (min = '1') then
        if (cnt_mj = 9) and (cnt_md = 5) then
          cnt_mj <= 0;
			 cnt_md <= 0;
          hour <= '1';
        else
			 cnt_mj <= cnt_mj + 1;
			 if (cnt_mj = 9) then
				cnt_mj <= 0;
				cnt_md <= cnt_md + 1;
			 end if;
        end if;
      end if;
    end if;
  end process;
  
  -- POCITADLO HODIN + nastaveni hodinov�ch pozic
  process (SMCLK)
  begin
    if (SMCLK'event) and (SMCLK = '1') then
		if (CNTS(0) = '1') then
			if (CNTS(12) = '1') then
				al_hd <= value;
			else
				cnt_hd <= value;
			end if;
		elsif (CNTS(1) = '1') then
			if (CNTS(12) = '1') then
				al_hj <= value;
			else
				cnt_hj <= value;
			end if;
		end if;
      if (hour = '1') then
        if (cnt_hj = 3) and (cnt_hd = 2) then
          cnt_hj <= 0;
			 cnt_hd <= 0;
        else
		  	 cnt_hj <= cnt_hj + 1;
			 if (cnt_hj = 9) then
				cnt_hj <= 0;
				cnt_hd <= cnt_hd + 1;
			 end if;
        end if;      
      end if;
    end if;
  end process;
end main;

-- KONE�N� AUTOMAT
-- p�vodn� verze neobsahovala stavy AL_..., nastavov�n� bud�ku prob�halo p�es stejn� stavy jako u hodin,
-- jen se p�edem nastavil CNTS(12) na '1' + pomocn� sign�l alarm takt� na '1', ale bohu�e se oba tyto sign�ly
-- ihned nulovaly a nebylo mo�n� identifikovat nastavov�n� alarmu (nep�i�li jsme na p�vod tohoto chov�n�).
-- Proto je pou��to v�ce stav� ne� by bylo pot�eba + po p�echodu do nastaven� hodin se bud�k automaticky
-- vypne a je nutno jej znovu zapnout po nastaven� hodin.
-- Testov�n� na hodnotu sign�lu alarm jsme zachovali pro p�edstavu p�vodn�ho n�vrhu.
architecture behavioral of fsm is
-- funkce pro p�evod hodnoty vektoru kl�vesnice na hodnotu zm��kl� kl�vesy
	function log2(val : integer) return natural is
     variable result : natural;
	begin
     for i in 0 to 31 loop
         if (val <= (2 ** i)) then
             result := i;
             exit;
         end if;
     end loop;
     return result;
 end function;
   type t_state is (Hour2, Hour11, Hour12, Min2, Min1, Sec2, Sec1, IDLE, IDLE2,
							AL_Hour2, AL_Hour11, AL_Hour12, AL_Min2, AL_Min1, AL_Sec2, AL_Sec1);
   signal present_state, next_state: t_state;
	signal tmp: integer;
	signal alarm: std_logic;
begin 
sync_logic : process(CLK)
begin
   if (RESET = '1') then
      present_state <= IDLE;
	elsif (CLK'event AND CLK = '1') then
      present_state <= next_state;
   end if;
end process sync_logic;

next_state_logic : process(present_state, KEY)
begin	
	case (present_state) is	
 ---------------------------------------------
	when Hour2 =>
      next_state <= Hour2;
      if (KEY(1 downto 0) /= "00") then
			next_state <= Hour11;
		elsif (KEY(2) = '1') then
			next_state <= Hour12;
		elsif (KEY(15) = '1') then
			if (alarm = '1') then
				next_state <= IDLE2;
			else
				next_state <= IDLE;
			end if;
      end if;
 ---------------------------------------------	
	when Hour11 =>
      next_state <= Hour11;
      if (KEY(9 downto 0) /= "0000000000") then
			next_state <= Min2;
		elsif (KEY(15) = '1') then
			if (alarm = '1') then
				next_state <= IDLE2;
			else
				next_state <= IDLE;
			end if;
      end if;	
 ---------------------------------------------	  
	when Hour12 =>
		next_state <= Hour12;
		if (KEY(3 downto 0) /= "0000") then
			next_state <= Min2;
		elsif (KEY(15) = '1') then
			if (alarm = '1') then
				next_state <= IDLE2;
			else
				next_state <= IDLE;
			end if;
		end if;
	  
 ---------------------------------------------	  
	when Min2 =>
      next_state <= Min2;
      if (KEY(5 downto 0) /= "000000") then
			next_state <= Min1;
		elsif (KEY(15) = '1') then
			if (alarm = '1') then
				next_state <= IDLE2;
			else
				next_state <= IDLE;
			end if;
      end if;	
 ---------------------------------------------
	when Min1 =>
      next_state <= Min1;
      if (KEY(9 downto 0) /= "0000000000") then
			next_state <= Sec2;
		elsif (KEY(15) = '1') then
			if (alarm = '1') then
				next_state <= IDLE2;
			else
				next_state <= IDLE;
			end if;
      end if;		  
 ---------------------------------------------	  
	when Sec2 =>
      next_state <= Sec2;
      if (KEY(5 downto 0) /= "000000") then
			next_state <= Sec1;
		elsif (KEY(15) = '1') then
			if (alarm = '1') then
				next_state <= IDLE2;
			else
				next_state <= IDLE;
			end if;
      end if;    
 ---------------------------------------------	  
	when Sec1 =>
      next_state <= Sec1;
      if (KEY(9 downto 0) /= "0000000000") then
			next_state <= Hour2;
		elsif (KEY(15) = '1') then
			if (alarm = '1') then
				next_state <= IDLE2;
			else
				next_state <= IDLE;
			end if;
      end if;	
 ---------------------------------------------		
	when AL_Hour2 =>
		next_state <= AL_Hour2;
		if (KEY(1 downto 0) /= "00") then
			next_state <= AL_Hour11;
		elsif (KEY(2) = '1') then
			next_state <= AL_Hour12;
		elsif (KEY(15) = '1') then
			next_state <= IDLE2;
		end if;
 ---------------------------------------------		
	when AL_Hour11 =>
      next_state <= AL_Hour11;
      if (KEY(9 downto 0) /= "0000000000") then
			next_state <= AL_Min2;
		elsif (KEY(15) = '1') then
			next_state <= IDLE2;
      end if;	  
 ---------------------------------------------	  
	when AL_Hour12 =>
		next_state <= AL_Hour12;
		if (KEY(3 downto 0) /= "0000") then
			next_state <= AL_Min2;
		elsif (KEY(15) = '1') then
			next_state <= IDLE2;
		end if;  
 ---------------------------------------------	  
	when AL_Min2 =>
      next_state <= AL_Min2;
      if (KEY(5 downto 0) /= "000000") then
			next_state <= AL_Min1;
		elsif (KEY(15) = '1') then
			next_state <= IDLE2;
      end if;	
 ---------------------------------------------
	when AL_Min1 =>
      next_state <= AL_Min1;
      if (KEY(9 downto 0) /= "0000000000") then
			next_state <= AL_Sec2;
		elsif (KEY(15) = '1') then
			next_state <= IDLE2;
      end if;			  
 ---------------------------------------------	  
	when AL_Sec2 =>
      next_state <= AL_Sec2;
      if (KEY(5 downto 0) /= "000000") then
			next_state <= AL_Sec1;
		elsif (KEY(15) = '1') then
			next_state <= IDLE2;
      end if;    
 ---------------------------------------------	  
	when AL_Sec1 =>
      next_state <= AL_Sec1;
      if (KEY(9 downto 0) /= "0000000000") then
			next_state <= AL_Hour2;
		elsif (KEY(15) = '1') then
			next_state <= IDLE2;
      end if;	
 ---------------------------------------------		
	when IDLE =>
		next_state <= IDLE;
		if (KEY(15) = '1') then
			next_state <= Hour2;
		elsif (KEY(10) = '1') then
			next_state <= IDLE2;
		elsif (KEY(14) = '1') then
			next_state <= AL_Hour2;
		end if;	
 ---------------------------------------------		
	when IDLE2 =>
		next_state <= IDLE2;
		if (KEY(15) = '1') then
			next_state <= Hour2;
		elsif (KEY(10) = '1') then
			next_state <= IDLE;
		elsif (KEY(14) = '1') then
			next_state <= AL_Hour2;
		end if;
 ---------------------------------------------		
	when others =>
end case;
end process next_state_logic;

output_logic : process(present_state, KEY)
begin
tmp <= log2(conv_integer(KEY(9 downto 0)));
	case (present_state) is
 ---------------------------------------------	
	when Hour2 | AL_Hour2 =>	
		if (present_state = AL_Hour2) then
			CNTS(13) <= '1';
			CNTS(12) <= '1';
			alarm <= '1';
		end if;
		CNTS(6) <= '1';
		if (KEY(2 downto 0) /= "000") then
			CNTS(6) <= '0';
			CNTS(5) <= '0';
			CNTS(0) <= '1';
			value <= tmp;
		end if;
 ---------------------------------------------		
	when Hour11 | AL_Hour11 =>	
		if (present_state = AL_Hour11) then
			CNTS(13) <= '1';
			CNTS(12) <= '1';
			alarm <= '1';
		end if;
		CNTS(7) <= '1';
		if (KEY(9 downto 0) /= "0000000000") then
			CNTS(7) <= '0';
			CNTS(0) <= '0';
			CNTS(1) <= '1';
			value <= tmp;
		end if;
 ---------------------------------------------	
	when Hour12 | AL_Hour12 =>
		if (present_state = AL_Hour12) then
			CNTS(13) <= '1';
			CNTS(12) <= '1';
			alarm <= '1';
		end if;
		CNTS(7) <= '1';
		if (KEY(3 downto 0) /= "0000") then
			CNTS(7) <= '0';
			CNTS(0) <= '0';
			CNTS(1) <= '1';
			value <= tmp;
		end if;
 ---------------------------------------------		
	when Min2 | AL_Min2 =>
		if (present_state = AL_Min2) then
			CNTS(13) <= '1';
			CNTS(12) <= '1';
			alarm <= '1';
		end if;
		CNTS(8) <= '1';
		if (KEY(5 downto 0) /= "000000") then
			CNTS(8) <= '0';
			CNTS(1) <= '0';
			CNTS(2) <= '1';
			value <= tmp;
		end if;
 ---------------------------------------------	
	when Min1 | AL_Min1 =>	
		if (present_state = AL_Min1) then
			CNTS(13) <= '1';
			CNTS(12) <= '1';
			alarm <= '1';
		end if;
		CNTS(9) <= '1';
		if (KEY(9 downto 0) /= "0000000000") then
			CNTS(9) <= '0';
			CNTS(2) <= '0';
			CNTS(3) <= '1';
			value <= tmp;
		end if;
 ---------------------------------------------		
	when Sec2 | AL_Sec2 =>	
		if (present_state = AL_Sec2) then
			CNTS(13) <= '1';
			CNTS(12) <= '1';
			alarm <= '1';
		end if;
		CNTS(10) <= '1';
		if (KEY(5 downto 0) /= "000000") then
			CNTS(10) <= '0';
			CNTS(3) <= '0';
			CNTS(4) <= '1';
			value <= tmp;
		end if;
 ---------------------------------------------		
	when Sec1 | AL_Sec1 =>
		if (present_state = AL_Sec1) then
			CNTS(13) <= '1';
			CNTS(12) <= '1';
			alarm <= '1';
		end if;
		CNTS(11) <= '1';
		if (KEY(9 downto 0) /= "0000000000") then
			CNTS(11) <= '0';
			CNTS(4) <= '0';
			CNTS(5) <= '1';
			value <= tmp;
		end if;
 ---------------------------------------------		
	when IDLE =>
		CNTS(13 downto 0) <= "00000000000000";
		alarm <= '0';
		if (KEY(14) = '1') then
			CNTS(12) <= '1';
			CNTS(13) <= '1';
			alarm <= '1';
		end if;
 ---------------------------------------------	
	when IDLE2 =>
		CNTS(13 downto 0) <= "10000000000000";
		alarm <= '1';
		if (KEY(14) = '1') then
			CNTS(12) <= '1';
		end if;
 ---------------------------------------------		
	when others =>
	end case;
end process output_logic;

end architecture behavioral;	
