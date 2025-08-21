# Verilator + cocotb testbenches

This folder contains Python based testbenches executed with **Verilator** and
**cocotb** via `pytest`.

## Running

```sh
pytest -q
```

A waveform (`dump.vcd`) is produced under `sim_build/` and can be inspected
with [GTKWave](http://gtkwave.sourceforge.net/).

## Lint and format

```sh
make lint   # Verilator --lint-only
make format # Uncrustify
```
