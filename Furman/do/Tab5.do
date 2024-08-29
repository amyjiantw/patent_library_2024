* Table 5

use "data/main_work", clear
egen yearID = group(yearsopen10)
gen post   = yearsopen10>=0
xi i.post*patent_lib, noomit
xtset identifier yearsopen10
cem pat_ID(#0) stateid(#0), treatment(treated)
drop if cem_matched==0

gen b = . 
gen se = .
gen name = ""
gen counter = 0

gen new = new_single_pop+new_pair_pop
gen old = old_single_pop + old_couple_pop

local i = 1
foreach x in pat_pop_distance new_single_pop old_single_pop new_pair_pop  old_couple_pop    new  old {
eststo r`i': xtreg `x' _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights],fe  cluster(pat_ID) 
sum `x'
estadd scalar mean_scalar = r(mean)
replace b = _b[ _IposXpaten_1] in `i'
replace se = _se[ _IposXpaten_1] in `i'
replace counter = `i' in `i'
replace name = "`x'" in `i'
local i = `i'+1

}




label var _IposXpaten_1 "Pat Lib x Post "
label var post   "Post "
label var patent_lib "Patent Library"

esttab  r1 r2 r3 r4 r5  r6 r7 using "results\Tab5.tex", posthead("") keep( _IposXpaten_1 post )order( post _IposXpaten_1 )   fragment compress nogaps nodepvar noisily ///
stats(mean_scalar r2 N, fmt(%9.1f %9.2f %18.0g) labels(`"Mean Dep."' `"R2 (within)"' `"Obs."')) nonotes nonumber nomtitle b(1) se(1) obslast  ///
star(* 0.10 ** 0.05 *** 0.01) label  replace
