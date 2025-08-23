# Testing

All block-level tests use [cocotb](https://github.com/cocotb/cocotb), with first
class support for cocotb 2.0.

All inter-IP dependencies should be kept to a minimum and dependency on the
project structure as well. Practically, this means if use of `$ROOT` can be
avoided, it should be.

Cores should follow a structure like:

```txt
.
└── core_a/
    ├── hdl/
    │   ├── a.v
    │   └── b.v
    ├── sim/
    │   └── <simulation output>
    ├── tests/
    │   ├── test_a.py
    │   ├── test_b.py
    │   └── <additional testcase data>
    └── fpga/
        └── Makefile
```
