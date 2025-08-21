#!/bin/bash
set -e

# Format SystemVerilog sources with Uncrustify when available
if command -v uncrustify >/dev/null 2>&1; then
  if [ -f uncrustify.cfg ]; then
    echo "Running Uncrustify formatting..."
    # Ignore errors so the script can proceed even if formatting fails
    find src -name '*.sv' -print0 | xargs -0 uncrustify -c uncrustify.cfg --no-backup || true
  else
    echo "uncrustify.cfg not found; skipping formatting."
  fi
else
  echo "Uncrustify not installed; skipping formatting."
fi

# Lint the design sources with Verilator
if command -v verilator >/dev/null 2>&1; then
  echo "Running Verilator lint..."
  verilator --lint-only -sv -Wall --Wno-fatal -Wno-BLKANDNBLK -Wno-WIDTHEXPAND -Isrc \
    $(find src -path 'src/tb' -prune -o -name '*.sv' -print)
else
  echo "Verilator not installed."
  exit 1
fi

# Run cocotb testbenches using pytest and Verilator
if command -v pytest >/dev/null 2>&1; then
  echo "Running cocotb tests with pytest + Verilator..."
  export SIM=verilator
  export TOPLEVEL_LANG=verilog
  export VERILATOR_TRACE=1
  pytest -q
else
  echo "pytest not installed."
  exit 1
fi

echo "All checks completed."
