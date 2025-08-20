transcript on
quietly set SCRIPTDIR [file normalize [file dirname [info script]]]
quietly set ROOT      [file normalize [file join $SCRIPTDIR ../..]]
puts "===> SCRIPTDIR = $SCRIPTDIR"
puts "===> ROOT      = $ROOT"
cd $ROOT

if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work

vlog -sv -work work +acc +incdir+$ROOT  "$ROOT/tb/spi_if.sv"
vlog -sv -work work +acc +incdir+$ROOT  "$ROOT/tb/leds_if.sv"
vlog -sv -work work +acc +incdir+$ROOT  "$ROOT/tb/tb_pkg.sv"
vlog -sv -work work +acc +incdir+$ROOT  "$ROOT/tb/tb_top.sv"

vsim -voptargs="+acc" -sv_seed random -classdebug work.tb_top

# ondas
do "$SCRIPTDIR/waves.do"

run -all
