* Data Preparaton File 
* Furman, Nagler, Watzinger: "Disclosure and Subsequent Innovation: Evidence from the Patent Depository Library Program"
* AEJ: Economic Policy
* December 2020

global dropbox "D:\Dropbox\02_Patent_Libraries"
global data "$dropbox\Data\raw"
global prog "$dropbox\Prog"
global proc "$dropbox\Prog"
global attorneysource "$dropbox\Data\Patent Attorneys"


global mapdir "$dropbox\Data\map" 
global mapdir "$dropbox\Data\map" 

*global patstat "E:\Patstat\data\"
global patstat "\\10.153.102.26\sfkw-backup$\Markus\data"
global patstat "E:\PATSTAT\data"


*****************************************************************************
* A) Population and other regional data: population_tract.dta; time_var_pop.dta; population_nber.dta
*****************************************************************************
{
* I) Map MSAs to counties: msa_zip_link
{

* Census data for zip to lat long
import delimited "$data\zip_lat_lon\Gaz_zcta_national.txt", delimiter(tab) clear 
keep geoid intptlat  intptlong
ren geoid zip
ren intptlat lat_zip
ren intptlong lon_zip
save "$prog\zip_lat_lon", replace


import delimited "$data\histpat\Gaz_counties_national.txt", clear
ren geoid fips
drop aland awater awater_sqmi hu10
ren intptlat lat_fips
ren intptlong lng_fips
ren usps state
save "$prog\fips_lat_lon", replace
}

* II) Population data from latest Census 
{
import delimited "$data\histpat\Gaz_places_national.txt", clear 
ren pop10 population

ren intptlat lat_municipality
ren intptlong lon_municipality
keep lat_* lon_* population
save "$prog\population_tract", replace

}


* III) Population data from NBER
{
use "$data\NBER population\county_population.dta", clear
destring fips, replace
keep fips pop*
drop pop2003-pop2014
drop if pop1970==. 
reshape long pop, i(fips) j(appln_y)
drop if pop==.
ren pop pop_nber
merge m:1 fips using "$prog\fips_lat_lon"
keep if _merge==3
drop _merge
keep fips appln_y pop_nber lat_fips lng_fips
ren lat_fips lat_municipality
ren lng_fips lon_municipality
save "$prog\population_nber", replace
}
}

**********************************************************
* B) Patent Data: patents_localized.dta
**********************************************************
{

*************************************************************************
* I) Create basic patent dataset from Patstat: patent_dataset.dta
*************************************************************************
{
cd "$dropbox"
* Publication - only US
{
import delimited "$patstat\tls211_part01.txt", varnames(1) clear 
keep if publn_auth=="US" | publn_auth==""
gen publn_y = substr(publn_date, 1, 4)
drop publn_date publn_nr_original
destring publn_y pat_publn_id publn_nr, force replace
save "$prog\merge", replace

forvalues i = 2(1)5 {
import delimited "$patstat\tls211_part0`i'.txt", varnames(1) clear 
keep if publn_auth=="US" | publn_auth==""
gen publn_y = substr(publn_date, 1, 4)
drop publn_date publn_nr_original
destring publn_y pat_publn_id publn_nr, force replace
append using "$prog\merge"
save "$prog\merge", replace
}
save "$prog\Pat_publn_id_Publn_y", replace
}

* Application
{
import delimited "$patstat\tls201_part01.txt", varnames(1) clear 
gen appln_y = substr(appln_filing_date, 1, 4)
drop appln_nr_epodoc appln_nr_original internat_appln_id appln_nr appln_kind
destring appln_id appln_y, force replace
save "$prog\merge", replace
forvalues i = 2(1)9 {
import delimited "$patstat\tls201_part0`i'.txt", varnames(1) clear 
gen appln_y = substr(appln_filing_date, 1, 4)
gen appln_m = substr(appln_filing_date, 6, 2)
gen appln_d = substr(appln_filing_date, 9, 2)
drop appln_nr_epodoc appln_nr_original internat_appln_id appln_nr appln_kind
destring appln_id appln_y, force replace
append using "$prog\merge"
save "$prog\merge", replace
}
keep if granted==1 & appln_auth=="US"
save "$prog\appln_id_appln_y_clean", replace
}

* Main Patent dataset
{
use "$prog\Pat_publn_id_Publn_y" if publn_auth=="US" & publn_nr!=. & publn_y!=9999, clear
joinby appln_id using  "$prog\appln_id_appln_y_clean"
drop earliest_pat_publn_id earliest_publn_year earliest_publn_date earliest_filing_id earliest_filing_year earliest_filing_date nat_phase reg_phase ipr_type int_phase appln_filing_date
save "$prog\patent_dataset", replace
}

}
***************************************************************************
* II) Geolocate each patent on the county level: patent_fips_weight.dta
***************************************************************************
{
* Fung Data
{
import delimited "$data\fung_new\fung_1.csv", varnames(1) clear 
destring patent_id, force replace
save "$prog\merge", replace
forvalues i = 2(1)14 {
import delimited "$data\fung_new\fung_`i'.csv", varnames(1) clear 
destring patent_id, force replace
append using "$prog\merge"
save "$prog\merge", replace
}
duplicates drop
save "$prog\inventor_fung_new", replace

u "$prog\inventor_fung_new", replace
ren patent_id publn_nr
keep if country_code=="US"
keep publn_nr longitude latitude
ren longitude lng 
ren latitude lat

save "$prog\inventor_fung_new_short", replace


import delimited "$data\fung\fung_1.csv", varnames(1) clear 
destring patent_id, force replace
sleep 500
save "$prog\merge", replace
forvalues i = 2(1)24 {
import delimited "$data\fung\fung_`i'.csv", varnames(1) clear 
destring patent_id, force replace
append using "$prog\merge"
sleep 500
save "$prog\merge", replace
}
duplicates drop
sleep 500
save "$prog\inventor_fung", replace


import delimited "$data\histpat\Gaz_counties_national.txt", clear 
ren geoid fips
drop aland awater awater_sqmi hu10
ren intptlat lat_fips
ren intptlong lng_fips
ren usps state
save "$prog\fips_lat_lon", replace
}


* Fung Database: Map each city state combination by lat lng to a county fips code
{
  
use "$prog\inventor_fung" if country=="US", clear
keep state_code sequence_number patent_id longitude latitude last_name first_middle_name country_code city_code
ren state_code state 
ren country_code country
ren longitude lng 
ren latitude lat
ren patent_id patent
ren last_name lastname
ren first_middle_name firstname
ren sequence_number invseq
ren city_code city
replace city=upper(city)
save "$prog\invpat_temp", replace


insheet using "$data\invpat.csv", clear
keep if country=="US"
gen old = 1 
destring patent, force replace
drop if patent==.
append using  "$prog\invpat_temp"
replace old = 0 if old==.
bysort patent: egen m = mean(old)
drop if old==0 & m>0
drop appyear gyear appdate
drop if patent==.
compress
save "$prog\invpat_temp", replace

use "$prog\invpat_temp", clear
drop if lat==.
keep if old==1
keep city state lat lng
duplicates drop
joinby state using "$prog\fips_lat_lon", unmatched(master)
gen dislat=((lat+lat_fips)/2)*0.01745
gen dist =  ((111.3*(lat-lat_fips))^2 + (111.3*cos(dislat)*(lng-lng_fips))^2)^0.5
drop if dist==.
drop if dist>500 
bysort city state lat lng: egen min = min(dist)
keep if dist ==min
drop _merge min dist dislat
save  "$prog\city_state_fips", replace

* Match fips to Fung Database
use "$prog\invpat_temp", clear
drop if lat==.
drop lat lng
joinby  city state  using "$prog\city_state_fips", unmatched(master)
keep if _merge==3
save "$prog\invpat_temp_fips", replace
}
* Morrison data
{
import delimited "$data\morrisson\LinkedInventorNameLocData.txt", delimiter("|") clear encoding("utf-8")
ren v1 ID 
ren v2 pat 
ren v3 name 
ren v4 lat_lng 
ren v5 qual 
ren v6 loctype 
gen publn_auth = substr(pat, 1,2)
gen publn_nr = substr(pat, 3,.)
keep if publn_auth=="US"
destring publn_nr, force replace
drop if publn_nr==.
split lat_lng, parse(",")
ren lat_lng1 lat
ren lat_lng2 lng
drop lat_lng
destring lat lng, force replace
drop if lat==.
save "$prog\inventor_lat_lng_morrison", replace
}
* Cross check location quality - Result: Final patent location dataset (patent_fips_weight)
{
** Li data for quality check of geolocation
use publn_nr lat lng using "$prog\inventor_fung_new_short", replace 
ren lat lat_li
ren lng lng_li
duplicates drop
save "$prog\selector", replace

** Quality selection
use publn_nr lat lng using  "$prog\inventor_lat_lng_morrison"  if lat>8 & lat<74 & lng<-40 & lng>-171, replace 

joinby publn_nr using  "$prog\selector", unmatched(both) 
gen dislat=((lat+lat_li)/2)*0.01745
gen dist =  (((111.3*(lat-lat_li))^2 + (111.3*cos(dislat)*(lng-lng_li))^2)^0.5)*0.621371
drop if dist>5 & dist!=. 
replace lat =  lat_li if lat==.
replace lng = lng_li if lng==.
keep publn_nr lat lng
duplicates drop
keep if lat>8 & lat<74 & lng<-40 & lng>-171

save "$prog\patent_fips_weight", replace
}

* All inventors in the same city?
{
u "$prog\patent_fips_weight", clear
gen id=_n
save "$prog\patent_fips_weight_onecity", replace

u "$prog\patent_fips_weight_onecity", clear
ren id id_test
ren lat lat_other
ren lng lon_other
joinby publn_nr using "$prog\patent_fips_weight_onecity"
gen dislat=((lat+lat_other)/2)*0.01745
gen author_dist =  (((111.3*(lat-lat_other))^2 + (111.3*cos(dislat)*(lng-lon_other))^2)^0.5)*0.621371
bys publn_nr: egen m_dist=max(author_dist)
gen samecity=(m_dist<15) 
keep samecity publn_nr
duplicates drop
save "$prog\patent_onecity", replace
}

}


