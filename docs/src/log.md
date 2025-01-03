# Project log

## Instruction support

### Data Transfer Instructions

- [ ] LUI: Load Upper Immediate
- [ ] AUIPC: Add Upper Immediate to PC
- [ ] ADDI: Add Immediate
- [ ] SLTI: Set Less Than Immediate (Signed)
- [ ] SLTIU: Set Less Than Immediate Unsigned
- [ ] XORI: Bitwise XOR Immediate
- [ ] ORI: Bitwise OR Immediate
- [ ] ANDI: Bitwise AND Immediate

### Register-Register Arithmetic Instructions

- [ ] ADD: Add
- [ ] SUB: Subtract
- [ ] SLL: Shift Left Logical
- [ ] SLT: Set Less Than (Signed)
- [ ] SLTU: Set Less Than Unsigned
- [ ] XOR: Bitwise XOR
- [ ] SRL: Shift Right Logical
- [ ] SRA: Shift Right Arithmetic
- [ ] OR: Bitwise OR
- [ ] AND: Bitwise AND

### Memory Access Instructions

- [x] LB: Load Byte (Signed)
- [ ] LH: Load Halfword (Signed)
- [ ] LW: Load Word
- [ ] LBU: Load Byte Unsigned
- [ ] LHU: Load Halfword Unsigned
- [ ] SB: Store Byte
- [ ] SH: Store Halfword
- [ ] SW: Store Word

### Control Transfer Instructions

- [ ] BEQ: Branch Equal
- [ ] BNE: Branch Not Equal
- [ ] BLT: Branch Less Than (Signed)
- [ ] BGE: Branch Greater Than or Equal (Signed)
- [ ] BLTU: Branch Less Than Unsigned
- [ ] BGEU: Branch Greater Than or Equal Unsigned
- [ ] JAL: Jump and Link
- [ ] JALR: Jump and Link Register

### System Instructions

- [ ] ECALL: Environment Call
- [ ] EBREAK: Environment Breakpoint

## TODO

- turn instrmem and regfile into BRAM, memory maybe SPRAM
- write a simple linker script
- add pipeline stalls
- rename pc_incr to pc
- double sw hazard, extra pipeline?
- if a clocked module requires the output of a previous stage, it should take it
  directly from that previous stage, not the pipeline register!
