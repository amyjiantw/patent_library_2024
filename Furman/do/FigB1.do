* Figure B-1

* Prepare different control groups
{
	
* Snythetic
{
	
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

use "data\main_work", clear
drop if appln_y<1975

keep if patent_lib==1
duplicates drop pat_ID yearsopen10, force
keep if yearsopen10>=-5 & yearsopen10<=5

joinby appln_y using "data\patent_no_by_year.dta", unmatched(master)
gen share = pat_15m/summer_other

replace share = . if yearsopen10!=-1
bysort pat_ID: egen mean_share = sum(share)

gen pat_pop_distance_synthetic = (mean_share*summer_other)/pop_15m*100000

collapse (mean) pat_pop_distance pat_pop_distance_synthetic, by (patent_lib yearsopen10)
drop patent_lib 
save "data/pat_pop_distance_synthetic", replace
}


* Within 
{
use "data/panel_pat_fdl", clear

keep if patent_lib
joinby pat_ID using "data\listofpatentlibs.dta"
drop if patent_lib == 1 & patent_lib_institutions==0
duplicates drop pat_ID appln_y, force
keep if openingyear>1975 & openingyear<1998   
drop if appln_y<1975

keep if pat_ID!=15 | pat_ID==.  
keep pat_ID pat_pop_distance pat_pop_total_forward_cites  yearsopen10 patent_lib appln_y openingyear pat_pop_small pat_pop_big pat_pop_young  pat_pop_old pat_pop_50m pat_mainarea*
save tmp, replace
keep pat_ID yearsopen10 patent_lib appln_y openingyear
foreach x in pat_ID yearsopen10 patent_lib  openingyear  {
ren `x' `x'_o
}
joinby appln_y using tmp, unmatched(master)
drop patent_lib patent_lib_o
gen patent_lib = pat_ID == pat_ID_o
keep if yearsopen10<0 | patent_lib==1
keep if openingyear_o<openingyear | patent_lib==1

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

gen one = 1

xtreg pat_pop_distance i.appln_y, fe
predict pat_pop_distance_res, xb
replace pat_pop_distance_res= pat_pop_distance - pat_pop_distance_res
collapse (mean) pat_pop_distance pat_pop_distance_res (sum) one  , by (patent_lib  pat_ID_o yearsopen10_o)
reshape wide pat_pop_distance pat_pop_distance_res one, i(pat_ID_o yearsopen10_o ) j(patent_lib)
drop if pat_pop_distance0==.
drop if pat_pop_distance1==.

bysort pat_ID: egen n = nvals(yearsopen10)

collapse (mean) pat_pop_distance0 pat_pop_distance1 pat_pop_distance_res1 pat_pop_distance_res0 , by ( yearsopen10_o)
ren pat_pop_distance0 pat_pop_distance_w0
ren pat_pop_distance1 pat_pop_distance_w1
ren pat_pop_distance_res1 pat_pop_distance_res_w1
ren pat_pop_distance_res0 pat_pop_distance_res_w0
ren yearsopen10_o yearsopen10
save "data/within", replace
}

* Closest match: university size etc
{
use "data/main_work", clear
drop if appln_y<1975

bysort pat_ID identifier: egen sim_size=sum((yearsopen10<0)*pat_pop_distance)
cem pat_ID(#0) stateid(#0)  uni_library(#0) sim_size(#5), treatment(treated)
drop if cem_matched==0

gen one = 1
collapse (mean) pat_pop_distance  (sum) one , by (patent_lib pat_ID yearsopen10)
reshape wide pat_pop_distance  one, i(pat_ID yearsopen10) j(patent_lib)
 
collapse (mean) pat_pop_distance0 pat_pop_distance1  , by ( yearsopen10)
ren pat_pop_distance0 pat_pop_distance_close_match_0
ren pat_pop_distance1 pat_pop_distance_close_match_1
save "data/close_match", replace
}


* Closest match: university size etc
{
use "data/main_work", clear
drop if appln_y<1975

keep if pat_FDL_dist<=100 | pat_FDL_dist==.

egen yearID = group(yearsopen10)
gen post   = yearsopen10>=0
xi i.post*patent_lib, noomit
xtset identifier yearsopen10
cem pat_ID(#0), treatment(treated)
drop if cem_matched==0

gen one = 1
collapse (mean) pat_pop_distance  (sum) one , by (patent_lib pat_ID yearsopen10)
reshape wide pat_pop_distance  one, i(pat_ID yearsopen10) j(patent_lib)
 
collapse (mean) pat_pop_distance0 pat_pop_distance1  , by ( yearsopen10)
ren pat_pop_distance0 pat_pop_distance_100_0
ren pat_pop_distance1 pat_pop_distance_100_1
save "data/within_100", replace
}

}


* Produce Figures
{
use "data/main_work", clear
drop if appln_y<1975
bysort pat_ID yearsopen patent_lib : egen rank = rank(pat_FDL_dist),  unique 
gen pat_pop_distance_5closest =  pat_pop_distance if rank<6

cem pat_ID(#0) stateid(#0), treatment(treated)
drop if cem_matched==0

gen one = 1

collapse (mean) pat_pop_distance pat_pop_distance_5closest (sum) one , by (patent_lib pat_ID yearsopen10)
reshape wide pat_pop_distance pat_pop_distance_5closest one, i(pat_ID yearsopen10) j(patent_lib)
 
collapse (mean) pat_pop_distance0 pat_pop_distance1 pat_pop_distance_5closest0 pat_pop_distance_5closest1, by ( yearsopen10)
merge 1:1 yearsopen10 using "data/within"
drop _merge
merge 1:1 yearsopen10 using "data/pat_pop_distance_synthetic"
drop _merge
merge 1:1 yearsopen10 using "data/close_match"
drop _merge
merge 1:1 yearsopen10 using "data/within_100"

twoway   (connected pat_pop_distance1 pat_pop_distance0 pat_pop_distance_w0   pat_pop_distance_synthetic   yearsopen10 , color( red edkblue eltblue eltgreen  emidblue) msize(large large large large large) lpattern(solid dash dash dash dash dash) msymbol(oh oh d  x) lwidth(thick thick thick thick thick )) ,   xtitle (Year relative to library opening) xlabel(#10) ytitle (Average new patents p.c. within 15 miles) legend(on order(1  2 4 3) rows(7) label(1 "Patent Libraries") label(2 "Federal Depository Libraries") label(3 "Within") label(4 "Synthetic") pos(11) ring(0)) xline(0, lc(gray)) 
graph export "results\FigB1a.pdf", replace 


foreach x in pat_pop_distance_100_0 pat_pop_distance0 pat_pop_distance1 pat_pop_distance_w0 pat_pop_distance_w1 pat_pop_distance_5closest0 pat_pop_distance_synthetic pat_pop_distance_res_w1  pat_pop_distance_res_w0 pat_pop_distance_close_match_0 pat_pop_distance_close_match_1 { 
egen m = max((yearsopen10==-1)*`x')
replace `x' = `x' -  m
drop m
}
twoway   (connected     pat_pop_distance0 pat_pop_distance_w0   pat_pop_distance_synthetic pat_pop_distance1  yearsopen10 , color(   edkblue eltblue eltgreen   red) msize(large large large large large) lpattern( dash dash dash solid) msymbol( oh d  x oh) lwidth(thick thick thick thick thick )) ,   xtitle (Year relative to library opening) xlabel(#10) ylabel(-5(5)15) ytitle (Average new patents p.c. within 15 miles) legend(on order(4 1  2  3) rows(7) label(4 "Patent Libraries") label(1 "Federal Depository Libraries") label(2 "Within") label(3 "Synthetic") pos(11) ring(0)) xline(0, lc(gray)) 
graph export "results\FigB1b.pdf", replace 


}

* Erase data sets that are only used in this Figure

erase "data/patent_no_by_year.dta"
erase "data/pat_pop_distance_synthetic.dta"
erase "data/within.dta"
erase "data/close_match.dta"
erase "data/within_100.dta"