*****************************************************************************
* III) Run patent characteristics file: patent_characteristics.dta
*****************************************************************************
{
*************************************************************************
* N Classes
*************************************************************************

import delimited "$patstat\tls223_part01.txt", varnames(1) clear
gen primary_classification = substr(docus_class_symbol, 10,1)
* Sort out the primary classification. It might P or if P is not there then O(riginal)
gen primary = strpos(primary_classification, "P")
gen primary_2 = strpos(primary_classification, "O")
bysort appln_id: egen s = sum(primary)
bysort appln_id: egen so = sum(primary_2)
keep if primary>0 | primary_2>0 // Keep either
gen nclass=substr(docus_class_symbol, 1,3)
drop docus_class_symbol
destring nclass, force replace
drop if nclass==.
duplicates drop
drop if primary_2>0 & s>0  // Give preference of P over O
bysort appln_id: egen st = sum(1)
keep appln_id nclass
duplicates drop appln_id, force 
save "$proc\nclass", replace

*************************************************************************
* Get distances
***************************************************#***********************
use lat lng publn_nr  using "$prog\patent_fips_weight", replace
duplicates drop publn_nr, force 
keep publn_nr lat lng
sort publn_nr lat lng
drop if lat==.
ren lng lon
duplicates drop
cap drop _merge
save "$prog\patent_lat_lon", replace

use "$dropbox\Data\mainarea", clear
keep appln_id area35
duplicates drop
save "$prog\mainarea_citing", replace


*************************************************************************
* Publication Year - Application Year
*************************************************************************

use "$prog\Pat_publn_id_Publn_y" if publn_auth=="US" & publn_nr!=. & publn_y!=9999, clear
drop if publn_kind=="A1"  | publn_kind=="A2" | publn_kind=="A9"
joinby appln_id using  "$prog\appln_id_appln_y_clean"
cap drop _merge
joinby appln_id using "$prog\nclass", unmatched(master)
cap drop _merge

destring publn_nr, force replace
cap drop _merge
joinby publn_nr using "$prog\patent_lat_lon", unmatched(master)
tab _merge 
drop _merge
keep appln_id pat_publn_id publn_y appln_y nclass publn_nr lat lon  inpadoc_family_id
duplicates drop
destring nclass, force replace
drop if nclass==.
drop if publn_nr==.
merge m:1 appln_id using "$dropbox\Data\mainarea"
drop if _merge==2
drop _merge
drop if pat_publn_id==.
save "$prog\Appln_id_Pat_publn_id_Publn_y_Appln_y", replace


u "$prog\Appln_id_Pat_publn_id_Publn_y_Appln_y", clear
keep pat_publn_id appln_id appln_y nclass lat lon area35 publn_nr
ren pat_publn_id cited_pat_publn_id
ren appln_id cited_appln_id
ren appln_y cited_appln_y
ren nclass cited_nclass
ren lat cited_lat
ren lon cited_lon
ren area35 cited_area35
ren publn_nr cited_publn_nr
save "$prog\cited_pat_publn_id_cited_appln_y", replace


*****************************************************************************
* Citation Data
*****************************************************************************

import delimited "$patstat\tls215_part01.txt", varnames(1) clear 
save "$prog\tls215_part01", replace
foreach x in pat_publn_id citn_id citn_categ {
ren `x' cited_`x'
}
save "$prog\cited_tls215_part01", replace

import delimited "$patstat\tls212_part01.txt", varnames(1) clear 
save "$prog\merge", replace
forvalues i = 2(1)9{
import delimited "$patstat\tls212_part0`i'.txt", varnames(1) clear 
append using "$prog\merge"
save "$prog\merge", replace
}

import delimited "$patstat\tls212_part10.txt", varnames(1) clear 
append using "$prog\merge"
save "$prog\merge", replace
save  "$prog\tls212", replace

*****************************************************************************
* Person Data
*****************************************************************************

import delimited "$patstat\tls206_part01.txt", varnames(1) clear 
drop person_address person_name
recast str60 doc_std_name  psn_name, force
save "$prog\merge", replace
forvalues i = 2(1)6 {
import delimited "$patstat\tls206_part0`i'.txt", varnames(1) clear 
drop person_address person_name
recast str60 doc_std_name  psn_name, force
append using "$prog\merge"
save "$prog\merge", replace
}
save  "$prog\tls206", replace

import delimited "$patstat\tls208_part01.txt", varnames(1) clear 
save  "$prog\tls208", replace


import delimited "$patstat\tls227_part01.txt", varnames(1) clear 
sleep 500
save "$prog\merge", replace
forvalues i = 2(1)3 {
import delimited "$patstat\tls227_part0`i'.txt", varnames(1) clear 
append using "$prog\merge"
save "$prog\merge", replace
}
destring invt_seq_nr, force replace
save  "$prog\tls227", replace

u  "$prog\Pat_publn_id_Publn_y" if publn_auth=="US", clear
keep pat_publn_id 
joinby pat_publn_id using "$prog\tls227", unmatched(master)
tab _merge
drop _merge
joinby person_id using "$prog\tls206", unmatched(master)
drop _merge
joinby doc_std_name_id using "$prog\tls208", unmatched(master)
drop _merge
save "$prog\persons", replace
bysort pat_publn_id: egen min_invt_seq_nr = min(invt_seq_nr)
duplicates tag pat_publn_id, gen(dup)
drop if min_invt_seq_nr<invt_seq_nr & dup>0
drop dup min_invt_seq_nr
keep pat_publn_id doc_std_name_id 
save "$prog\persons_citations", replace
ren pat_publn_id cited_pat_publn_id 
ren doc_std_name_id cited_doc_std_name_id
save "$prog\persons_cited", replace


*************************************************************************
* Match all: Forward citation data together
*************************************************************************
cd "$prog"

u pat_publn_id cited_pat_publn_id cited_appln_id  using "tls212" if cited_pat_publn_id!=0, clear

joinby cited_pat_publn_id using "cited_pat_publn_id_cited_appln_y"
cap drop _merge
compress
joinby pat_publn_id using "Appln_id_Pat_publn_id_Publn_y_Appln_y"
cap drop _merge
drop if lat ==. // only geolocated citations
gen cite = 1
drop if cited_appln_y==9999
gen dislat=((lat+cited_lat)/2)*0.01745
gen dist =  (((111.3*(lat-cited_lat))^2 + (111.3*cos(dislat)*(lon-cited_lon))^2)^0.5)*0.621371
drop if dist==.
drop lat lon cited_lat cited_lon dislat
compress

* Calculating technology distance
gen counter = nclass!=cited_nclass
replace counter = 0 if nclass==. | cited_nclass==.
bysort nclass cited_nclass: egen cross_tech = sum(counter)
bysort cited_nclass: egen cross_tech_origin = sum(counter)
bysort nclass: egen cross_tech_destination= sum(counter)
gen cross_tech_forward = cross_tech/cross_tech_origin 
gen cross_tech_backward = cross_tech/cross_tech_destination
drop cross_tech cross_tech_origin cross_tech_destination counter

duplicates drop pat_publn_id cited_pat_publn_id dist, force 
drop if dist==. | dist>4500
save "tls212_extended", replace


use "tls212_extended"
collapse (sum)  cite , by(cited_pat_publn_id appln_y)
ren cited_pat_publn_id pat_publn_id
ren appln_y citing_y
save "forward_cites", replace


* Characteristics of assignees
* Select assignees
u  "Appln_id_Pat_publn_id_Publn_y_Appln_y", clear
keep pat_publn_id publn_nr
save "pat_publn_id_select", replace

use tls227 , clear
bysort pat_publn_id: egen min_invt_seq_nr= min(invt_seq_nr)
keep if invt_seq_nr==min_invt_seq_nr

bysort pat_publn_id: egen min_applt_seq_nr= min(applt_seq_nr)
keep if applt_seq_nr==min_applt_seq_nr

drop invt_seq_nr min_applt_seq_nr  applt_seq_nr min_invt_seq_nr
duplicates drop pat_publn_id, force
save tls227_assignees, replace


u  "Appln_id_Pat_publn_id_Publn_y_Appln_y", clear

merge 1:1 pat_publn_id using tls227_assignees
keep if _merge==3
tab _merge
drop _merge
joinby person_id using tls206, unmatched(master)
keep if _merge==3
drop _merge
keep if person_ctry_code=="US" | person_ctry_code=="  "
drop if psn_name=="" | psn_name=="-NOT AVAILABLE-"
 
save persons_characteristics_temp, replace

u persons_characteristics_temp, clear
duplicates drop publn_nr, force
bysort doc_std_name_id: egen min_appln_y = min(appln_y)
sort doc_std_name_id appln_y

gen independent = (psn_sector=="INDIVIDUAL" | psn_sector=="" | psn_sector=="UNKNOWN" )
gen company = (psn_sector=="COMPANY")
gen non_profit = (psn_sector=="GOV NON-PROFIT" | psn_sector=="COMPANY GOV NON-PROFIT")
gen uni_hosp = (psn_sector=="UNIVERSITY") | (psn_sector=="HOSPITAL") | (psn_sector=="GOV NON-PROFIT UNIVERSITY") | (psn_sector=="COMPANY UNIVERSITY")  

keep pat_publn_id publn_nr min_appln_y   independent psn* independent company non_profit uni_hosp appln_y inpadoc_family_id

* Size
levelsof(appln_y), local(appln_y)
gen size= 0
forvalues x = 1960(1)2013 {
gen counter = inpadoc_family_id*(`x'<=appln_y)
bysort psn_id: egen size_temp = nvals(counter) 
replace size = size_temp-1 if (`x'==appln_y) // -1 to correct for zeros
drop counter size_temp
}

bysort psn_id appln_y: egen min_size = min(size)
replace size = min_size

*Age
bysort psn_id: egen firstPatent = min(appln_y)
bysort psn_id: egen sizeOfPortfolio = sum((appln_y<firstPatent+10))

bysort psn_name: egen sizeOfFirm = nvals(inpadoc_family_id)
replace sizeOfFirm= 1 if psn_name==""

gen age = appln_y-min_appln_y
replace size = size/(age+1)

drop appln_y
save persons_characteristics, replace


* Calculate generality

use "tls212_extended", clear
bysort cited_pat_publn_id: egen area_citing = nvals(area35)

gen cit = 1
collapse (sum) cit (mean) area_citing, by(nclass cited_pat_publn_id)
bysort cited_pat_publn_id: egen cit_tot = sum(cit)
gen generality = (cit/cit_tot)^2
ren cit total_forward_cites
collapse  (sum)  total_forward_cites generality (mean) area_citing, by(cited_pat_publn_id)
ren cited_pat_publn_id pat_publn_id 
replace generality = 1-generality
save "generality", replace

* Calculate originality
use "tls212_extended", clear
drop if cited_pat_publn_id==.
gen cit = 1
bysort pat_publn_id: egen area_cited = nvals(cited_area35)

collapse (sum) cit (mean) area_cited, by(cited_nclass pat_publn_id)
bysort pat_publn_id: egen cit_tot = sum(cit)
gen originality = (cit/cit_tot)^2
ren cit total_backward_cites
collapse  (sum) total_backward_cites originality (mean) area_cited, by(pat_publn_id)
replace originality = 1-originality
save "originality", replace

* Calculate distance
use "tls212_extended", clear
gen forward_no_dist = (dist==.)
gen forward_large_50=dist>50
gen forward_large_250=dist>250

global dist 
forvalues i = 10(10)90 {
global dist $dist (p`i') forward_p`i'_dist=dist 
}

collapse (sum) forward_no_dist (mean)   forward_large_50 forward_large_250 forward_mean_dist = dist (median) forward_median_dist = dist $dist (max) forward_max_dist= dist (min) forward_min_dist=dist , by(cited_pat_publn_id)
ren cited_pat_publn_id pat_publn_id
save "forward_dist", replace



use "tls212_extended", clear
gen backward_no_dist = (dist==.)
gen backward_large_20=dist>20
gen backward_large_50=dist>50
gen backward_large_100=dist>100
gen backward_large_250=dist>250
gen backward_large_500=dist>500

global dist 
forvalues i = 10(10)90 {
global dist $dist (p`i') backward_p`i'_dist=dist 
}
collapse (sum) backward_no_dist (mean)  backward_large_20 backward_large_50 backward_large_100 backward_large_250 backward_large_500 backward_mean_dist = dist (median)  backward_median_dist = dist  $dist (max) backward_max_dist= dist backward_max_100=backward_large_100 (min) backward_min_dist=dist   , by(pat_publn_id)
save "backward_dist", replace

use "tls212_extended", clear
drop if cross_tech_backward==.
collapse (mean) backward_mean_crossTech = cross_tech_backward (median) backward_median_crossTech  = cross_tech_backward (p90) backward_p90_crossTech =cross_tech_backward (p10) backward_p10_crossTech =cross_tech_backward (max) backward_max_crossTech = cross_tech_backward (min) backward_min_crossTech =cross_tech_backward , by(pat_publn_id)
save "backward_crossTech", replace

use "tls212_extended", clear
drop if cross_tech_forward==.
collapse (mean) forward_mean_crossTech = cross_tech_forward (median) forward_median_crossTech  = cross_tech_forward (p90) forward_p90_crossTech =cross_tech_forward (p10) forward_p10_crossTech =cross_tech_forward (max) forward_max_crossTech = cross_tech_forward (min) forward_min_crossTech =cross_tech_forward , by(cited_pat_publn_id)
ren cited_pat_publn_id pat_publn_id
save "forward_crossTech", replace

u   "Appln_id_Pat_publn_id_Publn_y_Appln_y", clear

merge m:1 pat_publn_id using  "generality"
tab _merge
drop if _merge==2
drop _merge
merge m:1 pat_publn_id using  "originality"
tab _merge
drop if _merge==2
drop _merge
merge m:1 pat_publn_id using  "forward_dist"
tab _merge
drop if _merge==2
drop _merge
merge m:1 pat_publn_id using  "backward_dist"
tab _merge
drop if _merge==2
drop _merge
merge m:1 pat_publn_id using  "backward_crossTech"
tab _merge
drop if _merge==2
drop _merge
merge m:1 pat_publn_id using  "forward_crossTech"
tab _merge
drop if _merge==2
drop _merge
merge m:1 pat_publn_id using "persons_characteristics"
tab _merge
drop if _merge==2
drop _merge
keep if publn_nr!=.
keep if appln_y>1965 & publn_y>1965
duplicates drop publn_nr, force
keep if lat!=.
replace total_forward_cites = 0 if total_forward_cites==.
save "patent_characteristics", replace

}
*****************************************************************************
* IV) Match together I) and II): patents_localized.dta
*****************************************************************************
{

global data "$dropbox\Data\raw"
global prog "$dropbox\Prog"
global mapdir "$dropbox\Data\map" 
global mapdir "$dropbox\Data\map" 


use appln_id  pat_publn_id publn_nr publn_y appln_filing_year granted appln_y inpadoc_family_id  using  "$prog\patent_dataset" , clear
merge m:1 appln_id using "$dropbox\Data\mainarea"		
keep if _merge==3

replace appln_y = publn_y-3 if appln_y==9999
joinby publn_nr using "$prog\patent_fips_weight"
bysort publn_nr: egen weight = sum(1)
replace weight = 1/weight
cap drop _merge
merge m:1 publn_nr using "$prog\patent_characteristics"
compress
cap drop min_appln_y
bysort psn_id: egen min_appln_y = min(appln_y)
replace min_appln_y=1877 if regexm(psn_name, "AT&T ") 
replace min_appln_y=1877 if regexm(psn_name, "BELL ") 

cap drop _merge
merge m:1 nclass using "$dropbox\Data\patentCategory" // hand-coded from Hall
keep if _merge==3
bysort appln_y nclass: egen m = mean(total_forward_cites)
gen pat_total_forward_cites = total_forward_cites*weight
foreach x in independent company non_profit uni_hosp {
gen pat_`x' = weight*(`x'==1)
}
global charact  originality generality backward_mean_dist 

* Split by technology
levelsof(subcat), local(subcat)
foreach x in `subcat' {
gen pat_subcat_`x' = weight * (subcat==`x')
}
gen cat = floor(subcat/10)

