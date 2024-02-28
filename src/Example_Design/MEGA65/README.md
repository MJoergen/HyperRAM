# MEGA65 support module (UART, keyboard, and video)

The purpose of this module is to provide support for UART and keyboard input and UART and
video output.  It's all encapsulated in a single module to keep the top-level file simple.

## HDMI output

The HDMI code generates a 1280x720 @ 60 Hz image.
It shows the following text:
```
 ERR-HI <error count, MSB>
 ERR-LO <error count, LSB>
FAST-HI <fast count, MSB>
FAST-LO <fast count, LSB>
SLOW-HI <slow count, MSB>
SLOW-LO <slow count, LSB>
 EXP-HI <expected read, MSB>
 EXP-LO <expected read, LSB>
ADDR-HI <address, MSB>
ADDR-LO <address, LSB>
READ-HI <actual read, MSB>
READ-LO <actual read, LSB>
```

## Limited keyboard support

The MEGA65 comes with a keyboard and two visible LED's. In order to make use of
these I've copied the file `mega65kbd_to_matrix.vhdl` from the [MEGA65
project](https://github.com/MEGA65/mega65-core) and removed stuff I didn't need.

In this way, I can start the test by pressing the `RETURN` key, and I can watch
the progress of the test on the `POWER` LED and look for any errors on the
`Floppy` LED. The entire test runs for approximately 2 seconds.

A separate file [clk_mega65.vhd](clk_mega65.vhd) generates a 40 MHz keyboard
clock and a 74.25 MHz video clock for the HDMI output.


## UART support

The example design listens to (any) UART input and if it receives anything at all,
it will start the test. So, e.g., pressing ENTER will start the test.

When the test is finished, it will output the same information as the video output.

