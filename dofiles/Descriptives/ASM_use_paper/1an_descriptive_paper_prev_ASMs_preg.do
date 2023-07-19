******************************************************************************
* Author: 	Harriet Forbes
* Date: 	21 April 2021
* Description:  Produces graphs for secular trends in AED prescribing
* Starts by formatting data into tables, saves as temporary files, then
*creates graphs
******************************************************************************

set scheme s2color
net install grc1leg, from(http://www.stata.com/users/vwiggins/)

*********************************************************************************
*1.Figure 1
*********************************************************************************
*Generates tables (in tempfile), overall then by inidcation 

cd "$Datadir\Descriptive_statistics\ASM_use_paper"
foreach indication in All epilepsy bipolar somatic_cond other_psych_gp {
	use "$Datadir\Derived_data\Combined_datasets\Descriptives_paper\dataset_descriptives_paper.dta", clear
	count /*total pregs*/
	gen n=1

	preserve
		recode flag_anydrug_preg 0=.
		collapse (count) flag_anydrug_preg (count) n
		gen percent_preg=(flag_anydrug_preg/n)*100
		keep percent n
		list
	restore

	gen pregyear=year(pregstart_num)
	tab flag_anydrug_prd1 pregyear, col chi

	gen All=1

	if "`indication'"!="All" {
		keep if `indication'==1
	}	

	/**Keep necessary variables
	keep flag_* pregyear polytherapy dosage_tri_1 n 
	gen flag_other_new_preg=1 if flag_other_prd5==1 | flag_other_prd6==1 ///
	| flag_other_prd7==1 | flag_topiramate_prd5==1 | flag_topiramate_prd6==1 ///
	| flag_topiramate_prd7==1 | flag_phenytoin_prd5==1 | flag_phenytoin_prd6==1 ///
	| flag_phenytoin_prd7==1*/

	***TABLE FOR FIGURE 1: year and % exposed for any indication by pregnancy
	*period (Pre-pre-pregnancy, preg and post-pregnancy)
	*Pre-pre-pregnancy, preg and post-pregnancy, by year
	foreach x in prepreg preg {
		preserve
			recode flag_anydrug_`x' 0=.
			collapse (count) flag_anydrug_`x' (count) n, by(pregyear)
			gen prop_`x' = flag_anydrug_`x'/n
			gen percent_`x'= prop_`x'*100
			gen se_`x' = sqrt(prop_`x' * (1-prop_`x') / n ) 
			gen lciperc_`x' = 100 * (prop_`x' -  invnormal(0.975) * se_`x')    
			gen uciperc_`x' = 100 * (prop_`x' +  invnormal(0.975) * se_`x')    
			keep pregyear percent n se lci uci
			list
			tempfile period`x'
			save `period`x''
		restore
	}

	*Figure 1a
	use `periodprepreg', clear
	foreach x in  preg  {
		merge 1:1  pregyear using `period`x'', nogen
	}
	gen `indication'=1
	cap lab var All All
	cap lab var epilepsy Epilepsy
	cap lab var bipolar Bipolar
	cap lab var somatic_cond "Other somatic conditions"
	cap lab var other_psych_gp "Other psychiatric conditions"
	local label: variable label `indication'
	save "$Datadir\Derived_data\CPRD\_temp\fig2_`indication'.dta", replace

}


   *Figure 1b
*all  
use "$Datadir\Derived_data\CPRD\_temp\fig2_All.dta", replace
keep pregyear percent_preg lciperc_preg uciperc_preg

twoway line  percent_preg pregyear, color(blue) || ///
	   rarea uciperc_preg lciperc_preg pregyear , color(blue%20) ///
		ylabel(0(1)2, angle(horizontal) labsize(vsmall)) ///
		xlabel(, labsize(vsmall)) ///
		xtitle("Year of pregnancy", size(vsmall)) ///
		graphregion(color(white)) bgcolor(white) ///
		lwidth(medthick medthick medthick medthick medthick) ///
		ytitle("Prevalence of ASM prescribing" " " "among all pregnancies (%)" " ", size(vsmall)) ///
		text(3 1995 "a) Overall", placement(r) size(small)) ///
		fysize(25) graphregion(margin(large)) ///
		legend(off) ///
		name(fig2_all, replace)
  
  
*indications
use "$Datadir\Derived_data\CPRD\_temp\fig2_epilepsy.dta", replace
foreach indication in  bipolar somatic_cond other_psych_gp {
	append using "$Datadir\Derived_data\CPRD\_temp\fig2_`indication'.dta"
}

gen ind=2 if  epilepsy==1
replace ind=3 if  bipolar==1 
replace ind=4 if  somatic_cond==1
replace ind=5 if  other_psych_gp==1
list
keep pregyear percent_preg ind lciperc_preg uciperc_preg
*reshape wide percent lciperc_preg uciperc_preg, i(pregyear) j(ind)

