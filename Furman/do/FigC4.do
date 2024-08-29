* Figure C-4

* C-4a
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
unab k: pat_subcat_*

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

unab k: pat_cat_*


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

replace subcategory = subinstr(subcategory, "pat_subcat_", "", .)
replace subcategory = subinstr(subcategory, "pat_cat_", "", .)

destring subcategory, replace
replace subcategory = subcategory*10 if subcategory<10
ren subcategory subcat
replace counter = (counter*-1)+43
merge m:1 subcat using "data/subcat_label", update
replace label_ex = "Overall" if subcat==10
replace label_ex = "Overall" if subcat==20
replace label_ex = "Overall" if subcat==30
replace label_ex ="Overall" if subcat==40
replace label_ex = "Overall" if subcat==50
replace label_ex = "Overall" if subcat==60

drop counter
drop if upper==.
gsort - subcat
gen counter = _n

replace counter = counter+2 if counter>10
replace counter = counter+2 if counter>19
replace counter = counter+2 if counter>29
replace counter = counter+2 if counter>36
replace counter = counter+2 if counter>44

set obs 49
replace counter = 11 in 44
replace counter = 20 in 45
replace counter = 30 in 46
replace counter = 37 in 47
replace counter = 45 in 48
replace counter = 54 in 49

replace label_ex = "Category: Chemical" if counter==54
replace label_ex = "Category: Communication & Computer"  if counter==45
replace label_ex = "Category: Drugs & Medical"  if counter==37
replace label_ex ="Category: Electrical & Electronic"  if counter==30
replace label_ex = "Category: Mechanical"  if counter==20
replace label_ex = "Category: Others"  if counter==11

labmask counter, values(label_ex) 
gen significant = upper<0 | lower>0

twoway (rcap upper lower counter, horizontal)  (scatter counter b if significant==1, color(red) msymbol(d)) (scatter counter b if significant==0, color(edkblue) msymbol(dh)), ytitle("") legend(off) xline(0)  ylabel(1	2	3	4	5	6	7	8	9	10  11 "Misc: Others"	13	14	15	16	17	18	19 20	22	23	24	25	26	27	28	29 30	32	33	34	35	36 37	39	40	41	42	43	44 45	47	48	49	50	51	52	53	54,  valuelabel labsize(small)   angle(0)  )   ysize(8)  
graph export "results\FigC4a.pdf", replace 


* C-4b
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
unab k: pat_area35_*

local i = 1
foreach x in   `k' {
quietly{
xtreg `x' _IposXpaten_1 post  patent_lib $controls2 [aweight=cem_weights], fe cluster(pat_ID) 
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

replace subcategory = subinstr(subcategory, "pat_area35_", "", .)

destring subcategory, replace
ren subcategory area35
replace counter = (counter*-1)+37

merge m:1 area35 using "data\area35_label", update 

cap drop counter
drop if upper==.
gsort - area35
gen counter = _n

labmask counter, values(label_ex) 

gen significant = upper<0 | lower>0
replace upper=. if upper>5 & lower<-5
replace lower=. if upper==.
twoway (rcap upper lower counter, horizontal)  (scatter counter b if significant==1, color(red) msymbol(d)) (scatter counter b if significant==0, color(edkblue) msymbol(dh)), ytitle("") legend(off) xline(0)  ylabel(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 ,  valuelabel labsize(small)     )   ysize(8)  
graph export "results\FigC4b.pdf", replace 