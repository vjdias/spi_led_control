# Verilator + cocotb testbenches

This folder contains Python based testbenches executed with **Verilator** and
**cocotb** via `pytest`.

## Running

```sh
pytest -q
```

Waveforms (`dump.fst`) are produced under `sim_build/<test>/` and can be
inspected with [GTKWave](http://gtkwave.sourceforge.net/).

## Lint and format

```sh
make lint   # Verilator --lint-only
make format # Uncrustify
```