twoway 	rarea uciperc_preg lciperc_preg pregyear if ind == 2 , color(navy%20) || ///
		rarea uciperc_preg lciperc_preg pregyear if ind == 3 , color(maroon%20) || ///
		rarea uciperc_preg lciperc_preg pregyear if ind == 4 , color(forest_green%20) || ///
		rarea uciperc_preg lciperc_preg pregyear if ind == 5 , color(dkorange%20) || ///
		line  percent_preg* pregyear if ind == 2, color(navy)  || ///
		line  percent_preg* pregyear if ind == 3, color(maroon) || ///
		line  percent_preg* pregyear if ind == 4, color(forest_green) || ///
		line  percent_preg* pregyear if ind == 5, color(dkorange)  ///
		ylabel(0(10)60, angle(horizontal) labsize(vsmall)) ///
		xlabel(, labsize(vsmall)) ///
		xtitle("Year of pregnancy", size(vsmall)) ///
		graphregion(color(white)) bgcolor(white) ///
		lwidth(medthick medthick medthick medthick medthick) ///
		ytitle("Prevalence of ASM prescribing" " " "among pregnancies with the indication (%)" " ", size(vsmall)) ///
		legend(order(5 "Epilepsy" ///
					 6 "Bipolar" ///
					 7 "Other somatic" ///
					 8 "Other psychiatric") ///
					 cols(2) size(vsmall) textw(*7)) ///
		text(70 1995 "b) By indication", placement(r) size(small)) ///
		fysize(75) graphregion(margin(large)) ///
		name(fig2_ind, replace)
	
graph combine fig2_all fig2_ind, cols(1) graphregion(color(white))
graph export "$Graphdir/descriptivepaper/figure1.svg", replace width(1500) height(2000)
graph export "$Graphdir/descriptivepaper/figure1.png", replace width(1500) height(2000)
graph export "$Graphdir/descriptivepaper/figure1.pdf", replace 


*********************************************************************************
*Figure 3
*********************************************************************************

foreach indication in All epilepsy bipolar somatic_cond other_psych_gp {
	cd "$Projectdir"
	use "$Datadir\Derived_data\Combined_datasets\Descriptives_paper\dataset_descriptives_paper.dta", clear
	count /*total pregs*/
	gen n=1

	gen pregyear=year(pregstart_num)
	tab flag_anydrug_prd1 pregyear, col chi

	gen All=1

	if "`indication'"=="All" {
	}
	if "`indication'"!="All" {
		keep if `indication'==1
	}	

	*Keep necessary variables
	keep flag_* pregyear dosage_tri_1 n 
	gen flag_other_new_preg=1 if flag_other_prd5==1 | flag_other_prd6==1 ///
	| flag_other_prd7==1 | flag_topiramate_prd5==1 | flag_topiramate_prd6==1 ///
	| flag_topiramate_prd7==1 | flag_phenytoin_prd5==1 | flag_phenytoin_prd6==1 ///
	| flag_phenytoin_prd7==1

	***TABLE FOR FIGURE 4: % exposed for any indication by the 7 pregnancy periods
	*Each pregnancy period through whole study period
	forvalues x=1/7 {
		preserve
		recode flag_anydrug_prd`x' 0=.
		collapse (count) flag_anydrug_prd`x' (count) n
		gen percent=(flag_anydrug_prd`x'/n)*100
		sum flag
		local 2 `r(mean)'
		sum n
		local 1 `r(mean)'
		cii proportions `1' `2'
		gen lci=`r(lb)'*100
		gen uci=`r(ub)'*100
		gen period=`x'
		keep period percent lci uci
		tempfile period`x'_`indication'
		save `period`x'_`indication''
		restore
	}
}
*Figure 3
use `period1_All', clear
gen indication="All"
forvalues x=2/7 {
	append using `period`x'_All'
}
replace indication="All" if indication==""

foreach indication in epilepsy bipolar somatic_cond other_psych_gp {
	forvalues x=1/7 {
		append using `period`x'_`indication''
		replace indication="`indication'" if indication==""
	}
}

gen n=_n
list
drop if indication=="All"
gen ind_num=1 if indication=="epilepsy"
replace ind_num=2 if indication=="bipolar"
replace ind_num=3 if indication=="other_psych_gp"
replace ind_num=4 if indication=="somatic_cond"

cap lab drop period
lab define period 1 "-12 to -9" 2 "-9 to -6" 3 "-6 to -3" 4 "-3 to 0" ///
5 "Trimester 1" 6 "Trimester 2" 7 "Trimester 3" 
lab val period period

