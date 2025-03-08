library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package USER_PACKAGE is
    --Specify constants 
    constant C_SIGNAL_WIDTH             : positive := 8;
    constant C_KERNEL_DIMENSION         : positive := 3;
    constant C_KERNEL_WIDTH             : positive := 8;
    constant C_CONVOLUTION_WIDTH        : positive := 16;
    
    --Specify custom ranges (to be used in datatypes) from constants 
    subtype SIGNAL_WIDTH_RANGE is natural range C_SIGNAL_WIDTH-1 downto 0;
    subtype KERNEL_DIMENSION_RANGE is natural range 0 to C_KERNEL_DIMENSION -1;
    subtype CONVOLUTION_WIDTH_RANGE is natural range C_CONVOLUTION_WIDTH-1 downto 0;

    -- Specify custom datatypes from custom ranges
    type window_row is array(KERNEL_DIMENSION_RANGE) of std_logic_vector(SIGNAL_WIDTH_RANGE); --one row in matrix
    type window is array (KERNEL_DIMENSION_RANGE) of window_row; --full matrix

    type kernel_row is array(KERNEL_DIMENSION_RANGE) of signed(SIGNAL_WIDTH_RANGE); --one row in matrix
    type kernel is array (KERNEL_DIMENSION_RANGE) of kernel_row; --full matrix
end USER_PACKAGE;