# Current Version 3 Information

Vivado: 2024.2

Target board: Arty S7 / xc7s50

Sine frequency: 1 kHz (Future Plans to bring it down to 1Hz testing, 1kHz was for the debugging IP)

Window function: Joglekar (exclusive to version 3 currently, version 4 will have more or a version 3.5)

Joglekar p value: 5

## Configurable parameters 
These parameters are embedded into the FPGA design, so if you change something you need to re-run synthesis implementation and bitsream to properly run the chip's function under it's new parameters set.

Some defaults are overidden by top_memrister.v this helps to easily change some values like sine frequency however most parameters are in their respective modules.

+ CLK_HZ = 12_000_000
  - Describes the frequency of the physical clock entering the design.
  - This value must match the actual board clock and the XDC clock constraint.
  - Changing this number does not physically change the clock.

+ SINE_HZ = 1
  - Sets the requested sine-wave frequency.
  - The default inside phase_accumulator.v is 1, but top_memrister.v overrides it with 1000 for the current Version 3 design. This can be changed but of course you need to resynthesize, impl, etc the whole design. Results are shown in the Data folder for different parameters. 

+ Ron = 10
  - Sets the lowest memristance value, reached when state_x is at its maximum.
  - In Version 3, this is an arbitrary digital model value and does not represent a measured resistance in ohms.

+ Roff = 90
  - Sets the highest memristance value, reached when state_x is at its minimum.
  - In Version 3, this is an arbitrary digital model value and does not represent a measured resistance in ohms.
  - Values between Ron and Roff represent the continuous intermediate memristance states.
  - Roff should be greater than Ron.

+ FRAC_BITS = 16
  - Sets the number of fractional bits used by the internal x_q state accumulator.
  - Increasing this value makes visible changes to state_x occur more slowly while allowing small updates to accumulate.
  - the larger this value is the more precise it can become, however with limitation to the 8 bit normalizations/outputs

+ STATE_GAIN = 20
  - Currently memristor_core.v is set to 8 for STATE_GAIN, however in the top_memrister.v file I overided it to 20 for curve fitting. 
  - Multiplies the voltage-driven state update.
  - Increasing it makes the internal state move toward its boundaries faster.

+ use_joglekar_window = 1
  - Enables the Joglekar window when set to 1.
  - Setting it to 0 bypasses the window function and instead of gradual movement near Ron and Roff boundries, State_x updates to STATE_GAIN and the sine wave generation.
  -  it could create a simpler (more perfect infinity loop) or really sharp pinching in the hyeresis loop, but im not really sure since I have not tested this nor intend to as my Version 2 was this minus the gain and rom file for state_x values with respect to the joglekar file.
  - In future versions will have more windowing functions to utilize this feature better

+ window_shift = 8
  - Divides the windowed state update by 2^window_shift.
  - Increasing it reduces how far the state moves during each clock cycle.

+ window_floor = 8
  - Replaces a zero Joglekar window value at the saturated boundaries.
  - This allows the state to move away from a boundary when the voltage reverses.

+ X_INIT = 0
  - Sets the signed internal state loaded during reset.
  - -128 is the Roff end, 127 is the Ron end, and 0 is approximately the midpoint of the state range.
  - In Version 4, this value could be adjusted to start the model at a resistance that better represents the initial state of a real device.
  - X_INIT does not set or represent the input voltage.

+ ROM_FILE = "sine_table_64x8.mem"
  - Selects the memory file containing the sine-wave lookup-table values.
  - This file can be changed by using the googlecolab jynper files with the respective namesakes, basically you can change your parameters in there and get new LUTs that this project can technically use. (it would really only work properly with 64 entries containing 8 bit values.)

+ window_file = "joglekar_window_256x8.mem"
  - Selects the memory file containing the Joglekar window coefficients.
  - You can adjust your p value to get different results of the windowing function
  - the windowing function is described above but this file contains scaled coefficients selected by state_x to control how much the internal state moves.
  -  The p constant can drastically impact how the curve is fitted, which is how I will be one of the main changing parameters to get proper fitting curves when compared to actual memrister graph data
  -  (this is useful as certain spec configurations to this proeject can be made with proper curve fitting tests so you dont need to guess all the time. sadly thats a version 5 thing which i dont think i will get to).
  -  However the other parameters like gain, frequency, voltage scaling, Ron, Roff, etc is to be considered in curve fitting so the p value isnt a one stop shop for fixing your hystersis loops

### Joglekar p Value

+ p = 5
  - The p value is not a Verilog parameter
  - It is built into joglekar_window_256x8.mem when the LUT is generated.
  - To change p, generate a new window memory file from the google collab file and rebuild the bitstream. (find it in the python folder) 


## How to operate

### Requirements

+ Vivado 2024.2
+ Digilent Arty S7-50 (xc7s50csga324-1)
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