levelsof(cat), local(cat)
foreach x in `cat' {
gen pat_cat_`x' = weight * (cat==`x')
}
foreach x in area30 mainarea30 area35 mainarea35 area34 mainarea34 {
levelsof `x', local(tech)
foreach y in `tech' {
gen pat_`x'_`y' = weight * (`x'==`y')
}
}



levelsof(appln_y), local(appln_y)
foreach x in `appln_y' {
gen young_company = (min_appln_y>=`x'-3) 
bysort psn_id: egen m_young=max(young_company)
replace m_young = 1 if psn_id==.
gen pat_young_`x' = weight * m_young
drop young_company m_young
}


levelsof(appln_y), local(appln_y)

levelsof(appln_y), local(appln_y)


foreach x in `appln_y' {
bysort psn_id: egen small=sum(weight*(appln_y<=`x')) 
replace small = (small<=20) 
bysort psn_id: egen m_small=max(small)
replace m_small = 1 if psn_id==.
gen pat_small_10_`x' = weight * m_small
drop m_small small
}


forvalues y = 10(10)50 {
gen pat_small_overall_`y' = (sizeOfFirm<`y')
}


drop if appln_y<1966 | appln_y>2010


save "$prog\patents_localized", replace
}

*****************************************************************
* V) Structure of inventors
*****************************************************************
{
use "$prog\inventor_fung" if country=="US", clear 
ren patent_id publn_nr
egen ID_nr = group(full_name)
tostring ID_nr, replace
gen ID = ID_nr
merge m:1 publn_nr using "$prog\patent_characteristics"
keep if _merge==3
keep publn_nr ID  appln_y
bysort ID: egen min_appln_y_nr = min(appln_y)
gen prio = 2
bysort publn_nr: egen n_inventor = sum(1)
save  "$prog\fung_id", replace

use "$prog\inventor_lat_lng_morrison", clear
keep publn_nr ID
merge m:1 publn_nr using "$prog\patent_characteristics"
keep if _merge==3
bysort pat: egen n_inventor = sum(1)
keep publn_nr ID appln_y n_inventor
bysort ID: egen min_appln_y_nr = min(appln_y)

gen prio = 1
append using  "$prog\fung_id"
bysort publn_nr: egen min_prio = min(prio)
keep if prio == min_prio 
egen inv_nr = group(ID)
keep publn_nr inv_nr appln_y n_inventor min_appln_y_nr
save "$prog\inv_nr", replace

ren inv_nr inv_nr2
ren min_appln_y_nr min_appln_y_nr2
duplicates drop
joinby publn_nr using "$prog\inv_nr"
drop if inv_nr==inv_nr2

keep publn_nr inv_nr inv_nr2 appln_y min_appln* n_inventor
duplicates drop
bysort inv_nr inv_nr2: egen min_appln_y = min(appln_y)
gen new_pair = min_appln_y == appln_y
gen new_pair_old_inv = new_pair*(appln_y>min_appln_y_nr)*(appln_y>min_appln_y_nr2)
gen old_couple = min_appln_y < appln_y

keep publn_nr new_pair new_pair_old_inv old_couple n_inventor
duplicates drop
bysort publn_nr: egen m_new_pair = max(new_pair)
bysort publn_nr: egen m_new_pair_min = min(new_pair)
bysort publn_nr: egen m_new_pair_old_inv = max(new_pair_old_inv)
bysort publn_nr: egen m_new_pair_old_inv_min = min(new_pair_old_inv)
bysort publn_nr: egen m_old_couple = min(old_couple)

keep publn_nr  m_* n_inventor
duplicates drop
ren m_new_pair new_pair
ren m_new_pair_old_inv new_pair_old_inv
ren m_old_couple old_couple
ren m_new_pair_min new_pair_all
ren m_new_pair_old_inv_min new_pair_all_old

label var new_pair "Some inventors are new in team"
label var new_pair_old_inv "Some inventors are new in team-but they worked before"
label var old_couple "All worked together in the past"
label var new_pair_all "Completely new inventor team"
label var new_pair_all_old "Completely new inventor team - all patented before"
save "$prog\publn_nr_new_pair", replace


use "$prog\inventor_lat_lng_morrison", clear
duplicates drop
merge m:1 publn_nr using "$prog\patent_characteristics"
keep if _merge==3
bysort pat: egen n_inventor = sum(1)
keep if n_inventor==1
bysort ID: egen min_appln_y_nr = min(appln_y)

gen prio = 1
keep if n_inventor==1

bysort publn_nr: egen min_prio = min(prio)
keep if prio == min_prio 
egen inv_nr = group(ID)
keep publn_nr inv_nr min_appln_y_nr appln_y n_inventor
duplicates drop 
gen new_single = min_appln_y_nr == appln_y
gen old_single = min_appln_y_nr < appln_y
keep publn_nr  new_single old_single n_inventor
append using  "$prog\publn_nr_new_pair"
bysort publn_nr: egen min_in = min(n_inventor)
keep if min_in ==  n_inventor
drop min_in
save "$prog\publn_nr_new_pair", replace
}


}

