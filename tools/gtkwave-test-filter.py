#!/usr/bin/env python3
import sys


def main():
    fh_in = sys.stdin
    fh_out = sys.stdout

    while True:
        # incoming values have newline
        line = fh_in.readline()
        if not line:
            return 0

        # outgoing filtered values must have a newline
        fh_out.write("%s" % line)
        fh_out.flush()


if __name__ == "__main__":
    sys.exit(main())
