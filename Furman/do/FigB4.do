* Figure B-4

use "data/main_work", clear
egen yearID = group(yearsopen10)
gen post   = yearsopen10>=0
xi i.post*patent_lib, noomit
xtset identifier yearsopen10
cem pat_ID(#0) stateid(#0) $matched, treatment(treated)
drop if cem_matched==0

gen b = .
gen se = .
gen number = .

local i=1
eststo rd1: xtreg pat_pop_distance _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights], fe cluster(pat_ID)
replace b = _b[_IposXpaten_1] in `i'
replace se = _se[_IposXpaten_1] in `i'
replace number = `i' in `i'
local i = `i'+1

foreach x in 50 100  {
eststo rd`i': xtreg pat_pop_`x'm _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights] , fe cluster(pat_ID) 
replace b = _b[_IposXpaten_1] in `i'
replace se = _se[_IposXpaten_1] in `i'
replace number = `i' in `i'
local i = `i'+1
}

			
gen upper = b+1.96*se
gen lower = b-1.96*se
set scheme lean1, perm
twoway (connected b number ,color(red)) (line upper lower number,color(edkblue) lpattern(solid solid) lcolor(edkblue) lwidth(thin thin) ), yline(0) ytitle(Coefficient) legend(off) xtitle("") xlabel(1 "0-15 mi" 2 "15-50 mi" 3 "50-100 mi" ) xtitle("Distance of inventor to patent library") ytitle("Increase in patents per 100k population")
graph export "results\FigB4.pdf", replace 