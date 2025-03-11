library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.user_pkg.all;

-- Entity: mult_tree
-- Description: a pipelined multiplier and add tree. This entity works on one row of the 3x3 image window. 

--Keeping convolution to a 3x3 kernel window for now to avoid additional complexity. Could look into modularity of kernel size in the future
--Reference Dr. Stitt's mult_add_tree and mult_tree from RC1 convolution project for a more modular example (more complex as well due to recursive code)
entity mult_add_tree is
    port(
        clk                 : in std_logic;
        rst                 : in std_logic;
        en                  : in std_logic;
        pixel_input         : in window_row;
        filter_input        : in kernel_row;
        output              : out signed(C_ROW_MULT_WIDTH-1 downto 0)
    );
end mult_add_tree; 

architecture rtl of mult_add_tree is
    signal pixel_window_r : window_row;
    signal filter_window_r : kernel_row;
    signal col0_product, col1_product, col2_product: signed(C_SIGNAL_WIDTH+C_KERNEL_WIDTH downto 0);
    signal col_0_1_sum : signed(C_SIGNAL_WIDTH+C_KERNEL_WIDTH+1 downto 0);
    signal delay_col2 : signed(C_SIGNAL_WIDTH+C_KERNEL_WIDTH downto 0);
    signal output_r : signed(ROW_MULT_RANGE);
begin
    output <= output_r;
    process(clk, rst) 
    begin
        if(rst = '1') then 
            pixel_window_r <= (others => (others => '0'));
            filter_window_r <= (others => (others => '0'));
            col0_product <= (others => '0');
            col1_product <= (others => '0');
            col2_product <= (others => '0');
            col_0_1_sum <= (others => '0');
            delay_col2 <= (others => '0');
            output_r <= (others => '0');
        elsif(rising_edge(clk)) then
            if(en = '1') then
                --Stage 1 of pipeline
                pixel_window_r <= pixel_input;
                filter_window_r <= filter_input;

                --Multiply each pixel value in row by the corresponding filter row value. Casting to signed in case of negative values (i.e. sobel filter)
                col0_product <= signed('0' & pixel_window_r(0)) * filter_window_r(0);
                col1_product <= signed('0' & pixel_window_r(1)) * filter_window_r(1);
                col2_product <= signed('0' & pixel_window_r(2)) * filter_window_r(2);

                --Add column 0 and column 1 product, delay column 2 product for later add
                col_0_1_sum <= resize(col0_product, C_SIGNAL_WIDTH+C_KERNEL_WIDTH+2) + resize(col1_product, C_SIGNAL_WIDTH+C_KERNEL_WIDTH+2);
                delay_col2 <= col2_product;

                --Accumulate the row sum in one final stage
                output_r <= resize(col_0_1_sum, C_ROW_MULT_WIDTH) + resize(delay_col2, C_ROW_MULT_WIDTH);
            end if;
        end if;
    end process;
    
end rtl;