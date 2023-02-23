*Analysis among valproate users

*Among valproate users, with epilepsy, over years

use "$Datadir\Derived_data\Combined_datasets\Descriptives_paper\dataset_descriptives_paper.dta", clear
keep if aed_class==22
tab use

egen preg_year_gp=cut(pregstart_year), at(1995(5)2020)
tab preg_year_gp

*Table of patterns

 table1_mc,  by(  preg_year_gp ) ///
			vars( /// 
				 use cat %5.1f \ ///
				) ///
			nospace onecol missing total(before) ///
			saving("$Datadir\Descriptive_statistics\ASM_use_paper\Table_valproate_use_paper_epilepsy.xlsx", replace)

tempname myhandle	
file open `myhandle' using "$Datadir\Descriptive_statistics\ASM_use_paper\patterns_percent_over_time.txt", write replace
file write `myhandle' "year_gp" _tab  "indication" _tab "use"  _tab "percent" _tab "Number with use pattern" _tab "Total with indication" _n

foreach year in 1995 2000 2005 2010 2015 {
tab use if preg_year_gp==`year'
local total=`r(N)'
levelsof use,  local(uselevs) sep(	)
foreach level in `r(levels)' {
file write `myhandle' "`year'" _tab "all" _tab "`level'" _tab
tab use if use==`level' &  preg_year_gp==`year'
local num=`r(N)'
local percent=(`num'/`total')*100
file write `myhandle' %4.2f (`percent') _tab %4.2f (`num') _tab %4.2f (`total')  _n
}

foreach ind in epilepsy bipolar somatic_cond other_psych_gp {
	tab use if `ind'==1 & preg_year_gp==`year'
local total=`r(N)'
levelsof use,  local(uselevs) sep(	)
foreach level in `r(levels)' {
file write `myhandle' "`year'" _tab  "`ind'" _tab "`level'" _tab
tab use if use==`level' &`ind'==1 & preg_year_gp==`year'
local num=`r(N)'
local percent=(`num'/`total')*100
file write `myhandle' %4.2f (`percent') _tab %4.2f (`num') _tab %4.2f (`total')  _n
}
}
}

import delimited "$Datadir\Descriptive_statistics\ASM_use_paper\patterns_percent_over_time.txt", clear
sort indication year use
label define use  1 "Continuous" 3 "Late discontinuation" 4 "Initiate during pregnancy" 9 "Other"
lab val use use
keep if indication=="all"
drop number*
reshape wide percent, i(year) j(use)

label define lb_year 1995 "1995-1999" 2000 "2000-2004" 2005 "2005-2009" 2010 "2010-2014" 2015 "2015-2018"
label values year_gp lb_year

local n1 = totalwithindication[1]
local n2 = totalwithindication[2]
local n3 = totalwithindication[3]
local n4 = totalwithindication[4]
local n5 = totalwithindication[5]

graph bar percent*, over(year)  ///
	bar(1, fcolor(navy) lcolor(navy)) ///
	bar(2, fcolor(forest_green) lcolor(forest_green)) ///
	bar(3, fcolor(dkorange) lcolor(dkorange)) ///
	bar(4, fcolor(teal) lcolor(teal)) ///
	stack  ///
	ytitle("Pregnancies (%)", size(small)) ///
	ylabel(0(20)100, angle(horizontal) labsize(vsmall)) ///
	graphregion(color(white)) ///
	bgcolor(white) ///
	blabel(percent1, position(inside)) ///
	legend(label(1 "Continuous") label(2 "Late discontinuation") ///
		   label(3 "Initiate during pregnancy") label(4 "Other") ///
		   cols(2) size(vsmall)) ///
	text(105 3    "N = `n1'", placement(r) size(small)) ///
	text(105 23   "N = `n2'", placement(r) size(small)) ///
	text(105 43.5 "N = `n3'", placement(r) size(small)) ///
	text(105 64.5 "N = `n4'", placement(r) size(small)) ///
	text(105 85   "N = `n5'", placement(r) size(small)) 

 graph export "$Graphdir/descriptivepaper/figureS3use_patterns_valproate_over_time.png", width(1000) replace
 graph export "$Graphdir/descriptivepaper/figureS3use_patterns_valproate_over_time.pdf", replace

 
********************************************************************************

use "$Datadir\Derived_data\Combined_datasets\Descriptives_paper\dataset_descriptives_paper.dta", clear
keep if flag_valproate_preg==1 | flag_valproate_prepreg==1
tab use

*Table of patterns
foreach ind in epilepsy bipolar somatic_cond other_psych_gp {
   recode `ind' .=0
 
table1_mc,  by(  `ind' ) ///
			vars( /// 
				 use cat %5.1f \ ///
				) ///
			nospace onecol missing total(before) ///
			saving("$Datadir\Descriptive_statistics\ASM_use_paper\TableS2_ASM_use_paper_`ind'_valproate.xlsx", replace)
}

tempname myhandle2	
file open `myhandle2' using "$Datadir\Descriptive_statistics\ASM_use_paper\patterns_percent_valproate.txt", write replace
file write `myhandle2' "indication" _tab "use" _tab "percent" _n

tab use
local total=`r(N)'
levelsof use,  local(uselevs) sep(	)
foreach level in `r(levels)' {
	file write `myhandle2' "all" _tab "`level'" _tab
	tab use if use==`level'
	local num=`r(N)'
	local percent=(`num'/`total')*100
	file write `myhandle2' %4.2f (`percent') _n
}

foreach ind in epilepsy bipolar somatic_cond other_psych_gp {
	tab use if `ind'==1
	local total=`r(N)'
	levelsof use,  local(uselevs) sep(	)
	foreach level in `r(levels)' {
		file write `myhandle2' "`ind'" _tab "`level'" _tab
		tab use if use==`level' &`ind'==1
		local num=`r(N)'
		local percent=(`num'/`total')*100
		file write `myhandle2' %4.2f (`percent') _n
	}
}

tab use
tab epilepsy
tab bipolar
tab other_psych_gp
tab somatic_cond


import delimited "$Datadir\Descriptive_statistics\ASM_use_paper\patterns_percent_valproate.txt", clear
reshape wide percent, i(indication) j(use)

graph bar percent*, over(indication, relabel(1 `""All pregnancies in" "women prescribed" "valproate" "(N=1,376)"' 3 `""Pregnancies in" "women with" "epilepsy (N=1,129)"' 2 `""Pregnancies in" "women with" "bipolar (N=176)"' 4 `""Pregnancies in" "women with" "other psychiatric" "conditions (N=721)"' 5 `""Pregnancies in" "women with" "other somatic" "conditions (N=319)"')  label(labsize(vsmall) angle(45) ) ) stack  ylabel(0(20)100, angle(horizontal) labsize(vsmall)) ytitle("Pregnancies (%)", size(small)) graphregion(color(white)) bgcolor(white) blabel(percent1, position(inside)) ///
 legend(label(1 "Continuous") label(2 "Pre-pregnancy discontinuation") label(3 "Late discontinuation") ///
label(4 "Initiate during pregnancy")  label(5 "Other") cols(2) size(vsmall)) saving( "$Graphdir/descriptivepaper/use_patterns.gph",  replace)


 graph export "$Graphdir/descriptivepaper/figureS2_use_patterns_valproate.jpg", width(10000) replace

  erase "$Graphdir/descriptivepaper/use_patterns.gph"

 
 