# UART

To communicate with the outside world, a memory-mapped UART module was added to
the system. It contains a receiver and a transmitter, both tested at baud rates
of 115200, 19200 and 9600.

## Receiver hardware

Specification:

- 8 data bit
- 1 stop bit
- parity bit supported
- AHB data interface

The receiver uses an oversampling technique to estimate transmitted bits on the
data line. In the absence of a clock line, detection of a start bit (0 value)
followed by sampling of data at the middle of a bit's transmission ensures
accurate retrieval. A standard oversampling factor of 16 minimizes the error to
1/16 from the middle point.

```{figure} img/uart-rx-proto.svg
:width: 80%
:align: center

Transmission of a byte
```

A stop bit (1 value) indicates the end of a transfer and historically provided a
crude method of data pacing for slower processors.

### Parity

The parity bit is 0 when the popcount is odd. A simple scheme to generate this
is to negate a reduction XOR operation.

## Transmitter hardware

## Software interface
