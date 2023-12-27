set module [lindex $quartus(args) 0]
set revision [lindex $quartus(args) 2]

if {[string match "quartus_asm" $module]} {
    post_message "Running AutoProgrammer for ${revision}"
    qexec "quartus_pgm output_files/${revision}.cdf"
}