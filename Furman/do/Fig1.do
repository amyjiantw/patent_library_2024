* Figure 1: Expansion in space

use "data/patent_lib", replace
drop if openingyear==.
ren city_library lib_city
drop if openingyear>1997
gen old = openingyear<1975 
drop if lng<-130

gen gradation=.
replace gradation=1 if openingyear>=1975 & openingyear<=1980
replace gradation=2 if openingyear>1980 & openingyear<=1985
replace gradation=3 if openingyear>1985 & openingyear<=1990
replace gradation=4 if openingyear>1990 & openingyear!=.

label define liblabel 0 "1870-1974" 1 "1975-1980"2 "1981-1985" 3 "1986-1990" 4 "after 1990"
label values gradation liblabel

save "data/oldPTDL", replace


cd "data/"
shp2dta using cb_2016_us_state_500k.shp, database("Newmap") coordinates("Newcoord") genid(id) replace
  
use Newmap.dta, clear

drop if NAME=="Alaska"
drop if NAME==" United States Virgin Islands"
drop if NAME=="Puerto Rico"
drop if NAME=="Hawaii"
drop if NAME=="Guam"
drop if id==33
drop if id==55
drop if id==56

spmap using Newcoord, id(id) point(data("oldPTDL.dta") select(drop if old==0) x(lng) y(lat ) sh (o) si(huge) fc(black)  legenda(on) legtitle("Opened in") leglabel(1870-1974)) legend(size( normal) pos(5)  region(fcolor(white)) symxsize(*0.5))
graph export "../results/Fig1a.pdf", replace


spmap using Newcoord, id(id) point(data("oldPTDL.dta") select(drop if old==1) by(gradation) x(lng) y(lat ) sh (O D T S)  si(large large large large) fc(gs4 gs7 gs10 gs13)  legenda(on) legtitle("Opened in") )  legend(size( normal) pos(5)  region(fcolor(white)) symxsize(*0.5))
graph export "../results/Fig1b.pdf", replace


cd "$dir"



