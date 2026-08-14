# My hopefully future installment by the end of December (its a due date so. shrug) 

This Version would be an updated version of Version 3 as it will be implemented on an oscilscope to go from pure digital to a Digital to Analog conversion. 
Im still not done with this as im waiting on the parts but that will be a during hte Fall semester goal 

while i wait however there may be a Version 3.5 maybe Version 4 will be this however it can be done in parralel as i want 

[] More Windowing Functions like Prodromakis, no window function (had that before), biolek etc etc 
[] make it more user friendly - so instead of needing to rebuild to change variables, those variables could be changed live it should be possible with some built in registers but of course with something like a window function it will need python code that gets updated with whatever constant variable that gets changed. like in joglekar from p=1 to 5 or 8 etc that would need an entire recompilation in the FPGA however i would like it so you can change the gain variable i have or the R_on R_off variables i have. or at the very least live window function changes as that i already assume can be done with a single multiplexer deciding what before it does any math with state_x and memristance. 
[] Create verification test benches - I dont really.. know.. well I do know how to make a test bench in verilog, i just suck at it! i have been testing this hardware by literally recompiling and validating on an FPGA every. single. time. the ILA probes help out a ton inside vivado but thats like such a maximalist perspective on hardware design. I should be studied for not learning how to make a testbench, you know i took an entire class for pure Verilog not even systemVerilog I think im pirating a book to learn SystemVerilog verification since I lowkey want to use systemverilog for verifying my chips and learn systemverilog overall since im a pure verilog type of person right now. 
