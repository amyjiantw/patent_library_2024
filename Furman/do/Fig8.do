* Figure 8 

*8a 
use "data/main_work", clear 
keep if appln_y>1974
replace pat_pop_distance=nw_r_nw_i_pop
xtset identifier appln_y
keep pat_ID stateid treated pat_pop_distance yearsopen10  identifier patent_lib uni_library
egen strata_id = group(pat_ID stateid )
bysort strata_id: egen mean = mean(treated)
drop if mean==0 | mean==1
gen one = 1

areg pat_pop_distance, absorb(identifier)
gen patents = pat_pop_distance

collapse (mean) patents (sum) one   , by(pat_ID strata_id yearsopen10 treated)
reshape wide patents one, i(strata_id yearsopen10 ) j(treated)

gen one = one1 + one0
gen diff = patents1-patents0
drop  patents1 patents0 
save "data/temp", replace
collapse  (mean) diff [fweight=one1]  , by(yearsopen10)
gen id = 1 
tempfile file1
cap save `file1'

*****

forvalues i = 2(1)1000 {
use "data/temp", replace
bsample  ,      cluster(pat_ID) 
collapse  (mean) diff [fweight=one1]  , by(yearsopen10)
gen id = `i' 
cap append using `file1'
tempfile file1
cap save `file1'
}

ren yearsopen10 year
replace year=year+10

reshape wide diff, i(id) j(year)
gen  mean = diff9
forvalues i = 5(1)15 {
replace diff`i' = diff`i'-mean
}

reshape long diff, i(id) j(year)
replace year=year-10

scatter diff year
bys year: egen lower=pctile(diff), p(2.5)
bys year: egen upper=pctile(diff), p(97.5)
collapse (mean) diff upper  lower, by(year)
set scheme lean1, perm

twoway (rcap upper lower year, lpattern(solid) color(edkblue)) (connected diff year , lpattern(dash) color(edkblue))  , ytitle(Excess Patents p.c. within 15 miles) legend(off) xline(0, lcolor(gs10))    xtitle("Year relative to opening") yline(0) ysize(5) yscale(range(-4 4)) ylabel(-4(1)4) xlabel(-5(1)5) ylabel(, labsize(large)) xlabel(, labsize(large))
graph export "results\Fig8a.pdf", replace



*8b 
use "data/main_work", clear 
keep if appln_y>1974
replace pat_pop_distance=postw_r_i_pop
xtset identifier appln_y
keep pat_ID stateid treated pat_pop_distance yearsopen10  identifier patent_lib uni_library
egen strata_id = group(pat_ID stateid )
bysort strata_id: egen mean = mean(treated)
drop if mean==0 | mean==1
gen one = 1

areg pat_pop_distance, absorb(identifier)
gen patents = pat_pop_distance

collapse (mean) patents (sum) one   , by(pat_ID strata_id yearsopen10 treated)
reshape wide patents one, i(strata_id yearsopen10 ) j(treated)

gen one = one1 + one0
gen diff = patents1-patents0
drop  patents1 patents0 
save "data/temp", replace
collapse  (mean) diff [fweight=one1]  , by(yearsopen10)
gen id = 1 
tempfile file1
cap save `file1'

*****

forvalues i = 2(1)1000 {
use "data/temp", replace
bsample  ,      cluster(pat_ID) 
collapse  (mean) diff [fweight=one1]  , by(yearsopen10)
gen id = `i' 
cap append using `file1'
tempfile file1
cap save `file1'
}

ren yearsopen10 year
replace year=year+10

reshape wide diff, i(id) j(year)
gen  mean = diff9
forvalues i = 5(1)15 {
replace diff`i' = diff`i'-mean
}

reshape long diff, i(id) j(year)
replace year=year-10

scatter diff year
bys year: egen lower=pctile(diff), p(2.5)
bys year: egen upper=pctile(diff), p(97.5)
collapse (mean) diff upper  lower, by(year)
set scheme lean1, perm

twoway (rcap upper lower year, lpattern(solid) color(edkblue)) (connected diff year , lpattern(dash) color(edkblue))  , ytitle(Excess Patents p.c. within 15 miles) legend(off) xline(0, lcolor(gs10))    xtitle("Year relative to opening") yline(0) ysize(5) yscale(range(-4 4)) ylabel(-4(1)4) xlabel(-5(1)5) ylabel(, labsize(large)) xlabel(, labsize(large))
graph export "results\Fig8b.pdf", replace



