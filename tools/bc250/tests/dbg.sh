#!/bin/bash
# dbg.sh '<json request>' [outpng]  -> calls the emulator's debug server
cd ~/lichii-bc250
if [ -n "$2" ]; then python3 -I tools/nx2/debug_mcp.py --server 127.0.0.1:6545 --call "$1" --out "$2"
else python3 -I tools/nx2/debug_mcp.py --server 127.0.0.1:6545 --call "$1"; fi
