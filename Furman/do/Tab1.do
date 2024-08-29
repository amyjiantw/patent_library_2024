* Table 1

u "data/main_work", clear

cem pat_ID(#0) stateid(#0) $matched, treatment(treated)
drop if cem_matched==0
drop cem*


keep if yearsopen10==-1

global characteristics1 pop_15m uni_library pat_15m pat_pop_distance pat_pop_total_forward_cites  pat_pop_small pat_pop_big pat_pop_young pat_pop_old 
global characteristics3 pat_mainarea30_1 pat_mainarea30_2 pat_mainarea30_3 pat_mainarea30_4 pat_mainarea30_5 pat_mainarea30_6

collapse (mean) $characteristics1 $characteristics2 $characteristics3 , by(patent_lib pat_ID)

label var pat_pop_distance "\# Patents/100k"
label var pat_15m "\# Patents"
label var pat_pop_small "\# Pat. small firms/100k"
label var pat_pop_big "\# Pat. big firms/100k"
label var pat_pop_young "\# Pat. young firms/100k"
label var pat_pop_old "\# Patents old firms/100k"
label var pat_pop_total_forward_cites "Citation-weighted patents"
label var pat_mainarea30_1  "Electrical Engineering"
label var pat_mainarea30_2 "Instruments"
label var pat_mainarea30_3 "Chemistry"
label var pat_mainarea30_4  "Process Engineering"
label var pat_mainarea30_5 "Mechanical Engineering"
label var pat_mainarea30_6 "Other Fields"
label var pop_15m "Population in 100k"
label var uni_library "Uni Library"

replace pop_15m= pop_15m/100000

bys patent_lib: sum pop_15m, d

eststo r2: estpost  ttest $characteristics1, by(patent_lib) unequal
esttab r2 using "results\Tab1a.tex", cells("mu_2(fmt(%9.2f) label(Patent Libraries)) mu_1(fmt(%9.2f) label(Control Libraries)) b(fmt(%9.2f) label(Diff)) p(fmt(%9.2f) label(P-Value))") fragment booktabs nodepvar noobs nomtitle nonumbers label star(* 0.10 ** 0.05 *** 0.01) staraux  replace

eststo r2: estpost  ttest $characteristics3, by(patent_lib) unequal
esttab r2 using "results\Tab1b.tex", cells("mu_2(fmt(%9.2f) label(Patent Libraries)) mu_1(fmt(%9.2f) label(Control Libraries)) b(fmt(%9.2f) label(Diff)) p(fmt(%9.2f) label(P-Value))") fragment booktabs nodepvar noobs nomtitle nonumbers label star(* 0.10 ** 0.05 *** 0.01) staraux  replace