**********************************************************
* C) Library Data: pat_fdl_full.dta
**********************************************************
{
**********************************************************
* I) Import all libraries with their respective location
**********************************************************
{
* Federal Depository Libraries:  fdl_libs.dta
{
global data "$dropbox\Data\raw"


* Import FDL Data
import excel "$data\alllibraries.xlsx", sheet("Tabelle1") firstrow clear
drop in 1 //empty
drop TitleofLibraryDirector LibraryDirectorLastName LibraryDirectorFirstName DepositoryCoordinatorTitle DepositoryCoordinatorLastName DepositoryCoordinatorFirstNam DepositoryCoordinatorPhoneNum V PublicServiceAreaPhoneNumber X FaxNumberAreaCode FaxNumber DepositoryWebsite CatalogWebsite SenatorialClass
rename City city
rename State state_compl
rename StatePostalCode state
replace city=upper(city)
split ZipCode, parse("-")
gen zip = ZipCode1
destring zip, force replace
joinby city state using  "$prog\city_state_fips", unmatched(master) // for lat and long
cap drop _merge
rename lat lat_library
rename lng lon_library
rename city city_library
cap drop _merge
drop CongressionalDistrict TypeofDesignation StreetAddress
rename state state_library
gen year_open = regexs(0) if(regexm( YearofDesignationasaDeposit , "[0-9][0-9][0-9][0-9]"))
destring year_open, replace
drop if year_open==.
replace city_library ="AUBURN" if city_library=="AUBURN UNIVERSITY"
replace ParentInstitutionofLibrary="Boston Public Library" if LibraryName=="Boston Public Library" //  field is missing
replace ParentInstitutionofLibrary="Wyoming State Library" if LibraryName=="Wyoming State Law Library"
replace ParentInstitutionofLibrary="Denver Public Library" if LibraryName=="Denver Public Library" //  field is missing
replace ParentInstitutionofLibrary="Detroit Public Library" if LibraryName=="Detroit Public Library" //  field is missing
replace ParentInstitutionofLibrary="Mississippi Library Commission" if LibraryName=="Mississippi Library Commission" //  field is missing
replace ParentInstitutionofLibrary="Arkansas State Library" if LibraryName=="Arkansas State Library" //  field is missing
replace ParentInstitutionofLibrary="Milwaukee Public Library" if LibraryName=="Milwaukee Public Library" //  field is missing
replace ParentInstitutionofLibrary="Newark Public Library" if LibraryName=="Newark Public Library" //  field is missing
replace ParentInstitutionofLibrary="Free Library of Philadelphia" if LibraryName=="Free Library of Philadelphia" //  field is missing
replace ParentInstitutionofLibrary="Carnegie Library of Pittsburgh" if LibraryName=="Carnegie Library of Pittsburgh" //  field is missing
replace ParentInstitutionofLibrary="Saint Louis Public Library" if LibraryName=="Saint Louis Public Library" //  field is missing
replace ParentInstitutionofLibrary="San Francisco Public Library" if LibraryName=="San Francisco Public Library" //  field is missing
replace ParentInstitutionofLibrary="Toledo-Lucas County Public Library" if LibraryName=="Toledo-Lucas County Public Library" //  field is missing

save "$prog\alllibraries_alone.dta", replace

use "$prog\alllibraries_alone.dta", replace

drop if LibrarySize=="Small (less than 250,000 volumes in the library)"
destring YearofDesignationasaDeposit, force replace
bysort fips: egen year_fdl = min(YearofDesignationasaDeposit)
gen fdl = 1
ren city_library city_fdl
ren state_library state_fdl
ren fips geoid
joinby geoid using "$prog\msa_zip_link", unmatched(master) 
drop _merge
save "$prog\fdl_libs", replace
}


* Patent Libraries: patent_lib.data
{
import delimited "$data\states_long.csv", delimiter(comma) clear
ren v1 lib_state
ren v3 state
drop v2
save "$prog\states", replace

* Filled file by hand
import excel "$data\patent_libraries_clean.xls", sheet("Sheet1") firstrow clear
ren city_library city
joinby lib_state using "$prog\states", unmatched(master)
drop _merge
replace state = "DC" if state==""
joinby city state using  "$prog\city_state_fips", unmatched(master) 
ren city city_library
drop _merge
save "$prog\patent_lib", replace
}
}
****************************************************************
* II) Match Patent Libaries to Control FDLs: pat_fdl_full.dta; pat_lat_lng_full
****************************************************************
{

cd "$dropbox"
use "$prog\fdl_libs", clear

keep DepositoryLibraryNumber DepositoryLibraryNumber DepositoryType LibraryType LibrarySize ParentInstitutionofLibrary LibraryName city_fdl state_fdl YearofDesignationasaDeposit lat_library lon_library zip
ren ParentInstitutionofLibrary ParentInstitutionofLibrary_fdl
save  "prog\fdl_libs_cross", replace

* Create the Patent Lib FDL Sample
use "$prog\patent_lib", clear

drop lib_state lng_fips lat_fips aland_sqmi pop10 name ansicode 
ren city_library city_patent_library
ren state state_patent_library
cross using "$prog\fdl_libs_cross"

gen dislat=((lat+lat_library)/2)*0.01745
gen pat_FDL_dist =  (((111.3*(lat-lat_library))^2 + (111.3*cos(dislat)*(lng-lon_library))^2)^0.5)*0.621371

* Strict within institutions
gen patent_lib_institutions = ParentInstitutionofLibrary_fdl == ParentInstitutionofLibrary  // Only select patent libs that are also FDL
bysort ID: egen m = max(patent_lib_institutions)

* Superset to strict definitions: Same city or very close
gen patent_lib= state_patent_library== state_fdl  & city_fdl==city_patent_library 
replace patent_lib = patent_lib_institutions if m==1
replace patent_lib = 1 if city_patent_library=="SUNNYVALE" & city_fdl=="SANTA CLARA" 
replace  patent_lib = 1   if  ParentInstitutionofLibrary_fdl=="Rutgers University, New Brunswick" & ParentInstitutionofLibrary=="Rutgers University"

drop if YearofDesignationasaDeposit>openingyear & patent_lib==0

* Drop all control at the same place as treated
drop if pat_FDL_dist==0 & patent_lib==0

* Calculate closests patent library
bysort DepositoryLibraryNumber: egen min_dist_FDL_pat = min(pat_FDL_dist)

* Keep closest, if two are equally close keep controls twice
keep if min_dist_FDL_pat>=pat_FDL_dist-5

* drop all outside of expansion period
keep if openingyear>1975 & openingyear<1998  

duplicates tag ID lat_library if patent_lib==1 & patent_lib_institutions==1, gen(dup) 
drop if LibraryType=="Academic, Law Library (AL)" & dup==1
drop dup

* Gives the main library dataset with latitude and longitude
save "$prog\pat_fdl_full", replace
keep lat_library lon_library 
ren lat_library lat
ren lon_library lng
keep lat lng  
duplicates drop 
save prog\pat_lat_lng_full, replace

}
}

******************************************************************************************************************
* D) Match libraries to patents, population and patent attorneys
******************************************************************************************************************
{
******************************************************************************************************************
* I) Match to patents: pat_fdl_with_patent_location.dta
******************************************************************************************************************
{
******************************************************************************************************************
* 1) Cross lat/lon of patents with lat/lon of libraries - all patents within 150 miles: fdl_libray_all_cross
******************************************************************************************************************

{
use lat lng using "$prog\patents_localized", clear
ren (lat lng) (lat_patent lng_patent) 
duplicates drop
cross using  "$prog\pat_lat_lng_full"
gen dislat=((lat+lat_patent)/2)*0.01745
gen dist =  (((111.3*(lat-lat_patent))^2 + (111.3*cos(dislat)*(lng-lng_patent))^2)^0.5)*0.621371

drop if dist>150
gen dist_15m=(dist<=15)
gen dist_50m=(dist>15 & dist<=50)
gen dist_100m=(dist>50 & dist<=100)
gen dist_150m=(dist>100 & dist<=150)

forvalues i = 0(10)150 {
local j = `i'+10
gen dist_`i' = (dist>=`i' & dist<`j')
}
drop dislat 
save "$prog\fdl_libray_all_cross", replace

* 2) Patent libraries with patent location
use  "$prog\pat_fdl_full", clear
drop lat lng
ren (lat_library lon_library) (lat lng)
joinby lat lng using  "$prog\fdl_libray_all_cross"
ren (lat lng) (lat_library lon_library) 
save "$prog\pat_fdl_with_patent_location", replace

* 3) Patent libraries with patent numbers within 15miles
use lat lng publn_nr appln_y using "$prog\patents_localized", clear
ren (lat lng) (lat_patent lng_patent) 
duplicates drop
save "$prog\publn_nr_lat_lng_patent", replace

use  "$prog\pat_fdl_with_patent_location", clear
keep if dist_15m==1
keep ID pat_libr_name LibraryName DepositoryLibraryNumber openingyear  lat_patent lng_patent lat_library  lon_library
duplicates drop
joinby lat_patent lng_patent using  "$prog\publn_nr_lat_lng_patent"
drop  lat_patent lng_patent
duplicates drop
keep publn_nr appln_y lat_library lon_library openingyear ID DepositoryLibraryNumber
save "$prog\patentlist", replace
}
}
******************************************************************************************************************
* II) Match to population:  population_lat_lng_all, population_lat_lng_tv, population_lat_lng_nber
******************************************************************************************************************
{
******************************************************************************************************************
* 1) Census population: population_lat_lng_all population_lat_lng_tv
******************************************************************************************************************
{
* Latest census population
use   "$prog\population_tract", clear
cross using   "$prog\pat_lat_lng_full"
gen dislat=((lat+lat_municipality)/2)*0.01745
gen dist =  (((111.3*(lat-lat_municipality))^2 + (111.3*cos(dislat)*(lng-lon_municipality))^2)^0.5)*0.621371


drop if dist>150
gen dist_15m=(dist<=15)
gen dist_50m=(dist>15 & dist<=50)
gen dist_100m=(dist>50 & dist<=100)
gen dist_150m=(dist>100 & dist<=150)

* Population for different circles -> robustness
gen pop_dist5=population*(dist<=5)
*gen pop_dist10=population*(dist<=10)
gen pop_dist25=population*(dist<=25)
gen pop_dist50=population*(dist<=50)
*


forvalues i = 0(10)150 {
local j = `i'+10
gen pop_`i'=population*(dist>=`i' & dist<`j')
}


