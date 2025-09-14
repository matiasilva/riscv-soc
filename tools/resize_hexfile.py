#!/usr/bin/env python3

import argparse
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(
        prog="resize_hexfile", description="resizes and reformats hex output from as"
    )
    parser.add_argument("-i", "--input", required=True)
    parser.add_argument("-o", "--output", required=True)
    parser.add_argument("-w", "--width", required=True)
    parser.add_argument("-r", "--reverse", action="store_true")
    args = parser.parse_args()
    with open(Path(args.input), "r") as infile:
        outlines = []
        for line in infile.readlines()[1:]:
            # `as` has 16 bytes per line
            line = line.strip()
            bytes_in_line = line.split(" ")
            n_bytes = int(args.width)
            if n_bytes % 2 != 0:
                sys.exit(1)
            n_groups = len(bytes_in_line) // n_bytes
            for i in range(n_groups):
                bytes_to_write = bytes_in_line[i * n_bytes : (i + 1) * n_bytes]
                if args.reverse:
                    bytes_to_write = reversed(bytes_to_write)
                outlines.append("".join(bytes_to_write))

    with open(Path(args.output), "w") as outfile:
        for line in outlines:
            outfile.write(line + "\n")


if __name__ == "__main__":
    main()
