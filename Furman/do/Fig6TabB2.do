
use "data/main_work", clear

gen post   = yearsopen10>=0
xi i.post*patent_lib, noomit
xtset identifier yearsopen10
cem pat_ID(#0) stateid(#0), treatment(treated)
drop if cem_matched==0

* Baseline
eststo r0: xtreg pat_pop_distance _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights],  fe cluster(pat_ID) 
sum pat_pop_distance 
estadd scalar mean_scalar = r(mean)

* Add matching on university library
drop uni_library
gen uni_library=regexm(ParentInstitutionofLibrary, "University")
gen control_uni=regexm(LibraryType, "Academic")
replace uni_library = 0 if control_uni==0
xi i.post*patent_lib, noomit
xtset identifier yearsopen10

preserve
cem pat_ID(#0) stateid(#0) uni_library(#0), treatment(treated)
drop if cem_matched==0

eststo r3: xtreg pat_pop_distance _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights],  fe cluster(pat_ID) 
sum pat_pop_distance 
estadd scalar mean_scalar = r(mean)
restore

* Add matching on patenting per capita
preserve
bysort pat_ID identifier: egen sim_size=sum((yearsopen10<0)*pat_pop_distance)
cem pat_ID(#0) stateid(#0)  uni_library(#0) sim_size(#5), treatment(treated)
drop if cem_matched==0

eststo r4: xtreg pat_pop_distance _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights],  fe cluster(pat_ID) 
sum pat_pop_distance 
estadd scalar mean_scalar = r(mean)
restore

* Add matching on patenting per capita and on population
preserve
bysort pat_ID identifier: egen sim_size=sum((yearsopen10<0)*pat_pop_distance)
bysort pat_ID identifier: egen sim_size_pop=sum((yearsopen10<0)*pop_15m)
cem pat_ID(#0) stateid(#0)  uni_library(#0) sim_size(#5) sim_size_pop(#5), treatment(treated)
drop if cem_matched==0

eststo r5: xtreg pat_pop_distance _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights],  fe cluster(pat_ID) 
sum pat_pop_distance 
estadd scalar mean_scalar = r(mean)
restore


* Distance match: < 100 miles
use "data/main_work_distance_matched", clear
keep if pat_FDL_dist<=100 | pat_FDL_dist==.
gen post   = yearsopen10>=0
xi i.post*patent_lib, noomit
xtset identifier yearsopen10
cem pat_ID(#0), treatment(treated)
drop if cem_matched==0

eststo r6: xtreg pat_pop_distance _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights],  fe cluster(pat_ID) 
sum pat_pop_distance 
estadd scalar mean_scalar = r(mean)


* Distance match: 5 closest
use"data\main_work_distance_matched", clear
replace pat_FDL_dist = -pat_FDL_dist
bysort pat_ID yearsopen patent_lib : egen rank = rank(pat_FDL_dist) if pat_FDL_dist!=0,  track
keep if rank<6 | rank==.
egen yearID = group(yearsopen10)
gen post   = yearsopen10>=0
xi i.post*patent_lib, noomit
xtset identifier yearsopen10
cem pat_ID(#0), treatment(treated)
drop if cem_matched==0

eststo r7: xtreg pat_pop_distance _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights],  fe cluster(pat_ID) 
sum pat_pop_distance 
estadd scalar mean_scalar = r(mean)



* Synthetic
	
u "data\patent_characteristics", clear
drop if appln_y>2010
drop if publn_y>2010
drop if lat<23
drop if lon<-130
replace appln_id = inpadoc_family_id
gen summer_other=1 
keep appln_id appln_y summer_other
gduplicates drop
collapse (sum) summer_other, by(appln_y)
save "data\patent_no_by_year.dta", replace


use "data/main_work", clear
keep if patent_lib==1
duplicates drop pat_ID yearsopen10, force
drop patent_lib
merge m:1 appln_y using "data\patent_no_by_year.dta"
keep if _merge==3
gen share = pat_15m/(summer_other)
replace share = . if yearsopen10!=-1
bysort pat_ID: egen mean_share = sum(share)
gen pat_pop_distance_0 = (mean_share*(summer_other))/pop_15m*100000		
ren pat_pop_distance pat_pop_distance_1
reshape long pat_pop_distance_, i(pat_ID yearsopen10) j(patent_lib)
gen post   = yearsopen10>=0
xi i.post*patent_lib, noomit
drop identifier
egen identifier = group(pat_ID patent_lib)
xtset identifier yearsopen10

eststo rs: xtreg pat_pop_distance_ i.yearID2 _IposXpaten_1 post  patent_lib ,  fe cluster(pat_ID) 
sum pat_pop_distance_
estadd scalar mean_scalar = r(mean)		
			
erase "data\patent_no_by_year.dta"