*8c 
use "data/main_work", clear 
keep if appln_y>1974
replace pat_pop_distance=nw_w_i_pop
xtset identifier appln_y
keep pat_ID stateid treated pat_pop_distance yearsopen10  identifier patent_lib uni_library
egen strata_id = group(pat_ID stateid )
bysort strata_id: egen mean = mean(treated)
drop if mean==0 | mean==1
gen one = 1

areg pat_pop_distance, absorb(identifier)
gen patents = pat_pop_distance

collapse (mean) patents (sum) one   , by(pat_ID strata_id yearsopen10 treated)
reshape wide patents one, i(strata_id yearsopen10 ) j(treated)

gen one = one1 + one0
gen diff = patents1-patents0
drop  patents1 patents0 
save "data/temp", replace
collapse  (mean) diff [fweight=one1]  , by(yearsopen10)
gen id = 1 
tempfile file1
cap save `file1'

*****

forvalues i = 2(1)1000 {
use "data/temp", replace
bsample  ,      cluster(pat_ID) 
collapse  (mean) diff [fweight=one1]  , by(yearsopen10)
gen id = `i' 
cap append using `file1'
tempfile file1
cap save `file1'
}

ren yearsopen10 year
replace year=year+10

reshape wide diff, i(id) j(year)
gen  mean = diff9
forvalues i = 5(1)15 {
replace diff`i' = diff`i'-mean
}

reshape long diff, i(id) j(year)
replace year=year-10

scatter diff year
bys year: egen lower=pctile(diff), p(2.5)
bys year: egen upper=pctile(diff), p(97.5)
collapse (mean) diff upper  lower, by(year)
set scheme lean1, perm

twoway (rcap upper lower year, lpattern(solid) color(edkblue)) (connected diff year , lpattern(dash) color(edkblue))  , ytitle(Excess Patents p.c. within 15 miles) legend(off) xline(0, lcolor(gs10))    xtitle("Year relative to opening") yline(0) ysize(5) yscale(range(-4 4)) ylabel(-4(1)4) xlabel(-5(1)5) ylabel(, labsize(large)) xlabel(, labsize(large))
graph export "results\Fig8c.pdf", replace


*8d
use "data/main_work", clear 
keep if appln_y>1974
replace pat_pop_distance=restnew_i_pop
xtset identifier appln_y
keep pat_ID stateid treated pat_pop_distance yearsopen10  identifier patent_lib uni_library
egen strata_id = group(pat_ID stateid )
bysort strata_id: egen mean = mean(treated)
drop if mean==0 | mean==1
gen one = 1

areg pat_pop_distance, absorb(identifier)
gen patents = pat_pop_distance

collapse (mean) patents (sum) one   , by(pat_ID strata_id yearsopen10 treated)
reshape wide patents one, i(strata_id yearsopen10 ) j(treated)

gen one = one1 + one0
gen diff = patents1-patents0
drop  patents1 patents0 
save "data/temp", replace
collapse  (mean) diff [fweight=one1]  , by(yearsopen10)
gen id = 1 
tempfile file1
cap save `file1'

*****

forvalues i = 2(1)1000 {
use "data/temp", replace
bsample  ,      cluster(pat_ID) 
collapse  (mean) diff [fweight=one1]  , by(yearsopen10)
gen id = `i' 
cap append using `file1'
tempfile file1
cap save `file1'
}

ren yearsopen10 year
replace year=year+10

reshape wide diff, i(id) j(year)
gen  mean = diff9
forvalues i = 5(1)15 {
replace diff`i' = diff`i'-mean
}

reshape long diff, i(id) j(year)
replace year=year-10

scatter diff year
bys year: egen lower=pctile(diff), p(2.5)
bys year: egen upper=pctile(diff), p(97.5)
collapse (mean) diff upper  lower, by(year)
set scheme lean1, perm

twoway (rcap upper lower year, lpattern(solid) color(edkblue)) (connected diff year , lpattern(dash) color(edkblue))  , ytitle(Excess Patents p.c. within 15 miles) legend(off) xline(0, lcolor(gs10))    xtitle("Year relative to opening") yline(0) ysize(5) yscale(range(-4 4)) ylabel(-4(1)4) xlabel(-5(1)5) ylabel(, labsize(large)) xlabel(, labsize(large))
graph export "results\Fig8d.pdf", replace


erase "data/temp.dta"