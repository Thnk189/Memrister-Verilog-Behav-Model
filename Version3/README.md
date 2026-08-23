# Current Version 3 Information

Vivado: 2024.2

Target board: Arty S7 / xc7s50

Sine frequency: 1 kHz (Future Plans to bring it down to 1Hz testing, 1kHz was for the debugging IP)

Window function: Joglekar

Joglekar p value: 5

Ron: 10

Roff: 90

STATE_GAIN: 20

window_floor: 8

I_output scaling: (V_sine * 256) / R_value

## How to operate

### Requirements

+ Vivado 2024.2
+ Digilent Arty S7-50 (`xc7s50csga324-1`)
+ USB cable for the FPGA,, Duhhh!
  - The ILA probes are all within the FPGA but in Version 4 you will need more requirements as I bought a DAC and Opamp and going to use an oscilscope to view the results

Once you download the files you really just need the files inside version 3 folder not the version 3 folder itself. I tried my best to just leave the file paths to what it is but honestly its probably just easier to copy and paste some things and then for the top where the ILA probing IP was used make it yourself. Its not that hard from what I remember it gives you options. And I left the .xpr but like it goes to my file path so it probably wont work. if it doesnt ill just delete in like 4 months. 

### Once its built
after you 
+ Ran synthesis
+ Ran implementation
+ Generated bitstream
+ connect and programmed the Arty S7
+ Open the ILA dashboard thats in hardware manager section it usually pops up unless its not configured correctly.
   - ILA signals shown below
 
### ILA Signals

| Probe  | Signal   | Description                                                                                                                                                                                                                    |
|--------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Probe0 | state_x  | its the signed 8 bit memrister state that changes through the sine wave                                                                                                                                                        |
| Probe1 | dir      | A two bit value that indicates whether the state_x is idle, increasing, decreasing, or attempting to move beyond a saturated boundry. the ILA can show how each bit at whichever point in time is saying what State_X is doing |
| probe2 | R_value  | its an unsigned 8 bit memristance value                                                                                                                                                                                        |
| Probe3 | I_Output | a Signed 16 bit fixed point value with eight fractional bits, it you must divide this raw value by 256 to get the represented current                                                                                          |
| Probe4 | V_sine   | Is the signed 16 bit voltaged produced by the sine wave LUT. It has a approximent range from -256 to +256                                                                                                                      |

