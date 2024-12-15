# Tools

## Open source ASIC/FPGA tools

While there is a great open source toolset for the iCESugar v1.5, it remains
difficult to navigate the web of broken links to find what is really needed to
get Verilog synthesized and 'running on' the FPGA. After lots of searching and
reading tutorials, I've condensed it to this:

- `yosys` for synthesis
  - <https://github.com/YosysHQ/yosys>
- `nextpnr` for place n route
  - <https://github.com/YosysHQ/nextpnr>
- `iverilog` for Verilog compilation and simulation
  - <https://github.com/steveicarus/iverilog>
- `icestorm` for a few useful tools for the iCE40 family of FPGAs
  - <https://github.com/YosysHQ/icestorm>
- `icesprog` for uploading the bitstream to the iCESugar board specifically
  - <http://github.com/wuxx/icesugar>

I recommend building each of these tools from source to ensure the latest
(working) version and in the case of `icesprog` you'll also need to add the
binary directory to your `$PATH`. Each of these tools has their own required
dependencies so look them up to find them. Then, a standard `make -j4` and
`sudo make install` suffices, apart from the odd case when a `./configure` was
needed. While I was wrapping my head around this, I found
<https://f4pga.readthedocs.io/en/latest/flows/index.html> quite helpful in
explaining each step of the design flow and how that interlinks with these open
source tools.

## Extra steps

### Mounting the iCESugar board

It seems that Raspberry Pi OS couldn't mount the board since `df` turned up
empty. It was evident that the device was correctly plugged in though as `lsusb`
showed a new addition and `dmesg` didn't show any errors. This meant that the
board had to be manually mounted (remember, it's not really a mass storage
device but acts like one), so I ran `blkid` to get the device UUID:

```bash
/dev/sda: SEC_TYPE="msdos" LABEL_FATBOOT="DAPLINK-DND" LABEL="iCELink"
UUID="2702-1974" BLOCK_SIZE="512" TYPE="vfat"
```

I then added an entry in `fstab`:

```bash

UUID=2702-1974 /mnt/iCELink vfat defaults,auto,users,rw,nofail 0 0
```

and that was it!

### RISC-V decode filter in GTKWave

Full credits go to
[mattvenn](https://github.com/mattvenn/gtkwave-python-filter-process) for the
initial code for the GTKWave filter process that takes RISC-V machine code and
transforms it into RV32I assembly for easy visualization in the waveform viewer.
It seems in between the time they wrote it and now, differences in
`risv64-unknown-elf-as` output have broken it.

Note to self: the process file needs to be executable!

Format of the process file: I wasn't able to find any strict documentation on
the process file but from my testing I found that the values of a particular
signal that are currently rendered will be passed into the `stdin` of the script
that is called as a hex string. You can then do whatever you want with this but
make sure to add a `\n` to the end of your output string (if it doesn't already
have one). Beware of `x`s!

### Homebrew formula for GTKWave for MacOS (M-series)

GTKWave underwent a complete rewrite and somewhere along the line compatibility
with newer Macs was broken. The author does not work on a Mac so couldn't
provide correct build instructions. Some nice guy on the internet created a
custom Homebrew formula with all the right steps to compile from source. I'm
also testing a new waveform visualizer called "surfer".

```bash
brew update brew outdated brew upgrade brew cleanup brew uninstall gtkwave brew
untap randomplum/gtkw
```

### RISC-V toolchain

<https://github.com/riscv-software-src/homebrew-riscv?tab=readme-ov-file>

### macros

FPGA

### formatting

<https://github.com/chipsalliance/verible/blob/master/verilog/tools/formatter/README.md>

### verification

<https://github.com/YosysHQ/riscv-formal>
<https://github.com/riscv-software-src/riscv-tests/>ave brew install --HEAD
randomplum/gtkwave/gtkwave

## Custom scripts

Every design project has its own set of custom scripts, usually to shoehorn
bytes around into the right format.

## Editor

This was the first project I completed fully in (neo)vim, using the LazyVim set
of plugins. I know, I became the very thing I swore to destroy.

If you do happen to go down that route, though, I used the JetBrains Mono Nerd
Font, which gives full icon support in LazyVim, with the
[Monokai Pro](https://github.com/loctvl842/monokai-pro.nvim) theme [^also]. I
also recommend `mini.align` for aligning SystemVerilog and Prettier for
formatting Markdown, which when coupled with LazyVim's native `lang.markdown`
support leads to an incredible documentation writing experience. I suggest
turning on `proseWrap` specifically for Markdown to keep things nicely limited
at 80 chars per row.

[^also]:
    I also considered the [Alabaster](https://sr.ht/~p00f/alabaster.nvim/) theme