*race=indications
*ses=period
graph twoway (bar percent ind_num) (rcap uci lci ind_num), by(period)

generate periodind = ind_num    if period == 1
replace  periodind = ind_num+5  if period == 2
replace  periodind = ind_num+10 if period == 3
replace  periodind = ind_num+15  if period == 4
replace  periodind = ind_num+20 if period == 5
replace  periodind = ind_num+25  if period == 6
replace  periodind = ind_num+30 if period == 7
sort periodind
list periodind period ind_num, sepby(period)

*Add N's - total with each indication in whole cohort 
list 
twoway (bar percent periodind if ind_num==1, color(navy)) ///
       (bar percent periodind if ind_num==2, color(maroon)) ///
       (bar percent periodind if ind_num==3, color(forest_green)) ///
       (bar percent periodind if ind_num==4, color(dkorange)) ///
       (rcap uci lci periodind, lcol(black)), ///
	    ylabel(0(10)40, angle(horizontal)) ytitle("%")  ///
		xlabel(2.5  `" "9-12 months" "pre-pregnancy" "' ///
			   7.5  `" "6-9 months" "pre-pregnancy" "' ///
			   12.5 `" "3-6 months" "pre-pregnancy" "' ///
			   17.5 `" "0-3 months" "pre-pregnancy" "' ///
			   22.5 "Trimester 1"  ///
			   27.5 "Trimester 2"  ///
			   32.5 "Trimester 3" ///		   
			   , labsize(vsmall)) xtitle("") ///
		xscale(range(0 35)) ///
		legend(label(1 "Epilepsy (N=9,570)") label(2 "Bipolar (N=2,028)") label(3 "Other somatic (N=97,830)") label(4 "Other psychiatric (N=261,233)") ///
			  label(5 "95% CI") cols(2) size(vsmall)) ///
		graphregion(color(white))
 graph export "$Graphdir/descriptivepaper/figure3_byasmind.png", width(2000) height(1500) replace


/*reshape wide percent lci uci, i(n) j(indication, string)
drop n
collapse (max) percent* lci* uci*, by(period)


drop percentAll
order period percentepilepsy percentbipolar percentsomatic_cond percentother_psych_gp 





graph twoway  (bar percent* period) (rcap lci* uci* period), over(period, label(labsize(vsmall))) ///
 ylabel(0(5)50, angle(horizontal)) ytitle("%") ///
 legend(label(1 "Epilepsy") label(2 "Bipolar") label(3 "Other somatic") ///
label(4 "Other psychiatric") cols(4) size(vsmall)) saving( "$Graphdir/descriptivepaper/figure3_byasmind.gph",  replace)
 graph export "$Graphdir/descriptivepaper/figure3_all.jpg", width(4000) replace*/


*********************************************************************************
*Figure S1
*********************************************************************************

