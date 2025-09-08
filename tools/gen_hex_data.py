#!/usr/bin/env python3
"""
Generates random hex data for $readmemh
"""

import random
import argparse


def generate_hex_word():
    """Generate 4 random hex bytes"""
    bytes_list = [random.randint(0, 255) for _ in range(4)]
    return " ".join(f"{b:02x}" for b in bytes_list)


def main():
    parser = argparse.ArgumentParser(
        description="Generate random hex words (4 bytes each)"
    )
    parser.add_argument("n", type=int, help="Number of hex words to generate")
    parser.add_argument("--seed", type=int, help="Random seed for reproducible output")
    parser.add_argument(
        "-o",
        "--output",
        type=str,
        help="Output file (if not specified, prints to stdout)",
    )

    args = parser.parse_args()

    if args.seed:
        random.seed(args.seed)

    # Generate all hex words
    hex_words = []
    for _ in range(args.n):
        hex_words.append(generate_hex_word())

    # Output to file or stdout
    if args.output:
        with open(args.output, "w") as f:
            for hex_word in hex_words:
                f.write(hex_word + "\n")
        print(f"Generated {args.n} hex words and saved to {args.output}")
    else:
        for hex_word in hex_words:
            print(hex_word)


if __name__ == "__main__":
    main()
