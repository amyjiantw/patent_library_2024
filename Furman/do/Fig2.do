* Figure 2: Expansion in time

use "data\patent_lib", replace
keep city_library openingyear
gen one = 1
sort openingyear city_library
gen two = sum(one)
replace city_library = proper(city_library)

keep if openingyear>=1974 & openingyear<1998

twoway (scatter  two openingyear  if openingyear>=1975 & openingyear<=1980, msize(0.9) mlabel(city_library) color(gs4) msymbol(O) mlabsize(1.6))(scatter  two openingyear   if openingyear>1980 & openingyear<=1985, msize(0.9) mlabel(city_library) color(gs7) msymbol(D) mlabsize(1.6))(scatter  two openingyear    if openingyear>1985 & openingyear<=1990, msize(0.9) mlabel(city_library) color(gs10) msymbol(T) mlabsize(1.6))(scatter  two openingyear   if openingyear>1990 & openingyear!=., mlabel(city_library) msize(0.9) color(gs13) msymbol(S) mlabsize(1.6)), ysize(8) xscale(range(1975 2000)) xlabel(1975(5)2000) ytitle("Number of patent libraries in U.S.", size(3)) xtitle("Opening year", size(3)) legend(off) 
graph export "results\Fig2.pdf", replace