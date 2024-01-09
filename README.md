# riscv-cpu

## Naming conventions

The code follows the [lowRISC coding style](https://github.com/lowRISC/style-guides/blob/master/VerilogCodingStyle.md) for Verilog for the most part. I wrote this myself in my free time so there will be deviations for no real reason.

* signals use snake case
	- note: logical word units are joined without underscore
	- eg: memwrite expands to memory write (one action)
	- eg: mem_to_reg expands to memory to register (no joining)
* parameters use ALL CAPS
* task names, module names are all snake case
* common abbreviations are used where possible (reg for register, mem for memory, ctrl for control, etc)

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


## Extra steps

### Mounting the iCESugar board

It seems that Raspberry Pi OS couldn't mount the board since `df` turned up empty. It was evident that the device was correctly plugged in though as `lsusb` showed a new addition and `dmesg` didn't show any errors. This meant that the board had to be manually mounted (remember, it's not really a mass storage device but acts like one), so I ran `blkid` to get the device UUID:

```
/dev/sda: SEC_TYPE="msdos" LABEL_FATBOOT="DAPLINK-DND" LABEL="iCELink" UUID="2702-1974" BLOCK_SIZE="512" TYPE="vfat"
```

I then added an entry in `fstab`:

```
UUID=2702-1974 /mnt/iCELink vfat defaults,auto,users,rw,nofail 0 0
```

and that was it!