* Test of SUTVA
use "data/main_work", clear
cap drop strata_id mean
drop if patent_lib==1
bys pat_ID: egen cf=min(pat_FDL_dist)
replace patent_lib=(pat_FDL_dist==cf)
replace treated = patent_lib

egen strata_id = group(pat_ID stateid)
bysort strata_id: egen mean = mean(treated)
drop if mean==0 | mean==1
keep if yearsopen10>=-5 & yearsopen10<=5
gen post   = yearsopen10>=0
xi i.post*patent_lib, noomit
xtset identifier yearsopen10
cem pat_ID(#0) stateid(#0), treatment(treated)
drop if cem_matched==0
eststo r2: xtreg pat_pop_distance _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights], fe cluster(pat_ID) 
sum pat_pop_distance
estadd scalar mean_scalar = r(mean)



* Distance
use "data/main_work", clear
gen post   = yearsopen10>=0
xi i.post*patent_lib, noomit
xtset identifier yearsopen10
cem pat_ID(#0) stateid(#0), treatment(treated)
drop if cem_matched==0

foreach x in 50 100  {
eststo rd`x': xtreg pat_pop_`x'm _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights] , fe cluster(pat_ID) 
sum pat_pop_`x'm
estadd scalar mean_scalar = r(mean)
}

label var _IposXpaten_1 "Pat Lib x Post "
label var post   "Post "
label var patent_lib "Patent Library"
	
esttab r0 r3 r4 r5 r6 r7 rs r2  r0 rd50 rd100  using "results\TabB2.tex",  posthead("") keep( _IposXpaten_1 post )order( post _IposXpaten_1 )   fragment compress nogaps nodepvar noisily ///
			stats(mean_scalar r2 N, fmt(%9.1f %9.2f %18.0g) labels(`"Mean Dep."' `"R2 (within)"' `"Obs."')) nonotes nonumber nomtitle b(1) se(1) obslast  ///
			star(* 0.10 ** 0.05 *** 0.01) label  replace			
			
mat b= r(coefs)
cap drop b se counter
gen b = .
gen se = . 
gen counter = .
forvalues i = 1(1)11{
local j = (`i'*3)-2
local k = `j'+1
replace b = b[2,`j'] in `i'
replace se = b[2,`k'] in `i'
replace counter = `i' in `i'			
}

gen upper = b + 1.68*se
gen lower = b - 1.68*se

replace counter = (counter*-1)+12.5

gen significant = upper<0 | lower>0
replace lower=. if upper==.



replace counter = -4 if counter == 1.5
replace counter = -3 if counter == 2.5
replace counter = -2 if counter == 3.5
replace counter = 0.5 if counter == 4.5
replace counter = 2 if counter == 5.5
replace counter = 3.5 if counter == 6.5
replace counter = 4.5 if counter == 7.5
replace counter = 7 if counter == 8.5
replace counter = 8 if counter == 9.5
replace counter = 9 if counter == 10.5

gen mlabel = ""
replace mlabel = "Increase by 3.2 / 18% relative to baseline"  if counter == 11.5
replace mlabel = "2.9 / 17%"  if counter == 9
replace mlabel = "2.4 / 19%"  if counter == 8
replace mlabel = "2.4 / 20%"  if counter == 7
replace mlabel = "1.9 / 8%"  if counter == 4.5
replace mlabel = "3.3 / 16%"  if counter == 3.5
replace mlabel = "2.4 / 12%"  if counter == 2
replace mlabel = "-0.5 / -3%"  if counter == 0.5
replace mlabel = "3.2 / 18%"  if counter == -2
replace mlabel = "2.1 / 12%"  if counter == -3
replace mlabel = "-1.4 / -7%"  if counter == -4


twoway (rcap upper lower counter, horizontal color(edkblue))  (scatter counter b if significant==1, color(red) msymbol(d) mlabel(mlabel) mlabcolor(black) mlabsize(2) mlabp(6) ) (scatter counter b if significant==0, color(edkblue) msymbol(dh) mlabel(mlabel) mlabcolor(black) mlabsize(2) mlabp(6)), ytitle("") legend(off) xline(0)  ylabel(-4 "11) in 50-100 mi"  -3 "10) in 15-50 mi" -2 "9) <= 15 mi" -1 "{bf:Patents p.c. in...}" 0.5 "8) Pseudo opening"  2 "7) Synthetic libraries" 3.5 "6) 5 closest" 4.5 "5) <100 mi" 5.5 "{bf:Distance Match...}" 7 "4) + Population" 8 "3)  + Patent p.c." 9 "2) +University" 10 "{bf:Add matching on...}" 11.5 "1) Baseline", angle(0)      )   ysize(6)  xline(3.216079, lc(gs12)) yscale(range(-4.5 11.5))
graph export "results\Fig6.pdf", replace 

	