********************************************************************************
*Describe patterns of use
********************************************************************************
*

********************************************************************************
* Install required packages
********************************************************************************
*ssc install table1_mc

*Table 3: The proportion of completed pregnancies where ASMs were continued, discontinued, initiated or switched during pregnancy, overall and by ASM indication, among women with ASM prescribing before, during or after pregnancy

use "$Datadir\Derived_data\Combined_datasets\Descriptives_paper\dataset_descriptives_paper.dta", clear
keep if flag_anydrug_preg==1 | flag_anydrug_prepreg==1
tab use

*Table of patterns
foreach ind in epilepsy bipolar somatic_cond other_psych_gp {
   recode `ind' .=0
 
table1_mc,  by(  `ind' ) ///
			vars( /// 
				 use cat %5.1f \ ///
				) ///
			nospace onecol missing total(before) ///
			saving("$Datadir\Descriptive_statistics\ASM_use_paper\TableS1_ASM_use_paper_`ind'.xlsx", replace)
}

tempname myhandle	
file open `myhandle' using "$Datadir\Descriptive_statistics\ASM_use_paper\patterns_percent.txt", write replace
file write `myhandle' "indication" _tab "use" _tab "percent" _n

tab use
local total=`r(N)'
levelsof use,  local(uselevs) sep(	)
foreach level in `r(levels)' {
file write `myhandle' "all" _tab "`level'" _tab
tab use if use==`level'
local num=`r(N)'
local percent=(`num'/`total')*100
file write `myhandle' %4.2f (`percent') _n
}

foreach ind in epilepsy bipolar somatic_cond other_psych_gp {
	tab use if `ind'==1
local total=`r(N)'
levelsof use,  local(uselevs) sep(	)
foreach level in `r(levels)' {
file write `myhandle' "`ind'" _tab "`level'" _tab
tab use if use==`level' &`ind'==1
local num=`r(N)'
local percent=(`num'/`total')*100
file write `myhandle' %4.2f (`percent') _n
}
}

tab use
tab epilepsy
tab bipolar
tab  other_psych_gp
tab somatic_cond


import delimited "$Datadir\Descriptive_statistics\ASM_use_paper\patterns_percent.txt", clear
reshape wide percent, i(indication) j(use)

graph bar percent*, over(indication, relabel(1 `""All pregnancies"  "(N=8,753)"' 3 `""Pregnancies in" "women with" "epilepsy (N=4,099)"' 2 `""Pregnancies in" "women with" "bipolar (N=436)"' 4 `""Pregnancies in" "women with" "other psychiatric" "conditions (N=5,816)"' 5 `""Pregnancies in" "women with" "other somatic" "conditions (N=3,041)"')  label(labsize(vsmall) angle(45) ) ) stack  ylabel(0(20)100, angle(horizontal) labsize(vsmall)) ytitle("Pregnancies (%)", size(small)) graphregion(color(white)) bgcolor(white) blabel(percent1, position(inside)) ///
 legend(label(1 "Continuous") label(2 "Pre-pregnancy discontinuation") label(3 "Late discontinuation") ///
label(4 "Initiate during pregnancy")  label(5 "Other") cols(2) size(vsmall)) saving( "$Graphdir/descriptivepaper/use_patterns.gph",  replace)


 graph export "$Graphdir/descriptivepaper/figure4_use_patterns.png", width(2000) height(1500)  replace

  erase "$Graphdir/descriptivepaper/use_patterns.gph"
