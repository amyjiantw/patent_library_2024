* Figure B-3

use "data/main_work", clear

egen yearID = group(yearsopen10)
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

local i = 1
foreach x in pat_pop_distance pat_independent_pc pat_company_pc   pat_uni_hosp_pc pat_non_profit_pc  {
xtreg `x' _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights],fe  cluster(pat_ID) 
sum `x'
estadd scalar mean_scalar = r(mean)
replace b = _b[ _IposXpaten_1] in `i'
replace se = _se[ _IposXpaten_1] in `i'
replace counter = `i' in `i'
replace name = "`x'" in `i'
local i = `i'+1

}

xtreg pat_pop_distance _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights] if hist_high==1,fe  cluster(pat_ID)
sum pat_pop_distance if hist_high==1
estadd scalar mean_scalar = r(mean)
replace b = _b[ _IposXpaten_1] in `i'
replace se = _se[ _IposXpaten_1] in `i'
replace counter = `i' in `i'
replace name = "High" in `i'
local i = `i'+1

xtreg pat_pop_distance _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights] if hist_high==0,  fe cluster(pat_ID)
sum pat_pop_distance if hist_high==0
estadd scalar mean_scalar = r(mean)
replace b = _b[ _IposXpaten_1] in `i'
replace se = _se[ _IposXpaten_1] in `i'
replace counter = `i' in `i'
replace name = "Low" in `i'
local i = `i'+1

bysort pat_ID: egen uni_pat_lib = max(patent_lib*uni_library)

xtreg pat_pop_distance _IposXpaten_1 post  patent_lib i.yearID2  [aweight=cem_weights] if uni_pat_lib==1 ,  fe cluster(pat_ID)
sum pat_pop_distance if uni_library==1
estadd scalar mean_scalar = r(mean)

xtreg pat_pop_distance _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights] if uni_pat_lib==0 , fe  cluster(pat_ID)
sum pat_pop_distance if uni_library==0
estadd scalar mean_scalar = r(mean)


gen upper = b + 1.68*se
gen lower = b - 1.68*se


replace counter = (counter*-1)+8

gen significant = upper<0 | lower>0
twoway (rcap upper lower counter, horizontal)  (scatter counter b if significant==1, color(red) msymbol(d)) (scatter counter b if significant==0, color(edkblue) msymbol(dh)), ytitle("") ysize(4) legend(off) xline(0) ylabel(1 "Historically Low Patenting Regions" 2 "Historically High Patenting Regions" 3 "Patents assigned to Government / Military / Non-Profit" 4 "Patents assigned to Universities" 5 "Patents assigned to Companies" 6 "Patents assigned to Individual Inventor" 7 "Baseline" ,  valuelabel labsize(small)) 
graph export "results\FigB3.pdf", replace 
