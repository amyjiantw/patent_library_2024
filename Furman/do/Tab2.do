* Table 2

use "data/main_work", clear
gen post   = yearsopen10>=0
xi i.post*patent_lib, noomit
xtset identifier yearsopen10
cem pat_ID(#0) stateid(#0), treatment(treated)
drop if cem_matched==0
egen group_year = group(appln_y pat_ID)
gen b = . 
gen se = .
gen name = ""
gen counter = 0
gen av_forward_cites =  pat_pop_total_forward_cites / pat_pop_distance

local i = 1
foreach x in pat_pop_distance pat_pop_total_forward_cites av_forward_cites pat_pop_small pat_pop_big pat_pop_young  pat_pop_old {
eststo r`i': xtreg `x' _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights],fe  cluster(pat_ID) 
sum `x'
estadd scalar mean_scalar = r(mean)
replace b = _b[ _IposXpaten_1] in `i'
replace se = _se[ _IposXpaten_1] in `i'
replace counter = `i' in `i'
replace name = "`x'" in `i'
local i = `i'+1

}

eststo r23: xtreg pat_pop_distance _IposXpaten_1 post  patent_lib i.yearID2  [aweight=cem_weights] if uni_library==1 ,  fe cluster(pat_ID)
sum pat_pop_distance if uni_library==1
estadd scalar mean_scalar = r(mean)

eststo r24: xtreg pat_pop_distance _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights] if uni_library==0 , fe  cluster(pat_ID)
sum pat_pop_distance if uni_library==0
estadd scalar mean_scalar = r(mean)

label var _IposXpaten_1 "Pat Lib x Post "
label var post   "Post "
label var patent_lib "Patent Library"
esttab  r1 r2 r3 r6 r7 r4 r5  r23 r24 using "results\Tab2.tex", posthead("") keep( _IposXpaten_1 post )order( post _IposXpaten_1 )   fragment compress nogaps nodepvar noisily ///
			stats(mean_scalar r2 N, fmt(%9.1f %9.2f %18.0g) labels(`"Mean Dep."' `"R2 (within)"' `"Obs."')) nonotes nonumber nomtitle b(1) se(1) obslast  ///
			star(* 0.10 ** 0.05 *** 0.01) label  replace