foreach x in 15 50 100 150 {
gen pop_`x'm=population*dist_`x'm
}
collapse (sum) pop_*, by(lat lng)
save "$prog\population_lat_lng_all", replace

}

******************************************************************************************************************
* 2) NBER population yearly: population_lat_lng_nber
******************************************************************************************************************
{
use  "$prog\pat_lat_lng_full", clear
cross using  "$prog\population_nber"
gen dislat=((lat+lat_municipality)/2)*0.01745
gen dist =  (((111.3*(lat-lat_municipality))^2 + (111.3*cos(dislat)*(lng-lon_municipality))^2)^0.5)*0.621371
gen dist_15m=(dist<=15)
gen pop_nber15m=pop_nber*dist_15m
gcollapse (sum) pop_*, by(lat lng appln_y)
save "$prog\population_lat_lng_nber", replace
}
}
*****************************************************************************
* III) Match to patent attorneys: patent_attorneys_lat_lng_all
*****************************************************************************
{

cd "$data"
u zip_lat_lon.dta, clear
ren ZipCode1 zip
keep zip county latitude longitude state state_1
sort zip
duplicates drop zip county state state_1, force //deletes second place name with same zip (37 Obs)

duplicates drop zip, force //deletes second county with same zip (6 Obs)

save "$attorneysource\zip_lat_lon.dta", replace
***
cd "$attorneysource"
foreach x in 1974 1975 1976 1977 1982 1984 1985 1987 1988 1990 1991 1992 1993 1994 1995 1996 1999 2001{ 
insheet using `x'z.txt, clear
drop if _n==1 //first row is headline only
drop if regexm(v1, "Government") //intermediate headlines
drop if regexm(v1, "Registrant") //intermediate headlines
drop if regexm(v1, "employed") //intermediate headlines
drop if regexm(v1, "U.S") //intermediate headlines
drop if regexm(v1, "Canada") //foreign attorneys
drop if v1==""
split v1, p(",")
ren v11 surname
gen year=`x'
gen zip = regexs(0) if(regexm(v12, "[0-9][0-9][0-9][0-9][0-9]"))
forvalues i=13/16{
replace zip=regexs(0) if(regexm(v`i', "[0-9][0-9][0-9][0-9][0-9]")) & zip==""
}
replace zip=regexs(0) if(regexm(surname, "[0-9][0-9][0-9][0-9][0-9]")) & zip==""
replace v1=v1[_n-1]+v1 if zip[_n-1]=="" & zip!=""
drop if zip=="" & zip[_n+1]!=""
replace zip=regexs(0) if(regexm(v1, "[0-9][0-9][0-9][0-9][0-9]")) & zip==""
destring zip, replace 
keep year zip surname v1
gen total=_N
gen zipmissing=(zip==.)
save "$attorneysource\attorneys`x'.dta", replace
}

u "$attorneysource\attorneys1974.dta", clear
foreach x in 1975 1976 1977 1982 1984 1985 1987 1988 1990 1991 1992 1993 1994 1995 1996 1999 2001{
append using "$attorneysource\attorneys`x'.dta"
}

save "$attorneysource\patentattorneys.dta", replace

u "$attorneysource\patentattorneys.dta", clear
keep zip year total
drop if zip==.
gen count=1

collapse (sum) count (mean) total, by(zip year)
merge m:1 zip using "$attorneysource\zip_lat_lon.dta"
keep if _merge==3
drop _merge
ren count patent_attorneys 
ren total total_patent_attorneys 
ren state state_attorneys 
ren latitude lat_attorneys 
ren longitude lon_attorneys 
ren year appln_y
drop state_1
save "$prog\patentattorneys_match.dta", replace


*************************************************************************************************
* Cross with patent attorney data - 25km 
use  "$prog\pat_lat_lng_full", clear
cap drop _merge
cross using  "$prog\patentattorneys_match"
gen dislat=((lat+lat_attorneys)/2)*0.01745
gen dist =  (((111.3*(lat-lat_attorneys))^2 + (111.3*cos(dislat)*(lng-lon_attorneys))^2)^0.5)*0.621371
gen dist_15m=(dist<=15)
gen dist_50m=(dist>15 & dist<=50)
gen dist_100m=(dist>50 & dist<=100)
gen dist_150m=(dist>100 & dist<=150)

forvalues i = 0(50)150 {
local j = `i'+10
gen patent_attorneys_`i'=patent_attorneys*(dist>=`i' & dist<`j')
replace patent_attorneys_`i'=. if patent_attorneys==.
}


foreach x in 15 50 100 150{
gen patent_attorneys_`x'm=patent_attorneys*dist_`x'm
replace patent_attorneys_`x'm=. if patent_attorneys==.
}
gcollapse (sum) patent_attorneys_*, by(lat lng appln_y)
save "$prog\patent_attorneys_lat_lng_all", replace
}
}


********************************************************************************
* E) New words calculation : new_words.dta
********************************************************************************
{
* Prepare words data
{

import delimited "$data\text_similarity\claim.tsv", encoding(UTF-8) colrange(2) clear
keep if dependent =="-1"
bysort patent_id: egen min_seq=min(sequence)
keep if sequence ==min_seq
ren patent_id publn_nr
drop dependent exemplary
destring publn_nr, force replace
drop if publn_nr==.
gen publn_auth="US"
save "$proc\claims", replace

*************************************************************************
* Application & Publication data
*************************************************************************
* Application data

import delimited "$patstat\tls201_part01.txt", varnames(1) clear 
destring appln_id , force replace
gen appln_y = substr(appln_filing_date, 1, 4)
destring appln_id appln_y, force replace
drop appln_nr_epodoc appln_nr_original internat_appln_id appln_nr appln_kind appln_nr_epodoc appln_nr_original appln_filing_date int_phase internat_appln_id ipr_type reg_phase nat_phase earliest* granted inpadoc_family_id nb_citing_docdb_fam nb_applicants nb_inventors 
save "merge", replace
forvalues i = 2(1)9 {
import delimited "$patstat\tls201_part0`i'.txt", varnames(1) clear 
destring appln_id , force replace
gen appln_y = substr(appln_filing_date, 1, 4)
destring appln_y, force replace
drop appln_nr_epodoc appln_nr_original internat_appln_id appln_nr appln_kind appln_nr_epodoc appln_nr_original appln_filing_date int_phase internat_appln_id ipr_type reg_phase nat_phase earliest* granted inpadoc_family_id nb_citing_docdb_fam nb_applicants nb_inventors 
append using "$prog\merge"
save "$prog\merge", replace
}
save "$prog\appln_id_appln_y", replace


* Publication data
import delimited "$patstat\tls211_part01.txt", varnames(1) clear 
destring appln_id , force replace
gen publn_y = substr(publn_date, 1, 4)
drop publn_date  publn_lg   publn_first_grant publn_nr_original
destring publn_y pat_publn_id publn_nr, force replace
save "$prog\merge", replace

forvalues i = 2(1)5 {
import delimited "$patstat\tls211_part0`i'.txt", varnames(1) clear 
destring appln_id , force replace
gen publn_y = substr(publn_date, 1, 4)
drop publn_date  publn_lg   publn_first_grant publn_nr_original
destring publn_y pat_publn_id publn_nr, force replace
append using "$prog\merge"
save "$prog\merge", replace
}
save "$prog\Pat_publn_id_Publn_y", replace



*************************************************************************
* Publication Year - Application Year
*************************************************************************

u  "$prog\Pat_publn_id_Publn_y", clear
drop if publn_y==9999 
drop if publn_auth!="US" & publn_y>1979
drop if publn_y>2010
drop publn_kind publn_claims
destring appln_id , force replace
joinby appln_id using "$prog\appln_id_appln_y", unmatched(master)
tab _merge
drop _merge
destring publn_nr, force replace
duplicates drop
drop if publn_nr==.
save "$prog\Appln_id_Pat_publn_id_Publn_y_Appln_y", replace

*************************************************************************
* Title & Abstract
*************************************************************************
import delimited "$patstat\tls202_part01.txt", varnames(1) clear 
keep if appln_title_lg=="en"
drop appln_title_lg
save "$prog\merge", replace

forvalues i = 2(1)3 {
import delimited "$patstat\tls202_part0`i'.txt", varnames(1) clear 
keep if appln_title_lg=="en"
drop appln_title_lg
append using  "$prog\merge"
save "$prog\merge", replace
}
save "$prog\title", replace


import delimited "$patstat\tls203_part01.txt", varnames(1) clear
keep if appln_abstract_lg=="en"
drop appln_abstract_lg
save "$prog\merge", replace

forvalues i = 2(1)9 {
import delimited "$patstat\tls203_part0`i'.txt", varnames(1) clear 
keep if appln_abstract_lg=="en"
drop appln_abstract_lg
append using  "$prog\merge"
save "$prog\merge", replace
}
forvalues i = 10(1)16 {
import delimited "$patstat\tls203_part`i'.txt", varnames(1) clear 
keep if appln_abstract_lg=="en"
drop appln_abstract_lg
append using  "$prog\merge"
save "$prog\merge", replace
}

save "$prog\abstract_1", replace

import delimited "$patstat\tls203_part17.txt", varnames(1) clear 
keep if appln_abstract_lg=="en"
save "$prog\merge", replace

forvalues i = 18(1)30 {
import delimited "$patstat\tls203_part`i'.txt", varnames(1) clear 
keep if appln_abstract_lg=="en"
drop appln_abstract_lg

append using  "$prog\merge"
pause 500
save "$prog\merge", replace
}

save "$prog\abstract_2", replace


************************************************************************
* Merge files together
************************************************************************
use "$prog\Appln_id_Pat_publn_id_Publn_y_Appln_y" , replace
joinby appln_id using "$prog\title", unmatched(master)
drop _merge
joinby appln_id using "$prog\abstract_1", unmatched(master)
drop _merge
joinby appln_id using "$prog\abstract_2", unmatched(master)
drop _merge
tab appln_y if appln_abstract!=""

save "$prog\title_abstract", replace


use "$prog\title_abstract", replace
drop if  appln_abstract=="" | appln_title=="" | appln_y==.
keep pat_publn_id appln_y appln_title appln_abstract
drop if pat_publn_id==pat_publn_id[_n-1]

order pat_publn_id appln_y appln_title appln_abstract
export delimited using "$prog\Patents_raw.csv", replace



use "$prog\title_abstract", replace
drop appln_abstract
save "$prog\Patents_charact", replace

use "$prog\title_abstract" if publn_auth=="US" | appln_y<=1980, replace
drop if   appln_title=="" | appln_y==.
joinby publn_auth publn_nr using "$proc\claims", unmatched(master)
drop _merge
replace appln_abstract = appln_abstract + " " + text

keep pat_publn_id appln_y appln_title appln_abstract
drop if pat_publn_id==pat_publn_id[_n-1]

order pat_publn_id appln_y appln_title appln_abstract
sort appln_y
export delimited using "$proc\Patents_raw.csv", replace

* Run Java File that produces patents_terms.txt

import delimited "$data\text_similarity\words.csv", clear	
ren v1 publn_nr	
ren v2 words	
gen publn_auth="US"	
joinby  publn_nr publn_auth using "$proc\Patents_charact"	
keep publn_nr pat_publn_id words appln_y	
drop if appln_y==9999 | appln_y==.	
duplicates drop publn_nr words appln_y, force	
drop if appln_y<1970	
gen number_keywords=wordcount(words)	
save "$proc\data_words", replace

use "$proc\data_words"  if number_keywords<=28, replace
drop number_keywords
split words
drop words
recast str40 words?, force 
recast str40 words??, force 
reshape long words, i(publn_nr) j(number)
drop if words==""
save  "$proc\temp_words", replace


use "$proc\data_words" if number_keywords>28 & number_keywords<=36, replace
drop number_keywords
split words
drop words
recast str40 words?, force 
recast str40 words??, force 
reshape long words, i(publn_nr) j(number)
drop if words==""
save  "$proc\temp_words1", replace

use "$proc\data_words" if number_keywords>36 & number_keywords<=45, replace
drop number_keywords
split words
drop words
recast str40 words?, force 
recast str40 words??, force 
reshape long words, i(publn_nr) j(number)
drop if words==""
save  "$proc\temp_words2", replace

use "$proc\data_words" if number_keywords>45, replace
drop number_keywords
split words
drop words
recast str40 words?, force 
recast str40 words??, force 
recast str40 words??, force 
reshape long words, i(publn_nr) j(number)
drop if words==""
save  "$proc\temp_words3", replace


use  "$proc\temp_words", clear
append using  "$proc\temp_words1"
append using  "$proc\temp_words2"
append using  "$proc\temp_words3"
save  "$proc\data_words", replace

use "$proc\data_words", clear
gegen word_number = group(words)
save "$proc\word_number", replace


import delimited "$proc\patents_terms.txt", clear delim(";")
ren v1 pat_publn_id
ren v2 number_keywords
ren v3 words
cap drop number_keywords
gen number_keywords=wordcount(words)
joinby pat_publn_id using "$proc\Patents_charact"
keep pat_publn_id words appln_y number_keywords
drop if appln_y==.
save "$proc\data_words", replace

use "$proc\data_words"  if number_keywords<=38, replace
drop number_keywords
split words
drop words
recast str40 words?, force 
recast str40 words??, force 
reshape long words, i(pat_publn_id) j(number)
drop if words==""
save  "$proc\temp_words", replace

use "$proc\data_words" if number_keywords>38 & number_keywords<=50, replace
drop number_keywords
split words
drop words
recast str40 words?, force 
recast str40 words??, force
reshape long words, i(pat_) j(number)
drop if words==""
save  "$proc\temp_words1", replace
clear
clear matrix 
clear mata  
set maxvar 11000
use "$proc\data_words" if number_keywords>50 & number_keywords<=70, replace
drop number_keywords
split words
drop words
recast str40 words?, force 
recast str40 words??, force 
reshape long words, i(pat_) j(number)
drop if words==""
save  "$proc\temp_words2", replace

use "$proc\data_words" if number_keywords>70, replace
drop number_keywords
split words
drop words
recast str40 words?, force 
recast str40 words??, force 
recast str40 words???, force
drop words400-words453 
drop words300-words399
drop words150-words299
reshape long words, i(pat_) j(number)
drop if words==""
save  "$proc\temp_words3", replace

use  "$proc\temp_words", clear
append using  "$proc\temp_words1"
append using  "$proc\temp_words2"
append using  "$proc\temp_words3"
save  "$proc\data_words", replace

* Add publn_nr
use pat_publn_id publn_auth publn_nr using "$proc\Patents_charact", clear
keep if publn_auth=="US"
duplicates drop
save "$proc\pat_publn_id_publn_nr", replace

use "$proc\data_words", clear
gegen word_number = group(words)
recast str20 words, force 
drop if appln_y>2020
merge m:1 pat_publn_id using "$proc\pat_publn_id_publn_nr"
keep if _merge==3
drop _merge
compress
sort appln_y
keep if  publn_auth=="US" | appln_y<1985
save "$proc\word_number_publn_nr_us", replace

}


* I) Assigne unique word number 
{
use "$prog\word_number", replace 
append using "$prog\word_number_publn_nr_us"
replace publn_auth="US" if publn_auth==""
drop number
drop word_number
compress
duplicates drop
gegen word_number = group(words)
save "$prog\word_number_full", replace 
}

* II) Publication year for each patent
{
use pat_publn_id publn_y  using  "$proc\patent_characteristics", clear
save "$proc\pat_publn_id_publn_y_granted", replace
}

* III) First occurence of a word in the world and the region
{
* 1) World
use words appln_y  pat_publn_id using "$prog\word_number_full", clear
joinby pat_publn_id using "$proc\pat_publn_id_publn_y_granted", unmatched(master)
keep words appln_y publn_y
duplicates drop
bysort words: gegen min_appln_y=min(appln_y)
bysort words: gegen min_publn_y=min(publn_y)
bysort words: egen total_min_appln_y = total(1*(appln_y<=min_appln_y+100))
keep min_appln_y min_publn_y words total_min_appln_y
duplicates drop
save "$prog\words_min_appln_y", replace

