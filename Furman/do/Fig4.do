* Figure 4

use "data/main_work", clear

cem pat_ID(#0) stateid(#0), treatment(treated)
drop if cem_matched==0
gen one = 1
collapse (mean) pat_pop_distance (sum) one , by (patent_lib pat_ID yearsopen10)
reshape wide pat_pop_distance one, i(pat_ID yearsopen10) j(patent_lib)
collapse (mean) pat_pop_distance0 pat_pop_distance1 , by ( yearsopen10 )

twoway (connected pat_pop_distance1 yearsopen10 , color(red) lwidth(thick)) (connected pat_pop_distance0 yearsopen10 , lpatter(dash) lwidth(thick) color(edkblue)) ,   xtitle (Year relative to library opening) xlabel(#10) ytitle (Average number of patents within 15 miles) legend(on order(1 2) rows(2) label(1 "Patent libraries") label(2 "Federal Deposit libraries") pos(11) ring(0)) xline(0, lc(gray)) ysize(5)  ylabel(, labsize(large)) xlabel(, labsize(large)) yscale(range (12 28)) ylabel(12(2)28)
graph export "results\Fig4a.pdf", replace 

egen m = max((yearsopen10==-1)*pat_pop_distance0)
replace pat_pop_distance0 = pat_pop_distance0 -  m
drop m
egen m = max((yearsopen10==-1)*pat_pop_distance1)
replace pat_pop_distance1 = pat_pop_distance1 -  m

twoway (connected pat_pop_distance1 yearsopen10 , color(red) lwidth(thick)) (connected pat_pop_distance0 yearsopen10 , lpatter(dash) lwidth(thick) color(edkblue)) ,   xtitle (Year relative to library opening) xlabel(#10) ytitle (Average additional patents p.c. within 15 miles) ysize(5) yscale(range (-2 13)) ylabel(-2(2)14) legend(on order(1 2) rows(2) label(1 "Patent Libraries") label(2 "Federal Deposit Libraries") pos(11) ring(0)) xline(0, lc(gray)) xlabel(, labsize(large)) ylabel(, labsize(large))
graph export "results\Fig4b.pdf", replace 