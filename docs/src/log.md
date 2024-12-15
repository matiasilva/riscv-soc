# Project log

## TODO

- turn instrmem and regfile into BRAM, memory maybe SPRAM
- write a simple linker script
- add pipeline stalls
- rename pc_incr to pc
- double sw hazard, extra pipeline?
- if a clocked module requires the output of a previous stage, it should take it
  directly from that previous stage, not the pipeline register!
