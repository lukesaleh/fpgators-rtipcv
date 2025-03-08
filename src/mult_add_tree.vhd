library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use user_pkg.all;

-- Entity: mult_tree
-- Description: a pipelined multiplier and add tree. This entity works on one row of the 3x3 image window. 
entity mult_add_tree is
    port(
        clk                 : in std_logic;
        rst                 : in std_logic;
        en                  : in std_logic;
        pixel_input         : in window_row;
        filter_input        : in kernel_row;
        output              : out std_logic_vector(CONVOLUTION_WIDTH_RANGE)
    );
end mult_add_tree; 

architecture rtl of mult_add_tree is
    signal 

begin

    

end architecture;