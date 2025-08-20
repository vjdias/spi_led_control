transcript on

# Descobre onde está este .do
quietly set SCRIPTDIR [file normalize [file dirname [info script]]]
# Sobe dois níveis desde modelsim/ → tb/ ou src/tb/
quietly set ROOT      [file normalize [file join $SCRIPTDIR ../..]]

# Raiz real do projeto (se ROOT terminar em /src, volta um nível)
if {[string equal [file tail $ROOT] "src"]} {
  set PROJ_ROOT [file dirname $ROOT]
} else {
  set PROJ_ROOT $ROOT
}

# TB pode estar em tb/ ou src/tb/
set TB_DIR ""
if {[file exists "$PROJ_ROOT/tb/tb_top.sv"]} {
  set TB_DIR "$PROJ_ROOT/tb"
} elseif {[file exists "$PROJ_ROOT/src/tb/tb_top.sv"]} {
  set TB_DIR "$PROJ_ROOT/src/tb"
} else {
  error "tb_top.sv não encontrado em $PROJ_ROOT/tb nem $PROJ_ROOT/src/tb"
}

# Include dirs:
#  - INC1 = raiz do projeto  (para includes do tipo "src/..." e "tb/...")
#  - INC2 = raiz/src         (para includes do tipo "protocol/...", "drivers/...", etc. sem 'src/')
set INC1 "$PROJ_ROOT"
set INC2 "$PROJ_ROOT/src"

puts "===> SCRIPTDIR = $SCRIPTDIR"
puts "===> PROJ_ROOT = $PROJ_ROOT"
puts "===> TB_DIR    = $TB_DIR"
puts "===> INC1      = $INC1"
puts "===> INC2      = $INC2"

# Lib
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work

# Compila TB (tb_top inclui o RTL via `include "..."`
vlog -sv -work work +acc +incdir+$INC1 +incdir+$INC2  "$TB_DIR/spi_if.sv"
vlog -sv -work work +acc +incdir+$INC1 +incdir+$INC2  "$TB_DIR/leds_if.sv"
vlog -sv -work work +acc +incdir+$INC1 +incdir+$INC2  "$TB_DIR/tb_pkg.sv"
vlog -sv -work work +acc +incdir+$INC1 +incdir+$INC2  "$TB_DIR/tb_top.sv"

# Roda em modo console até $finish
vsim -c -voptargs="+acc" -sv_seed random -classdebug work.tb_top -do "run -all"
