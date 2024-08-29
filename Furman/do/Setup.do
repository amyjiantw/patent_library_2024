
clear all
set more off

program main
    * *** Add required packages from SSC to this list ***
    local ssc_packages "cem estout labutil gtools spmap egenmore"
    * *** Add required packages from SSC to this list ***

    if !missing("`ssc_packages'") {
        foreach pkg in "`ssc_packages'" {
            dis "Installing `pkg'"
            quietly ssc install `pkg', replace
        }
    }

    * Install lean scheme using net
    quietly net from "http://www.stata-journal.com/software/sj4-3"
    quietly cap net uninstall gr0002_3
	quietly net install gr0002_3
end

graph set window fontface "Constantia"
set scheme lean1, perm // Graph scheme 

