* Table 3

use "data/panel_pat_fdl", clear

keep if patent_lib
joinby pat_ID using "data\listofpatentlibs.dta"

drop if patent_lib == 1 & patent_lib_institutions==0
duplicates drop pat_ID appln_y, force
keep if openingyear>1975 & openingyear<1998   
drop if appln_y<1975
gen av_forward_cites =  pat_pop_total_forward_cites / pat_pop_distance

keep if pat_ID!=15 | pat_ID==.  //burlington, vt
keep pat_ID pat_pop_distance pat_pop_total_forward_cites av_forward_cites  yearsopen10 patent_lib appln_y openingyear pat_pop_small pat_pop_big pat_pop_young  pat_pop_old pat_pop_50m 
save "data/tmp", replace

keep pat_ID yearsopen10 patent_lib appln_y openingyear
foreach x in pat_ID yearsopen10 patent_lib  openingyear {
ren `x' `x'_o
}
joinby appln_y using "data/tmp"
drop patent_lib patent_lib_o
gen patent_lib = pat_ID == pat_ID_o
keep if yearsopen10<0 | patent_lib==1
keep if openingyear>=openingyear_o | patent_lib==1
drop yearsopen10
cem pat_ID_o(#0), treatment(patent_lib)
drop if cem_matched==0

cap drop _merge
egen yearID = group(yearsopen10_o)
gen post   = yearsopen10_o>=0

xi i.post*patent_lib, noomit
egen identifier = group(pat_ID pat_ID_o)
xtset identifier appln_y
drop if yearsopen10_o<-5 | yearsopen10_o>5 
cap drop yearID
egen yearID = group(appln_y) 
local i=0
foreach x in pat_pop_distance pat_pop_total_forward_cites av_forward_cites pat_pop_young pat_pop_old pat_pop_small pat_pop_big  {
local i=`i'+1
eststo rw`i': xtreg `x'  patent_lib post _IposXpaten_1 i.yearID [aweight=cem_weights]  , fe cluster(identifier) 
sum `x'
estadd scalar mean_scalar = r(mean)
}

label var _IposXpaten_1 "Pat Lib x Post "
label var post   "Post "
label var patent_lib "Patent Library"
esttab  rw1 rw2 rw3 rw4 rw5 rw6 rw7 using "results\Tab3.tex", posthead("") keep( _IposXpaten_1 post )order( post _IposXpaten_1 )   fragment compress nogaps nodepvar noisily ///
			stats(mean_scalar r2 N, fmt(%9.1f %9.2f %18.0g) labels(`"Mean Dep."' `"R2 (within)"' `"Obs."')) nonotes nonumber nomtitle b(1) se(1) obslast  ///
			star(* 0.10 ** 0.05 *** 0.01) label  replace
			
		
erase "data/tmp.dta"
