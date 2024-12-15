# Specification

## Naming conventions

The code follows the
[lowRISC coding style](https://github.com/lowRISC/style-guides/blob/master/VerilogCodingStyle.md)
for Verilog for the most part. I wrote this myself in my free time so there will
be deviations for no real reason.

- signals use snake case
  - note: logical word units are joined without underscore
  - eg: memwrite expands to memory write (one action)
  - eg: mem_to_reg expands to memory to register (no joining)
- parameters use ALL CAPS
- task names, module names are all snake case
- sensible abbreviations should be used but never at the cost of understanding
  (vld NO valid YES)
