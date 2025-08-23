# utils_logging.do  — funções utilitárias de log para ModelSim/Questa

# Inicia transcript para um arquivo em <basedir>/<logs_subdir>/sim_<tb>_<timestamp>.log
# Retorna o caminho completo do log.
proc setup_logging {tb basedir {logs_subdir "logs"}} {
    # Diretório dos logs
    set ::LOGDIR [file join $basedir $logs_subdir]
    file mkdir $::LOGDIR

    # Timestamp e nome do arquivo
    set ts [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
    set ::LOGFILE [file join $::LOGDIR "sim_${tb}_${ts}.log"]

    # Ativa transcript para o arquivo
    transcript file $::LOGFILE
    transcript on

    return $::LOGFILE
}

# Encerra transcript e mostra onde o log foi salvo
proc finish_logging {} {
    transcript off
    if {[info exists ::LOGFILE]} {
        puts "===> Log salvo em $::LOGFILE"
    } else {
        puts "===> Transcript finalizado (nenhum arquivo configurado)"
    }
}