foreach indication in All {
cd "$Projectdir"
use "$Datadir\Derived_data\Combined_datasets\Descriptives_paper\dataset_descriptives_paper.dta", clear
count /*total pregs*/
gen n=1

gen pregyear=year(pregstart_num)
tab flag_anydrug_prd1 pregyear, col chi

gen All=1

if "`indication'"=="All" {
}
if "`indication'"!="All" {
keep if `indication'==1
}	

*Keep necessary variables
keep flag_* pregyear polytherapy_firsttrim dosage_tri_1 n 
gen flag_other_new_preg=1 if flag_other_prd5==1 | flag_other_prd6==1 ///
| flag_other_prd7==1 | flag_topiramate_prd5==1 | flag_topiramate_prd6==1 ///
| flag_topiramate_prd7==1 | flag_phenytoin_prd5==1 | flag_phenytoin_prd6==1 ///
| flag_phenytoin_prd7==1

*Overall polytherapy 
preserve
keep if flag_anydrug_prd5==1 /*1st trimester exposure*/
recode polytherapy 0=.
collapse (count) polytherapy (count) n
gen percent_poly=(polytherapy/n)*100
keep  percent* n 
list
restore

*Most common polytherapy combinations
preserve
keep if flag_anydrug_prd5==1 /*1st trimester exposure*/
keep if polytherapy==1
keep flag_*_prd5
contract flag_*_prd5, freq(freq)
sort freq
list
restore

**Table for Figure S1: The proportion of pregnancies which used ASM polytherapy and high dose ASMs, over time, among pregnancies with first trimester exposure
*Dose needs to be worked on
preserve
keep if flag_anydrug_prd5==1 /*1st trimester exposure*/
gen high_dose=1 if dosage_tri_1==3
count
recode polytherapy 0=.
collapse (count) polytherapy (count) high_dose (count) n, by(pregyear)
gen percent_poly=(polytherapy/n)*100
gen percent_high_dose=(high_dose/n)*100
keep pregyear percent* n polytherapy
tempfile poly_dose
save `poly_dose'
restore

 *Figure S1
use `poly_dose', clear
	graph bar percent_poly percent_high_dose, over(pregyear, label(labsize(small) angle(45))) ///
	ylabel(0(10)100, angle(horizontal))  ///
	ytitle("%") ///
	legend(label(1 "Polytherapy") label(2 "High dose exposure") cols(2)) ///
	graphregion(color(white)) ///
	saving( "$Graphdir/descriptivepaper/figures1_asmind`indication'.gph",  replace) 
 graph export "$Graphdir/descriptivepaper/figureS1_all.tif", width(1000) replace
}


*********************************************************************************
*Figure 2
*********************************************************************************

set scheme s1color
foreach indication in All  bipolar somatic_cond other_psych_gp epilepsy {
	cd "$Projectdir"
	use "$Datadir\Derived_data\Combined_datasets\Descriptives_paper\dataset_descriptives_paper.dta", clear
	count /*total pregs*/
	gen n=1

	gen pregyear=year(pregstart_num)
	tab flag_anydrug_prd1 pregyear, col chi

	gen All=1

	if "`indication'"=="All" {
	}
	if "`indication'"!="All" {
	keep if `indication'==1
	}	

	*Keep necessary variables
	keep flag_* pregyear  n 
	gen flag_other_new_preg=1 if flag_other_prd5==1 | flag_other_prd6==1 ///
	| flag_other_prd7==1 | flag_topiramate_prd5==1 | flag_topiramate_prd6==1 ///
	| flag_topiramate_prd7==1 | flag_phenytoin_prd5==1 | flag_phenytoin_prd6==1 ///
	| flag_phenytoin_prd7==1

	*Table for Fig2: proportion of women prescribed each ASM drug class anytime during pregnancy during the study period, overall and by indication
	*foreach drug in lamotrigine valproate carbamazepine pregabalin levetiracetam gabapentin *phenytoin levetiracetam topiramate other {
	foreach drug in lamotrigine valproate carbamazepine pregabalin levetiracetam gabapentin levetiracetam topiramate  phenytoin other {
		preserve
		recode flag_`drug'_preg 0=.
		collapse (count) flag_`drug'_preg (count) n, by(pregyear)
		gen percent_`drug'=(flag_`drug'_preg/n)*100
		keep pregyear percent n 
		tempfile ASM_`drug'
		save `ASM_`drug''
		restore
	}


*Figure 2
	use `ASM_lamotrigine', clear
	foreach drug in lamotrigine valproate carbamazepine pregabalin levetiracetam gabapentin  topiramate phenytoin other {
		merge 1:1  pregyear using `ASM_`drug'', nogen
	}
	list 
	gen `indication'=1
	cap lab var All All
	cap lab var epilepsy Epilepsy
	cap lab var bipolar Bipolar
	cap lab var somatic_cond "Other somatic conditions"
	cap lab var other_psych_gp "Other psychiatric conditions"
	local label: variable label `indication'

	if "`indication'" == "All" | "`indication'" == "other_psych_gp" {
		local yrange = "0(0.2)1"
	}
	else if "`indication'" ==  "bipolar" |  "`indication'" ==  "epilepsy" {		
		local yrange = "0(5)30"
	}
	else if "`indication'" ==  "somatic_cond"  {		
		local yrange = "0(0.5)2"
	}
	
		graph twoway line percent* pregyear, lpattern(dash solid dot ///
			 dash_dot shortdash      shortdash_dot   longdash longdash_dot ) ///
			ylabel(`yrange', angle(horizontal) labsize(small)) ///
			xlabel(, labsize(small)) ///
			xtitle("Year of pregnancy", size(small)) ///
			ytitle("%") ///
			title("`label'", size(small)) ///
			legend(label(1 "Lamotrigine") label(2 "Valproate") label(3 "Carbamazepine") ///
			label(4 "Pregabalin") label(5 "Levetiracetam") label(6 "Gabapentin")  ///
			label(7 "Topiramate") label(8 "Phenytoin") label(9 "Other")  ///
			 cols(2) size(*.5)) ///
			name(fig_`indication', replace)
}

grc1leg fig_All fig_epilepsy fig_bipolar fig_other_psych_gp fig_somatic_cond, cols(2) ring(0) position(4)
graph export "$Graphdir/descriptivepaper/figure2_asmind.tif", width(2000) height(1500) replace
graph export "$Graphdir/descriptivepaper/figure2_asmind.png", width(2000) height(1500) replace
graph export "$Graphdir/descriptivepaper/figure2_asmind.svg", width(2000) height(1500) replace
graph export "$Graphdir/descriptivepaper/figure2_asmind.pdf", replace


  



