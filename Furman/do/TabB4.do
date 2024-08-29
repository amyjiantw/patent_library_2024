* Table B-4

use "data\main_work_inventor", clear
bysort pat_ID area30  yearsopen10: egen m_t = mean(treated)
drop if m_t==0 | m_t==1

gen young_firm = min_appln_y>=openingyear-3
drop min_appln_y
bysort psn_id: egen size_firm = sum(1)
cap drop groupID
egen groupID = group(pat_ID  yearsopen10 ) 

foreach x in originality area_cited {
replace `x' = `x'*100
}

eststo r1: areg total_backward_cites  post patent_lib _IposXpaten_1  if  young_firm==1 , cluster(pat_ID)  ab(groupID)
eststo r2: areg total_forward_cites  post patent_lib _IposXpaten_1   if  young_firm==1   , cluster(pat_ID)  ab(groupID)
eststo r3: areg backward_p50_dist    post patent_lib _IposXpaten_1  if  young_firm==1  , cluster(pat_ID)  ab(groupID)
eststo r4: areg originality  post patent_lib _IposXpaten_1  if  young_firm==1   , cluster(pat_ID) ab(groupID)
eststo r5: areg area_cited  post patent_lib _IposXpaten_1    if  young_firm==1  , cluster(pat_ID) ab(groupID)

eststo r6: areg total_backward_cites  post patent_lib _IposXpaten_1  if  young_firm==0 , cluster(pat_ID)  ab(groupID)
eststo r7: areg total_forward_cites  post patent_lib _IposXpaten_1   if  young_firm==0   , cluster(pat_ID)  ab(groupID)
eststo r8: areg backward_p50_dist    post patent_lib _IposXpaten_1  if  young_firm==0  , cluster(pat_ID)  ab(groupID)
eststo r9: areg originality  post patent_lib _IposXpaten_1 if  young_firm==0   , cluster(pat_ID) ab(groupID)
eststo r10: areg area_cited  post patent_lib _IposXpaten_1  if  young_firm==0   , cluster(pat_ID) ab(groupID)

label var _IposXpaten_1 "Pat Lib x Post"
label var post   "Post "
label var patent_lib "Patent Library"


estout r1  r3 r4 r5 r2  using "results\TabB4a.tex" , cells(b(fmt(1) star) se(fmt(1) par))  stats( N, fmt(%18.0g) labels(  `"Obs."')) ///
starlevels(`"*"' 0.10 `"**"' 0.05 `"***"' 0.01, label(" \(p<@\)")) delimiter(&) end(\\) ///
prefoot("\hline") label varlabels(_cons Constant) mlabels(none) nonumbers collabels(none) eqlabels(, begin("\hline" "") nofirst) substitute(_ \_ "\_cons " \_cons) interaction(" $\times$ ") notype ///
level(95) style(esttab) keep(  _IposXpaten_*) order( _IposXpaten_*  ) replace


estout  r6 r8 r9 r10  r7  using "results\TabB4b.tex" , cells(b(fmt(1) star) se(fmt(1) par))  stats( N, fmt(%18.0g) labels(  `"Obs."')) ///
starlevels(`"*"' 0.10 `"**"' 0.05 `"***"' 0.01, label(" \(p<@\)")) delimiter(&) end(\\) ///
prefoot("\hline") label varlabels(_cons Constant) mlabels(none) nonumbers collabels(none) eqlabels(, begin("\hline" "") nofirst) substitute(_ \_ "\_cons " \_cons) interaction(" $\times$ ") notype ///
level(95) style(esttab) keep(  _IposXpaten_*) order( _IposXpaten_*  ) replace
