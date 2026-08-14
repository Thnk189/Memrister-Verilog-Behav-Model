# Memrister FPGA

This project is my FPGA-based digital memristor emulator. It is currently on like Version 3, which uses a Joglekar window function, Python-generated LUT files, Verilog modules, and Vivado ILA probes to test the internal hysteresis behavior before moving to real DAC/oscilloscope output.

It generates a internal sine wave so no external inputs are needed to trigger behavior.

This is still a work in progress, but it is officially past the “wait... it actually works??” stage. I know, im like hella cool like that.

## What This Does

The FPGA generates a sine wave internally from a lookup table, then feeds that voltage into a digital memristor model. The model updates an internal state variable, calculates a resistance value, and then calculates current from the voltage and resistance.

In simple terms:

V_sine -> memristor state update -> R_value -> I_output

This took me on and off this whole summer (and parts of the previous spring semester 2026) and for full transparency I used ai on certain parts but 80% of it is all hand written. I would call myself a beginner still in RTL-Digital logic chip design type fields. However conceptually I designed and pushed for my choices 100% as is. TBH all the ai suggustions were lowkey throwing everything off since parralel timing and just parralel thinking is not the AI's speciality. Luckily i am able to visualize that or somthing.

Version3 folder will explain how to operate things


@Property of [Chip Design Initiative](https://github.com/cdi-sjsu) 2026.
