* Figure 3

u "data\main_work", clear
cap drop m
bysort pat_ID: egen m = mean(patent_lib)
keep if openingyear>1974 | openingyear<1998
keep lat lng patent_lib 

drop if lng<-130
replace patent_lib = patent_lib*-1+1
label define liblabel 1 "Federal Depository library" 0 "Patent library" 
label values patent_lib liblabel
save "data\pat_fdl_lat_lng", replace


use "data\Newmap.dta", clear

drop if NAME=="Alaska"
drop if NAME==" United States Virgin Islands"
drop if NAME=="Puerto Rico"
drop if NAME=="Hawaii"
drop if NAME=="Guam"
drop if id==33
drop if id==55
drop if id==56

spmap using "data\Newcoord", id(id) point(data("data/pat_fdl_lat_lng.dta") by(patent_lib) x(lng) y(lat ) si(medium) sh(circle circle_hollow ) fc( red edkblue)  legenda(on) )  legend(size( normal) pos(5)  region(fcolor(white)) symxsize(*0.5))
graph export "results\Fig3.pdf", replace


* Erase Map Files from Fig 1 & 3
erase "data/Newcoord.dta"
erase "data/Newmap.dta"
erase "data/oldPTDL.dta"
erase "data/pat_fdl_lat_lng.dta"
