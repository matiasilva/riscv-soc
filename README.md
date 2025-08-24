# riscv-soc

This repository contains the source code for my Minimal RISC-V SoC.

To view the datasheet and full documentation set associated with this project,
[click here](https://matiasilva.github.io/riscv-soc).

> [!NOTE]  
> This project is a work in progress. I'm picking this up in my free time as and
> when I can.

## Development

To run simulations, view waveforms, and flash Lattice/Gowin FPGAs, you'll need
the latest version of the
[OSS CAD suite](https://github.com/YosysHQ/oss-cad-suite-build). For Xilinx
FPGAs, Vivado is required.

All Makefiles rely on the `$ROOT` variable being set, which you can get by
sourcing the appropriately named `sourceme` file.

Full information on running simulations and the project setup are available on
the [project page](https://matiasilva.github.io/riscv-soc/tools.html).

## Testing

This project uses cocotb for HDL simulation paired with the Icarus and Verilator
simulators. The following also applies:

- Simulators are invoked with cocotb Python runners.
- Test files follow standard pytest discovery names where one file tests one
  module
- Where multiple test files target one module, these are named 'tb\_' and the
  runner is separated into its own file, following pytest discovery names.

## Linting

[slang](https://sv-lang.com/) is used for HDL linting.

## Author

Matias Wang Silva, 2024/2025

## License

MIT
