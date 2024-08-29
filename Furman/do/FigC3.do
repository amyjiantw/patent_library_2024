* Figure C-3

use "data/main_work", clear
egen yearID = group(yearsopen10)
gen post   = yearsopen10>=0
xi i.post*patent_lib, noomit
xtset identifier yearsopen10
cem pat_ID(#0) stateid(#0) $matched, treatment(treated)
drop if cem_matched==0

gen b = .
gen se = .
gen subcategory = ""
gen counter = .
unab k: pat_area30_*

local i = 1
foreach x in  `k' {
quietly{
xtreg `x' _IposXpaten_1 post  patent_lib i.yearID2 [aweight=cem_weights], fe cluster(pat_ID) 
replace b = _b[_IposXpaten_1] in `i'
replace se = _se[_IposXpaten_1] in `i'
replace subcategory = "`x'" in `i'
replace counter = `i' in `i'
local i = `i'+1
}
}


keep if counter!=.

gen upper = b + 1.68*se
gen lower = b - 1.68*se

replace subcategory = subinstr(subcategory, "pat_area30_", "", .)

destring subcategory, replace
ren subcategory area30
replace counter = (counter*-1)+37

merge m:1 area30 using "data\area30_label", update

cap drop counter
drop if upper==.
gsort - area30
gen counter = _n

replace counter = counter+2 if counter>2
replace counter = counter+2 if counter>10
replace counter = counter+2 if counter>17
replace counter = counter+2 if counter>27
replace counter = counter+2 if counter>33

set obs 36
replace counter = 3 in 31
replace counter = 11 in 32
replace counter = 18 in 33
replace counter = 28 in 34
replace counter = 34 in 35
replace counter = 41 in 36


replace label_ex = "Other Fields" if counter==3
replace label_ex = "Mechanical Engineering"  if counter==11
replace label_ex = "Process Engineering"  if counter==18
replace label_ex ="Chemistry"  if counter==28
replace label_ex = "Instruments"  if counter==34
replace label_ex = "Electrical Engineering"  if counter==41

labmask counter, values(label_ex) 
gen significant = upper<0 | lower>0


preserve 
keep if counter>18
twoway (rcap upper lower counter, horizontal)  (scatter counter b if significant==1 , color(red) msymbol(d)) (scatter counter b if significant==0, color(edkblue) msymbol(dh)), ytitle("") legend(off) xline(0)  ylabel(  20  21 22 23 24 25 26 27 28   30 31 32 33 34  36 37 38 39 40 41,  valuelabel     tlcolor(none) )   ysize(5)  yline( 4 12 29 35)  
graph export "results\FigC3a.pdf", replace 
restore

preserve 
keep if counter<=18
twoway (rcap upper lower counter, horizontal)  (scatter counter b if significant==1 , color(red) msymbol(d)) (scatter counter b if significant==0, color(edkblue) msymbol(dh)), ytitle("") legend(off) xline(0)  ylabel(1 2 3  5 6 7 8 9 10 11  13 14 15 16 17 18 ,  valuelabel     tlcolor(none) )   ysize(5)  yline( 4 12 29 35)  
graph export "results\FigC3b.pdf", replace 
restore