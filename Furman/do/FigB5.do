* Figure B-5

use "data/main_work", clear
keep pat_ID city_patent_library
duplicates drop
save "data\pat_ID_lib_city", replace

use "data/main_work", clear

gen b = .
gen se = .
gen number = .

egen yearID = group(yearsopen10)
gen post   = yearsopen10>=0
xi i.post*patent_lib, noomit
xtset identifier yearsopen10
cem pat_ID(#0) stateid(#0) $matched, treatment(treated)
drop if cem_matched==0
eststo r0: reg pat_pop_distance _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights],  cluster(pat_ID) 

levelsof(pat_ID), local(pat)
local i = 1
foreach x in `pat' {
eststo r0: xtreg pat_pop_distance _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights] if pat_ID!=`x', fe cluster(pat_ID) 
replace b = _b[_IposXpaten_1] in `i'
replace se = _se[_IposXpaten_1] in `i'
replace number = `x' in `i'
local i = `i'+1
}
sort b
keep b se number		
ren number pat_ID 
drop if pat_ID==.
joinby pat_ID using "data\pat_ID_lib_city"
replace city_patent_library = proper(city_patent_library)
gen upper = b+1.68*se
gen lower = b-1.68*se
set scheme lean1, perm
drop pat_ID
sort b
gen pat_ID=_n

labmask pat_ID, values(city_patent_library) // take over value label
twoway (scatter b pat_ID ,color(edkblue)) (rcap upper lower pat_ID,color(edkblue) ), yline(0) yscale(range(0 6)) ylabel(0(1)6) ytitle(Coefficient) legend(off) xtitle("") xlabel(1(1)45, valuelabel angle(90)) ytitle(Coefficient dropping one library)
graph export "results\FigB5.pdf", replace 

erase "data\pat_ID_lib_city.dta"