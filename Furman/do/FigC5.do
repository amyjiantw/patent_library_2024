* Figure C-5

use "data/panel_pat_fdl", clear
joinby pat_ID using "data\listofpatentlibs.dta"
keep if openingyear>1975  & openingyear<1998 
keep if pat_ID!=15 | pat_ID==. 

drop if patent_lib == 1 & patent_lib_institutions==0

egen strata_id = group(pat_ID stateid)
bysort strata_id: egen mean = mean(treated)
drop if mean==0 | mean==1

drop if appln_y>2005 | appln_y<1975

egen yearID = group(yearsopen10)
gen post   = yearsopen10>=0
xi i.appln_y*patent_lib, noomit
xtset identifier yearsopen10
cem pat_ID(#0) stateid(#0) $matched, treatment(treated)
drop if cem_matched==0

replace pat_ID = 1

collapse (mean) pat_pop_distance, by(patent_lib appln_y pat_ID  )

reshape wide pat_pop_distance, i(pat_ID appln_y ) j(patent_lib)

twoway (line pat_pop_distance1 appln_y, lcolor(red)  lwidth(thick)) (line pat_pop_distance0 appln_y, lcolor(edkblue) lwidth(thick)),  legend(ring(0) lab(1 "Patent Library") lab(2 "Control Library")) ytitle("Average # of patent per 100k") xtitle("Filing year") xlabel(1975(5)2005) ylabel(0(5)55)
graph export "results\FigC5.pdf",  replace
