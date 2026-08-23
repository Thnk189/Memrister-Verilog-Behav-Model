# Memrister FPGA

This project is my FPGA-based digital memristor emulator. It is currently on like Version 3, which uses a Joglekar window function, Python-generated LUT files, Verilog modules, and Vivado ILA probes to test the internal hysteresis behavior before moving to real DAC/oscilloscope output.

It generates a internal sine wave so no external inputs are needed to trigger behavior.

This is still a work in progress, but it is officially past the “wait... it actually works??” stage. I know, im like hella cool like that.

## What This Does

The FPGA generates a sine wave internally from a lookup table, then feeds that voltage into a digital memristor model. The model updates an internal state variable, calculates a resistance value, and then calculates current from the voltage and resistance.

In simple terms:

V_sine -> memristor state update -> R_value -> I_output

Inside the memristor's main core (Memrister_Core.v):

V_in → apply state gain → apply Joglekar window → update x_q → saturation/clamping → calculate Rmem → calculate I_out

This took me on and off this whole summer (and parts of the previous spring semester 2026) and for full transparency I used ai on certain parts but 80% of it is all hand written. I would call myself a beginner still in RTL-Digital logic chip design type fields. However conceptually I designed and pushed for my choices 100% as is. TBH all the ai suggustions were lowkey throwing everything off since parralel timing and just parralel thinking is not the AI's speciality. Luckily i am able to visualize that or somthing.

## How to use?
THrough the folders there are different version currently only version 3 exists below is the link to go to that readme file to download its files and just well mess with it
[Version 3 Readme](https://github.com/Thnk189/Memrister-Verilog-Behav-Model/tree/main/Version3)

Version 4 is not made yet

### What's left to do here? 

Other than version 4 i need to show a bunch of resutls of different parameters being changed im mostly only going to change a few key parameters but yeah that will be in the Data folder 

Version 4 is basically completely different than Version 3 and my Version 2 was completely different too,, i might include version 2 but its more like a tech demo no window function it was all internal no ILA probes no sine wave literally just a state accumulator but thats where I based it off of so it was necessary. anyway Version 4 is going to be using a DAC and opamp and osciscope workflow to prove these values in a more realsitic testing. Thats why its gonna take FOREVER if i ever get the time for it. but anyway yeah thats my little bit here :) see yah next week as i slowly get all this out 


@Property of [Chip Design Initiative](https://github.com/cdi-sjsu) 2026.
