* Table B-3

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

*No CEM Weights
eststo r1: xtreg pat_pop_distance _IposXpaten_1 post  patent_lib i.yearID2,  fe cluster(pat_ID) 
sum pat_pop_distance 
estadd scalar mean_scalar = r(mean)

*25m Circle
eststo r2: xtreg pat_pop_distance25m _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights],  fe cluster(pat_ID) 
sum pat_pop_distance25m 
estadd scalar mean_scalar = r(mean)

*50m Circle
eststo r3: xtreg pat_pop_distance50m _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights],  fe cluster(pat_ID) 
sum pat_pop_distance50m 
estadd scalar mean_scalar = r(mean)

*Solo/Co-located
eststo r4: xtreg pat_pop_onecity _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights],  fe cluster(pat_ID) 
sum pat_pop_onecity 
estadd scalar mean_scalar = r(mean)

* Number patents on left hand side, time-varying population
eststo r6: xtreg pat_15m _IposXpaten_1 post  patent_lib  pop_nber15m i.yearID2 [aweight=cem_weights],  fe cluster(pat_ID) 
sum pat_15m 
estadd scalar mean_scalar = r(mean)

* Log patents on left hand side, time-varying population
g lpat=ln(pat_15m+1)
eststo r7: xtreg lpat _IposXpaten_1 post  patent_lib  pop_nber15m i.yearID2 [aweight=cem_weights],  fe cluster(pat_ID) 
sum lpat 
estadd scalar mean_scalar = r(mean)

* Patent Library-Specific Trends
eststo r5: xi: reg pat_pop_distance i.post*patent_lib c.yearsopen10##i.pat_ID [aweight=cem_weights],  cluster(pat_ID)
sum pat_pop_distance 
estadd scalar mean_scalar = r(mean)



label var _IposXpaten_1 "Pat Lib x Post "
label var post   "Post "
label var patent_lib "Patent Library"
esttab r0 r1 r5  r4  r2 r3 r6 r7 using "results\TabB3.tex",  posthead("") keep( _IposXpaten_1 post )order( post _IposXpaten_1 )   fragment compress nogaps nodepvar noisily ///
			stats(mean_scalar r2 N, fmt(%9.1f %9.2f %18.0g) labels(`"Mean Dep."' `"R2 (within)"' `"Obs."')) nonotes nonumber nomtitle b(1) se(1) obslast  ///
			star(* 0.10 ** 0.05 *** 0.01) label  replace