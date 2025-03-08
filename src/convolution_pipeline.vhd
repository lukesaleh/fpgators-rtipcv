library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use user_pkg.all;

entity convolution_pipeline is
    port(
        clk                     : in std_logic;
        rst                     : in std_logic;
        en                      : in std_logic;
        window_input            : in window;
        filter_input            : in kernel;
        output                  : out signed(CONVOLUTION_WIDTH_RANGE)
    );

architecture rtl of convolution_pipeline is
    signal summed_rows : 
begin

    

end architecture;
end mult_add_tree; 