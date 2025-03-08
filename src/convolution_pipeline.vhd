library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.user_pkg.all;

-- Entity: mult_tree
-- Description: a pipelined convolution kernel. This entity takes a 3x3 slice of an image and convolves it with a filter kernel.
-- It accumulates  

--Keeping convolution to a 3x3 kernel window for now to avoid additional complexity. Could look into modularity of kernel size in the future
--Reference Dr. Stitt's mult_add_tree and mult_tree from RC1 convolution project for a more modular example (more complex as well due to recursive code)

entity convolution_pipeline is
    port(
        clk                     : in std_logic;
        rst                     : in std_logic;
        en                      : in std_logic;
        window_input            : in window;
        filter                  : in kernel;
        output                  : out STD_LOGIC_VECTOR(SIGNAL_WIDTH_RANGE)
    );

end convolution_pipeline; 

architecture rtl of convolution_pipeline is
    --Signals used to connect registered outputs from row-wise add-multiplier tree
    type summed_row is array(KERNEL_DIMENSION_RANGE) of signed(ROW_MULT_RANGE);
    signal summed_rows_r : summed_row;

    signal output_r : signed(CONVOLUTION_WIDTH_RANGE);
    signal col_0_1_sum : signed(C_ROW_MULT_WIDTH downto 0);
    signal col_2_delay : signed(ROW_MULT_RANGE);
begin
    --Use the mult_add_tree entity to ccompute the row-wise sum of products for the filtered image
    U_ROW_ACCUMULATOR : for i in 0 to C_KERNEL_DIMENSION-1 generate
        U_MULT_ADD_TREE : entity work.mult_add_tree
        port map(
            clk => clk,
            rst => rst,
            en => en,
            pixel_input => window_input(i),
            filter_input => filter(i),
            output => summed_rows_r(i) --outputs already registered through this entity
        );
    end generate;
    
    --This clocked process completes the pipelined convolution datapath
    process(clk, rst)
    begin
        if(rst = '1') then
            output_r <= (others => '0');
            col_0_1_sum <= (others => '0');
            col_2_delay <= (others => '0');
        elsif(rising_edge(clk)) then
            if(en = '1') then
                col_0_1_sum <= resize(summed_rows_r(0), C_ROW_MULT_WIDTH+1) + resize(summed_rows_r(1), C_ROW_MULT_WIDTH+1);
                col_2_delay <= summed_rows_r(2);
                output_r <= resize(col_0_1_sum, C_CONVOLUTION_WIDTH) + resize(col_2_delay, C_CONVOLUTION_WIDTH);
            end if;
        end if;
    end process;

    --add clamping on output before being able to assign, also need to cast to std_logic_vector and resize
    output <=
        --clamp to 0 case 
        (others => '0') when (output_r <= to_signed(0,C_CONVOLUTION_WIDTH)) else 
        --clamp to 255 case
        (others => '1') when (output_r >= to_signed(C_MAX_INTENSITY, C_CONVOLUTION_WIDTH)) else
        --otherwise cast signal
        std_logic_vector(output_r(C_SIGNAL_WIDTH-1 downto 0));
end rtl;