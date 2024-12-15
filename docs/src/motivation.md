# Motivation

I've
[written about how I got into ASIC work](https://matiasilva.com/journal/riscv-from-scratch/)
in my journal before. In a nutshell, it was very much accidentally. It wasn't by
accident, though, that from a young age I was interested in computers and how
they work. I was the family IT kid, even though what I knew back then is vastly
dwarfed by what I know now.

My years spent coding everything from physics simulations, to microcontrollers,
to entire ticketing platforms had taught me about the limitations of the
hardware I was working on but something still eluded me. It was only after I got
an internship in chip design and took a university course in computer
architecture, though, that the worlds of hardware and software came together for
me. Armed with all this knowledge, I felt like I finally knew the entire stack
from application to transistor (and that's where it stops for me, because I'm
not a physicist).

I followed an unusual path into digital design. Most tend to experiment on FPGAs
and back up RTL with simulations, with very few ever getting to take part in
real ASIC design as costs are prohibitive. Because I got a job at an fabless
ASIC shop, interestingly, I was missing the exact opposite. Coming from the
software world, the inflexibility of hardware is incredibly frustrating and more
so are the arcane development practices in that sector. I needed a reason to get
some FPGA experience and I wanted a challenge.

What better project to work on than a RISC-V core? Well, that was what I thought
until I saw that everyone and their uncle had gotten to that challenge years
ago[^defence]. While I've never looked at anyone else's cores before finishing
my own, the vulgarity of the RISC-V core meant that it fell short of the
learning tool I wanted it to be. The upshot was that there was plenty of good
material online, with help ranging from tooling, to environment setup, to
microarchitecture.

A glaring similarity among many RISC-V projects out there was that few were ever
able to "talk to" anything. In the real world, this is not how things work. CPU
cores are just a piece of the puzzle that is known as the SoC (an important one,
of course). Many of them were also not pipelined, nor did they account for any
kind of hazards. So, this is where I set myself the challenge. It meant that I'd
learn a little more about real chips, AMBA protocols like AHB and APB, and could
be on my way to understanding modern superscalar CPUs.

My main goals with the project were to:

1. to understand the role of each tool involved in a tapeout
1. develop a deeper understanding of digital design, verification and compilers
1. to understand the hardware stack from the bottom up: gates to kernel to
   userland software
1. learn about RISC-V, computer architecture and ISAs

Along the way, I greatly refined my command of Neovim for documentation writing
and code, which I'd been trying to pick up for forever.

[^defence]:
    In my defence, I was 12 when the first RISC-V ISA came out and 16 when
    homemade cores began entering the mainstream.
