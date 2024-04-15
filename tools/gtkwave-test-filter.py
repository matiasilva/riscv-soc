#!/usr/bin/env python3
import sys

def main():
    fh_in = sys.stdin
    fh_out = sys.stdout

    with open("/Users/matias/projects/riscv-cpu/demo.txt", 'a') as outfile:
        while True:
            # incoming values have newline
            l = fh_in.readline()
            outfile.write("%s\n" % l)
            if not l:
                return 0

            # outgoing filtered values must have a newline
            fh_out.write("%s\n" % l)
            fh_out.flush()

if __name__ == '__main__':
	sys.exit(main())