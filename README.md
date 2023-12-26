# riscv-cpu

## Development

While there is a great open source toolset for the iCESugar v1.5, it remains difficult to navigate the web of broken links to find what is really needed to get Verilog synthesized and 'running on' the FPGA. After lots of searching and reading tutorials, I've condensed it to this:

* `yosys` for synthesis 
	- https://github.com/YosysHQ/yosys
* `nextpnr` for place n route
	- https://github.com/YosysHQ/nextpnr
* `iverilog` for Verilog compilation and simulation
	- https://github.com/steveicarus/iverilog
* `icestorm` for a few useful tools for the iCE40 family of FPGAs
	- https://github.com/YosysHQ/icestorm
* `icesprog` for uploading the bitstream to the iCESugar board specifically
	- http://github.com/wuxx/icesugar

I recommend building each of these tools from source to ensure the latest (working) version and in the case of `icesprog` you'll also need to add the binary directory to your `$PATH`. Each of these tools has their own required dependencies so look them up to find them. Then, a standard `make -j4` and `sudo make install` suffices, apart from the odd case when a `./configure` was needed. While I was wrapping my head around this, I found https://f4pga.readthedocs.io/en/latest/flows/index.html quite helpful in explaining each step of the design flow and how that interlinks with these open source tools.