* 2) Region

use "$prog\word_number_full" , replace 
compress
duplicates drop
merge m:1 words using  "$prog\words_min_appln_y"
keep if _merge==3
drop _merge
drop words
compress
joinby publn_nr using "$prog\patentlist" 
duplicates drop
bysort ID DepositoryLibraryNumber word_number: gegen min_appln_y_region=min(appln_y)
gen words_age = appln_y-min_appln_y
save "$prog\words_extended", replace
}

* IV) Calculate word characteristics and aggregate up: new_words.dta
{
use "$prog\words_extended", replace
drop if min_appln_y==.
gen new_words = min_appln_y>1970
gen old_words= min_appln_y<=1970
gen new_words_world = (appln_y==min_appln_y)*new_words
gen new_words_region= (appln_y==min_appln_y_region)*(new_words_world==0)*new_words
gen preopening_words_region= (new_words_region==0)*(new_words_world==0)*(min_appln_y_region<openingyear) if openingyear!=. &  min_appln_y_region!=.
replace preopening_words_region=1 if old_words==1
gen postopening_words_region= (new_words_region==0)*(new_words_world==0)*new_words*(min_appln_y_region>=openingyear) if openingyear!=. &  min_appln_y_region!=.
gen old_words_region= (new_words_region==0)*(new_words_world==0)*new_words
gen new_words_region_not_world= new_words_region*(appln_y>=min_publn_y)*(new_words_world==0)
replace new_words_world=1 if new_words_region==1 & appln_y<min_publn_y & new_words_world==0

gen total_words = 1
keep old_words_region new_words old_words new_words_world new_words_region new_words_region_not_world total_words publn_nr appln_y words word_number   preopening_words_region postopening_words_region ID DepositoryLibraryNumber

duplicates drop
bys publn_nr: egen n_years=nvals(appln_y)
drop if n_years>1

gcollapse (sum) old_words_region new_words old_words new_words_world new_words_region new_words_region_not_world preopening_words_region postopening_words_region total_words, by(publn_nr ID DepositoryLibraryNumber) 
save "$prog\new_words", replace
}
}

