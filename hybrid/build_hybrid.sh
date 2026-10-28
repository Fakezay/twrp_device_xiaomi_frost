#!/bin/bash
set -e
# Compiles the static AArch64 Hybrid Router PID 1
aarch64-linux-gnu-gcc -static -O2 router.c -o init
aarch64-linux-gnu-strip -s init
chmod 755 init
echo "Hybrid router compiled successfully!"
