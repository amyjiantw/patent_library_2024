*Table B-5

use "data/main_work", clear

egen yearID = group(yearsopen10)
gen post   = yearsopen10>=0
xi i.post*patent_lib, noomit
xtset identifier yearsopen10
cem pat_ID(#0) stateid(#0) $matched, treatment(treated)
drop if cem_matched==0

* Baseline
eststo r0: xtreg pat_pop_distance _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights],  fe cluster(pat_ID) 
sum pat_pop_distance 
estadd scalar mean_scalar = r(mean)


* Baseline for sample with Patent Attorneys
eststo r0b: xtreg pat_pop_distance _IposXpaten_1 post  patent_lib i.yearID2 if patent_attorneys_15m!=. [aweight=cem_weights],  fe cluster(pat_ID) 
sum pat_pop_distance if patent_attorneys_15m!=. // 
estadd scalar mean_scalar = r(mean)


* Including Patent Attorneys
eststo r1: xtreg pat_pop_distance _IposXpaten_1 post  patent_lib i.yearID2 pat_attorneys_distance if patent_attorneys_15m!=. [aweight=cem_weights],  fe cluster(pat_ID) 
sum pat_pop_distance if patent_attorneys_15m!=.
estadd scalar mean_scalar = r(mean)

* Predicting Patent Attorneys
eststo r2: xtreg pat_attorneys_distance _IposXpaten_1 post  patent_lib i.yearID2 if patent_attorneys_15m!=.  [aweight=cem_weights],  fe cluster(pat_ID) 
sum pat_attorneys_distance if patent_attorneys_15m!=.
estadd scalar mean_scalar = r(mean)

label var _IposXpaten_1 "Pat Lib x Post "
label var post   "Post "
label var patent_lib "Patent Library"
label var pat_attorneys_distance "Patent Attorneys p.c."

esttab r0 r0b r1 r2 using "results\TabB5.tex",  posthead("") keep( _IposXpaten_1 post pat_attorneys_distance) order( post _IposXpaten_1 )   fragment compress nogaps nodepvar noisily ///
			stats(mean_scalar r2 N, fmt(%9.1f %9.2f %18.0g) labels(`"Mean Dep."' `"R2 (within)"' `"Obs."')) nonotes nonumber nomtitle b(1) se(1) obslast  ///
			star(* 0.10 ** 0.05 *** 0.01) label  replace