****************************************************************************************
* F) Match relevant patents to all its characteristics and aggregate up by latitude and longitude
****************************************************************************************
{


use "$prog\patentlist", clear
joinby publn_nr ID DepositoryLibraryNumber using "$prog\new_words"
save  "$prog\new_words_withID", replace

use "$prog\patents_localized", clear
keep publn_nr weight lat lng
duplicates drop
joinby publn_nr using "$prog\new_words_withID"

global indicator
global share
global share_calc
global levels
ren new_words_world nw_w
ren new_words_region nw_r
ren new_words_region_not_world nw_r_nw
ren old_words_region ow_r
ren new_words nw
ren old_words ow
ren preopening_words_region prew_r
ren postopening_words_region postw_r


foreach x in nw_w nw_r nw_r_nw ow_r nw ow prew_r postw_r {
replace `x' = `x'*weight
gen `x'_d = `x'/total_words
gen `x'_i = (`x'>0)*weight
replace `x'_i=. if  `x'==.
replace `x'_d=. if  `x'==.

global indicator $indicator `x'_i 
global levels $levels `x'
}

** Give preference to knowledge transfer via new to region not world over other categories
replace nw_w_i=0 if nw_r_nw_i>0 & nw_r_nw_i!=.
replace postw_r_i=0 if nw_r_nw_i>0 & nw_r_nw_i!=.
replace prew_r_i=0 if nw_r_nw_i>0 & nw_r_nw_i!=.
*
replace postw_r_i=0 if nw_w_i>0 & nw_w_i!=.
replace prew_r_i=0 if nw_w_i>0 & nw_w_i!=.
*
replace prew_r_i=0 if postw_r_i>0 & postw_r_i!=.
**
gen pat_wordsclassified=weight*(postw_r_i!=.)*(nw_w_i!=.)*(nw_r_nw_i !=.) 
gen restnew_i=(nw_r_nw==0)*(nw_w==0)*(postw_r==0)*weight 
replace restnew_i=. if nw_r_nw==. 
replace restnew_i=. if nw_w==. 
replace restnew_i=. if postw_r==. 


global indicator $indicator restnew_i 

cap drop _merge
merge m:1 publn_nr using "$prog\publn_nr_new_pair"
keep if _merge==1 | _merge==3
drop _merge
global levels_pair

global share_pair

foreach x in new_pair  new_single old_couple old_single {
gen nw_r_i_`x'  = nw_r_nw_i * `x'
gen nw_w_i_`x'  = nw_w_i * `x'

global indicator $indicator nw_r_i_`x' nw_w_i_`x' 
}


gcollapse (sum) $indicator $levels pat_wordsclassified, by(appln_y lat lng ID DepositoryLibraryNumber)
ren (lat lng) (lat_patent lng_patent)
save "$prog\patents_localized_aggregated_words", replace



use "$prog\patents_localized", clear
ren nclass class_no
ren publn_y gyear
sort publn_nr
merge m:1 publn_nr using "$prog\patent_onecity.dta", gen(_merge5) //add indicator for same city patent
drop if _merge5==2
drop _merge5
gen wgt_samecity=weight*(samecity==1)

keep publn_nr appln_y weight wgt_samecity pat* lat lng psn_name pat_*  $charact area30
drop pat_publn_id

merge m:1 publn_nr using "$prog\publn_nr_new_pair"
keep if _merge==1 | _merge==3
drop _merge
global levels_pair

global share_pair

global share_pair_calc
foreach x in  new_single old_single new_pair new_pair_all new_pair_old_inv new_pair_all_old old_couple {
replace `x' = `x'*weight 
global levels_pair $levels_pair `x'
}
 
gcollapse (sum) weight pat_*  wgt_samecity  $levels_pair, by(appln_y lat lng )


global sumwords $indicator $levels $levels_pair
ren (lat lng) (lat_patent lng_patent)
save "$prog\patents_localized_aggregated", replace




* Cross with patents 
use  ID DepositoryLibraryNumber lat_library lat_patent lng_patent lon_library dist dist_15m dist_50m dist_100m dist_150m dist_0 dist_10 dist_20 dist_30 dist_40 dist_50 dist_60 dist_70 dist_80 dist_90 dist_100 dist_110 dist_120 dist_130 dist_140 dist_150 using "$prog\pat_fdl_with_patent_location", clear
duplicates drop
cap drop _merge
joinby lat_patent lng_patent using  "$prog\patents_localized_aggregated", unmatched(master)
cap drop _merge
merge 1:1  lat_patent lng_patent ID DepositoryLibraryNumber appln_y using  "$prog\patents_localized_aggregated_words"
keep if _merge==1 | _merge==3
cap drop _merge


unab k: pat_* $sumwords
foreach x in `k' {
replace `x'=`x'*dist_15m
replace `x'=0 if dist_15m==0
}

foreach x in 15 50 100 150 {
gen pat_`x'm=dist_`x'm*weight
}

gen pat_dist25=(dist<=25)*weight
gen pat_dist50=(dist<=50)*weight

gen pat_onecity=wgt_samecity*dist_15m
drop wgt_samecity
forvalues i = 0(10)150 {
gen  pat_`i'=dist_`i'*weight
}

ren weight total_patents
compress
duplicates drop

ren (lat_library lon_library) (lat lng)
gcollapse (sum) total_patents  pat_* $sumwords , by(lat lng appln_y  ID DepositoryLibraryNumber)
egen groupID=group(  ID DepositoryLibraryNumber lat lng)
xtset groupID appln_y
tsfill, full
gsort groupID -appln_y
replace lat = lat[_n-1] if groupID == groupID[_n-1] & lat ==.
replace lng = lng[_n-1] if groupID == groupID[_n-1] & lng ==.
gsort groupID +appln_y
replace lat = lat[_n-1] if groupID == groupID[_n-1] & lat ==.
replace lng = lng[_n-1] if groupID == groupID[_n-1] & lng ==.

unab k: pat_*

foreach x in total_patents `k' {
replace `x' = 0 if `x'==.
}
save "$prog\patents_lat_lng_all", replace


}

****************************************************************************************
* G) Prepare datasets for main paper
****************************************************************************************
{
* I) Raw dataset: panel_pat_fdl.dta
{
use "$prog\pat_fdl_full", replace

* Add patents and population and patent attorneys
{
ren (lat lng) (lat_patent_lib lng_patent_lib)
ren  (lat_library lon_library) (lat lng)

* Add patents
joinby lat lng ID DepositoryLibraryNumber using  "$prog\patents_lat_lng_all", unmatched(master)
drop _merge

* Add population
joinby lat lng using  "$prog\population_lat_lng_all", unmatched(master)
drop _merge
joinby lat lng appln_y using  "$prog\population_lat_lng_nber", unmatched(master)
drop _merge


joinby lat lng appln_y using  "$prog\patent_attorneys_lat_lng_all", unmatched(master)
drop _merge
}

* Normalize patent counts by population; create various variables
{

gen pat_pop_distance = pat_15m/pop_15m*100000
foreach x in 50 100 150 {
gen pat_pop_`x'm= pat_`x'm/pop_`x'm*100000
}

gen pat_pop_distance25m=pat_dist25/pop_dist25*100000
gen pat_pop_distance50m=pat_dist50/pop_dist50*100000
gen pat_pop_onecity=pat_onecity/pop_15m*100000


gen pat_young=.
gen pat_small=.
levelsof(openingyear), local(openingyear)

forvalues y = 10(10)50 {
gen pat_small_`y' = .
}
forvalues y = 10(10)10 {
foreach x in `openingyear' {
cap replace pat_small_`y' = pat_small_`y'_`x' if openingyear==`x'
cap replace pat_young = pat_young_`x' if openingyear==`x'
}
}
forvalues y = 10(10)10 {
gen pat_pop_small_`y' = pat_small_`y'/pop_15m*100000
gen pat_small_overall_`y'_pc = pat_small_overall_`y'/pop_15m*100000
}
replace pat_small = pat_small_10
replace pat_small = 0 if pat_small==.
gen pat_pop_small = pat_pop_small_10
gen pat_pop_big = pat_pop_distance-pat_pop_small
gen pat_pop_young = pat_young/pop_15m*100000
gen pat_pop_old = pat_pop_distance-pat_pop_young
gen pat_pop_total_forward_cites=pat_total_forward_cites/pop_15m*100000



foreach x in $sumwords pat_wordsclassified {
cap gen `x'_pop=`x'/pop_15m*100000
replace `x'_pop=0 if `x'_pop==.
}



foreach x in pat_company pat_non_profit pat_uni_hosp pat_independent {
gen `x'_pc = `x'/pop_15m*100000
} 
unab k: pat_cat* pat_subcat* pat_area30_* pat_mainarea30_* pat_area35_* pat_mainarea35_*
foreach x in `k' {
replace `x' = `x'/pop_15m*100000
}

gen pat_attorneys_distance = patent_attorneys_15m/pop_15m*100000

ren ID pat_ID

gen uni_library=0
replace uni_library=regexm(ParentInstitutionofLibrary, "University")
replace uni_library = uni_library*(patent_lib==1)
cap drop m
bysort pat_ID: egen m = max(uni_library)
replace uni_library=m
drop m

unab k: pat_*
foreach x in `k' {
cap replace `x' = 0 if `x'==.
}

bysort pat_ID: egen high_low = mean(pat_pop_distance)
sum high_low, detail
gen hist_high = high_low>r(p50)
drop high_low


egen identifier = group(pat_ID DepositoryLibraryNumber)
gen treated = patent_lib
gen yearsopen10 = appln_y-openingyear
egen stateid=group(state_fdl)
drop if pat_ID==.
drop if yearsopen10==.

}
egen yearID2 = group(appln_y)
compress

