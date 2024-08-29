* Figure 7


use "data/main_work", clear
egen yearID = group(yearsopen10)
gen post   = yearsopen10>=0
xi i.post*patent_lib, noomit
xtset identifier yearsopen10
cem pat_ID(#0) stateid(#0) $matched, treatment(treated)
drop if cem_matched==0

gen b = .
gen se = .
gen subcategory = ""
gen counter = .
ren pat_pop_distance pat_mainarea30_0
unab k: pat_mainarea30_*

local i = 1
foreach x in  `k' {
quietly{
xtreg `x' _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights], fe cluster(pat_ID) 
replace b = _b[_IposXpaten_1] in `i'
replace se = _se[_IposXpaten_1] in `i'
replace subcategory = "`x'" in `i'
replace counter = `i' in `i'
local i = `i'+1
}
}



keep if counter!=.

gen upper = b + 1.68*se
gen lower = b - 1.68*se

replace subcategory = subinstr(subcategory, "pat_mainarea30_", "", .)

destring subcategory, replace
ren subcategory mainarea30
replace counter = (counter*-1)+37


joinby mainarea30 using "data\mainarea35_area35", unmatched(master)
drop mainarea30 _merge
joinby area30 using "data\mainarea35_area35", unmatched(master)
replace mainarea30=0 if mainarea30==.
keep b se mainarea30 counter upper lower
duplicates drop
sort mainarea30
decode mainarea30, gen(label_ex)


cap drop counter
drop if upper==.
gsort - b
gen counter = _n

replace counter = 7-counter


labmask counter, values(label_ex) 


gen significant = upper<0 | lower>0
replace lower=. if upper==.
twoway (rcap upper lower counter, horizontal color(edkblue))  (scatter counter b if significant==1, color(red) msymbol(d)) (scatter counter b if significant==0, color(edkblue) msymbol(dh)), ytitle("") legend(off) xline(0)  ylabel(0  1 2 3 4 5 6 "Baseline" ,  valuelabel     )   ysize(4)  
graph export "results\Fig7.pdf", replace 