*Labels
{
drop  pat_libr_name LibraryName DepositoryType ParentInstitutionofLibrary_fdl zip dislat min_dist_FDL_pat total_patents pat_independent fips pat_company pat_non_profit pat_uni_hosp pat_young* pat_small* pat_wordsclassified pat_50m pat_100m pat_150m pat_dist50 pat_dist25 pat_0 pat_10 pat_20 pat_30 pat_40 pat_50 pat_60 pat_70 pat_80 pat_90 pat_100 pat_110 pat_120 pat_130 pat_140 pat_150 nw_w_i nw_r_i nw_r_nw_i ow_r_i nw_i ow_i prew_r_i postw_r_i restnew_i nw_r_i_new_pair nw_w_i_new_pair nw_r_i_new_single nw_w_i_new_single nw_r_i_old_couple nw_w_i_old_couple nw_r_i_old_single nw_w_i_old_single nw_w nw_r nw_r_nw ow_r nw ow prew_r postw_r old_single new_single new_pair new_pair_all new_pair_old_inv new_pair_all_old old_couple groupID pop_dist5 pop_dist25 pop_dist50 pop_0 pop_10 pop_20 pop_30 pop_40 pop_50 pop_60 pop_70 pop_80 pop_90 pop_100 pop_110 pop_120 pop_140 pop_150 pop_50m pop_150m pop_100m patent_attorneys_0 patent_attorneys_50 patent_attorneys_100 patent_attorneys_150 patent_attorneys_50m patent_attorneys_100m pat_pop_150m pat_pop_small_10 pat_small_overall_10_pc nw_w_i_new_pair_pop nw_r_i_new_pair_pop nw_r_i_new_single_pop nw_w_i_new_single_pop nw_r_i_old_couple_pop nw_w_i_old_couple_pop nw_w_i_old_single_pop nw_r_i_old_single_pop pop_130 pop_nber patent_attorneys_150m prew_r_i_pop nw_w_pop nw_r_pop nw_r_nw_pop ow_r_pop nw_pop prew_r_pop ow_pop postw_r_pop lat_patent_lib lng_patent_lib pat_area34* pat_mainarea34* pat_onecity nw_r_i_pop ow_r_i* nw_i_pop ow_i_pop new_pair_all_pop new_pair_old_inv_pop new_pair_all_old_pop pat_mainarea35_*


label var openingyear "Opening year of patent library"
label var pat_ID "ID of patent library"
label var state_patent_library "State of patent library"
label var lat "Latitude of library"
label var lng "Longitude of library"
label var pat_FDL_dist "Distance between PTDL and FDL"
label var patent_lib_institutions ""
label var patent_lib "Patent library indicator"
label var appln_y "Application year of patents"
label var pat_total_forward_cites "Forward-cites-weighted patents"
label var pat_15m "Patents in 15m around library"
label var city_patent_library "City of patent library"
label var ParentInstitutionofLibrary "Parent institution of patent library"
label var patent_lib_institutions "Patent library is FDL"
label var pop_15m "Population in 15m around library"
label var pop_nber15m "Time-varying population around library"
label var patent_attorneys_15m "Patent attorneys in 15m around library"
label var pat_pop_distance "Patents p.c. in 15m around library"
label var pat_pop_50m "Patents p.c. in 15-50m around library"
label var pat_pop_100m "Patents p.c. in 50-100m around library"
label var pat_pop_distance25m "Patents p.c. of inventors within 25m of library"
label var pat_pop_distance50m "Patents p.c. of inventors within 50m of library"
label var pat_pop_onecity "Patents p.c. of inventors within 15m of library"
label var pat_pop_small "Patents p.c. of small inventors (see text)"
label var pat_pop_big "Patents p.c. of large inventors (see text)"
label var pat_pop_young "Patents p.c. of young inventors (see text)"
label var pat_pop_old  "Patents p.c. of old inventors (see text)"
label var pat_pop_total_forward_cites "Forward-cites-weighted patents p.c. in 15m around library"
label var nw_w_i_pop "Patents p.c. in 15m around library with words new to world"
label var nw_r_nw_i_pop "Patents p.c. in 15m around library with words new to region but not world"
label var postw_r_i_pop "Patents p.c. in 15m around library with words that only appeared after PTDL opening"
label var restnew_i_pop "Patents p.c. in 15m around library with only old words"
label var new_single_pop "Patents p.c. in 15m around library by new single inventors" 
label var old_single_pop "Patents p.c. in 15m around library by existing single inventors"
label var new_pair_pop "Patents p.c. in 15m around library by (partially) new inventor pairs"
label var old_couple_pop "Patents p.c. in 15m around library by existing inventor pairs"
label var pat_wordsclassified_pop  "Patents p.c. in 15m around library with words classification"
label var pat_non_profit_pc "Patents p.c. in 15m around library by non-profit inventors" 
label var pat_company_pc "Patents p.c. in 15m around library by company inventors" 
label var pat_uni_hosp_pc "Patents p.c. in 15m around library by university or hospital inventors" 
label var pat_independent_pc  "Patents p.c. in 15m around library by independent inventors" 
label var pat_attorneys_distance  "Patent attorneys p.c. in 15m around library"
label var uni_library "University library"
label var hist_high "Historically high-patenting region"
label var identifier "ID for PTDL-FDL combination"
label var treated "Patent library indicator"
label var yearsopen10 "Years relative to PTDL opening"
label var stateid "State ID"
label var yearID2 "Application year ID"

foreach x in 11 12 13 14 15 19 21 22 23 24 25 31 32 33 39 41 42 42 43 44 45 46 49 51 52 53 54 55 59 61 62 63 64 65 66 67 68 69 {
label var pat_subcat_`x' "Patents in  NBER Subcategory `x'"
}

forvalues x=1/6 {
label var pat_cat_`x' "Patents in NBER Category `x'"
}
 
forvalues x=1/30{
label var pat_area30_`x'  "Patents in ISI-OST-INPI Area `x'"
}

forvalues x=1/6{
label var pat_mainarea30_`x'  "Patents in ISI-OST-INPI Main Area `x'"
}

forvalues x=201/235{
label var pat_area35_`x'  "Patents in ISI-OST-INPI Technological Category `x'"
}

}

compress
save "$prog\panel_pat_fdl", replace


* Match by state
cd "$prog"
use panel_pat_fdl, clear
keep if state_patent_library == state_fdl 
save panel_pat_fdl_state, replace
}

* II) Auxillary dataset: Matched only on distance
{
cd "$prog"
use panel_pat_fdl, clear
keep if yearsopen10>=-5 & yearsopen10<=5
bys pat_ID DepositoryLibraryNumber: egen mp=min(pat_pop_distance)
keep if mp>0 
drop if patent_lib == 1 & patent_lib_institutions==0
drop if LibrarySize=="Small (less than 250,000 volumes in the library)"
drop if DepositoryLibraryNumber=="0580A"

egen strata_id = group(pat_ID )
bysort strata_id: egen mean = mean(treated)
drop if   mean==0
drop if   mean==1
drop mean strata_id mp
keep if pat_ID!=15 | pat_ID==.   //burlington, vt

keep if yearsopen10>=-5 & yearsopen10<=5
keep if openingyear>=Yearof 
compress
save "$prog\main_work_distance_matched.dta", replace
}

* III) Main dataset: main_work.dta 
{
cd "$prog"
use panel_pat_fdl_state, clear // matched on distance AND state
keep if pat_FDL_dist> 30 | patent_lib==1
drop if LibrarySize=="Small (less than 250,000 volumes in the library)"
keep if yearsopen10>=-5 & yearsopen10<=5
drop if patent_lib == 1 & patent_lib_institutions==0

egen strata_id = group(pat_ID )
bysort strata_id: egen mean = mean(treated)
drop if   mean==0 |  mean==1
drop mean strata_id
keep if pat_ID!=15 | pat_ID==.  //burlington, vt

keep if yearsopen10>=-5 & yearsopen10<=5
keep if openingyear>=Yearof
compress
save "$prog\main_work.dta", replace

}


* IV) Auxillary dataset: List of patent libraries in main sample
{
u "$prog\main_work.dta", clear
cem pat_ID(#0) stateid(#0) $matched, treatment(treated)
drop if cem_matched==0
keep pat_ID
duplicates drop
compress
save "$prog\listofpatentlibs.dta", replace

}


* V) Auxillary dataset: main_work_longpostperiod.dta; longer time period
{
cd "$prog"
use panel_pat_fdl_state, clear
drop if LibrarySize=="Small (less than 250,000 volumes in the library)"
keep if yearsopen10>=-5 & yearsopen10<=10
drop if patent_lib == 1 & patent_lib_institutions==0

egen strata_id = group(pat_ID )
bysort strata_id: egen mean = mean(treated)
drop if   mean==0
drop if   mean==1
drop mean strata_id
keep if pat_ID!=15 | pat_ID==.  //burlington, vt

keep if yearsopen10>=-5 & yearsopen10<=10
keep if openingyear>=Yearof
compress
save "$prog\main_work_longpostperiod.dta", replace
}

}

****************************************************************************************
* H) Prepare main_work_inventor: used exclusively in Appendix
****************************************************************************************

{
use "$prog\patent_characteristics", clear
ren lat lat_patent
ren lon lng_patent
sort appln_id publn_y
duplicates drop appln_id, force // keep earliest patent publication (81 patents deleted)
compress
save "$prog\patent_characteristics_short", replace


use "$prog\main_work.dta", clear
keep pat_ID pat_pop_distance yearsopen10 patent_lib appln_y openingyear identifier lat lng stateid
joinby lat lng using  "$prog\fdl_libray_all_cross", unmatched(master)
keep if dist_15m==1
drop _merge
duplicates drop
joinby lat_patent lng_patent appln_y using  "$prog\patent_characteristics_short"
compress
egen yearID = group(yearsopen10)
label var yearID "ID for year relative to PTDL opening"
gen post   = yearsopen10>=0
xi i.post*patent_lib, noomit


gen treated = patent_lib
label var treated "PTDL dummy"
drop if backward_p50_dist>2458.634 | backward_p50_dist==0 //5th, 95th pct
cap drop groupID
egen groupID= group(pat_ID stateid)
bysort groupID: egen m = mean(treated)
drop if m == 0 | m==1

keep pat_ID area30  yearsopen10 treated min_appln_y openingyear psn_id originality area_cited  total_backward_cites  post patent_lib _IposXpaten_1   total_forward_cites backward_p50_dist originality area_cited


label var area30  "ISI-OST-INPI Area"
label var total_forward_cites "Total forward cites"
label var total_backward_cites "Total backward cites"
label var originality "Originality"
label var area_cited "Number of areas cited"
label var backward_p50_dist "Median backward citation distance"
label var psn_id "Inventor ID"
label var min_appln_y "Earliest patent application year"
label var post "Post PTDL opening dummy"
label var _IposXpaten_1 "Interaction dummy between PTDL opening and post-opening period"

compress
save "$prog\main_work_inventor.dta", replace

}






