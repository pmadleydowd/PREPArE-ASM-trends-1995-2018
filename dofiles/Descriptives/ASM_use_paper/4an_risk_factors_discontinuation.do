

********************************************************************************
*Logistic regression analysis
********************************************************************************
/*Logistic regression analysis was used to investigate factors that were 
independently associated with ASM early and then late discontinuation during 
pregnancy. This analysis was restricted to women with a completed pregnancy.  

We accounted for women contributing several pregnancies by [GEE]. 

We compared women who discontinued at any time during their pregnancy 
with women who continued or switched medications. As discontinuation patterns 
may vary by GP practice, we included general practice in all models as a 
random effect to account for clustering. 

There were missing data for ASM indication, ASM dose, BMI, smoking and alcohol use.  
As these data are likely to be missing not at random (i.e. missingness depends 
on the value itself; for example those of normal weight are less likely to 
have their BMI recorded) we conducted a complete case analysis.
*/
use "$Datadir\Derived_data\Combined_datasets\Descriptives_paper\dataset_descriptives_paper.dta", clear
keep if flag_anydrug_preg==1 | flag_anydrug_prepreg==1
tab use
foreach ind in epilepsy bipolar somatic_cond other_psych_gp {
   recode `ind' .=0
}

recode smokstatus 3=.
recode bmi_cat 4=.
recode eth5 5=.


*Comparing women who discontinued at at time during pregnancy with those who continued or switched

gen outcome1_discont=1 if use==2 | use==3 /*early and late discontinuers*/
replace outcome1_discont=0 if use==1 /*continuers*/
 keep if outcome1!=.


*drop aed_class_gp

gen aed_class_gp=.
replace aed_class_gp=1 if flag_lamotrigine_prepreg==1
replace aed_class_gp=2 if flag_valproate_prepreg==1 & aed_class_gp==.
replace aed_class_gp=3 if flag_carbamazepine_prepreg==1  & aed_class_gp==.
replace aed_class_gp=4 if flag_pregabalin_prepreg==1  & aed_class_gp==.
replace aed_class_gp=5 if flag_levetiracetam_prepreg==1  & aed_class_gp==.
replace aed_class_gp=6 if flag_gabapentin_prepreg==1  & aed_class_gp==.
replace aed_class_gp=7 if flag_topiramate_prepreg==1  & aed_class_gp==.
replace aed_class_gp=8 if flag_phenytoin_prepreg==1  & aed_class_gp==.
replace aed_class_gp=9 if flag_other_prepreg==1  & aed_class_gp==.


lab define aed_class_gp 1 "Lamotrigine" 2 "Valproate" 3 "Carbamazepine" ///
4 "Pregabalin" 5 "Levetiracetam" 6 "Gabapentin" 7 "Topiramate" 8 "Phenytoin" 9 "Other"
lab val aed_class_gp aed_class_gp


misstable sum 	 matage_cat  epilepsy bipolar  somatic_cond  other_psych_gp ///
eth5  imd5   smokstatus   bmi_cat  hazardous_drinking   illicit  ///
CPRD_consultation_events_cat   seizure_events_CPRD_HES_cat   ///
antipsychotics_365_prepreg   antidepressants_365_prepreg 	///
 aed_class_gp  	 dosage_pre_preg , gen(miss) 
 
foreach var in eth5 smokstatus bmi_cat {
 bysort matage_cat:  tab outcome1_discont miss`var', col chi
} 

stop 
/* Covariates not incorporated
-illicit drug use (definition TBC), 
-number of hospitalizations in the year before pregnancy (linked data only)
-ASM duration of prescribing (<6 months, 6-12 months, 1-5 years and over 5 years), 
*/
********************************************************************************
* 3 - Create descriptive statistics using table1_mc package 
********************************************************************************
table1_mc,  by(outcome1_discont) ///
			vars( /// 
				 matage_cat cat %5.1f \ ///
				 epilepsy cat %5.1f \ ////
				 bipolar cat %5.1f \ ////
				 somatic_cond cat %5.1f \ ////
				 other_psych_gp cat %5.1f \ ////
				 eth5 cat %5.1f \ ///
				 imd5 cat %5.1f \ ///
				 smokstatus cat %5.1f \ ///
				 bmi_cat cat %5.1f \ ///
				 hazardous_drinking cat %5.1f \ ///
				 illicit cat %5.1f \ ///
				 parity_cat cat %5.1f \ ///
				 CPRD_consultation_events_cat cat %5.1f \ ///
				 seizure_events_CPRD_HES_cat cat %5.1f \ ///
				 antipsychotics_365_prepreg cat %5.1f \ ///
				 antidepressants_365_prepreg cat %5.1f \ ///
				 aed_class_gp cat %5.1f \ ///
				 dosage_pre_preg cat %5.1f \ ///
				) ///
			nospace onecol missing total(before) ///
			saving("$Datadir\Descriptive_statistics\ASM_use_paper\Table2_ASM_use_paper.xlsx", replace)

rename CPRD_consultation_events_cat cons_cat

*Issue with GEE model: estimates diverging. As such used cluster option
*xtset patid // tells the data the grouping structure 
*xtgee outcome1_discont i.matage_cat, family(binomial) link(logit) corr(exchangeable) 

*file write code to generate ORs and write to text file
tempname myhandle	
file open `myhandle' using "$Datadir\Descriptive_statistics\ASM_use_paper\Table2_ASM_use_paper_ORs.txt", write replace
file write `myhandle' _n "Table 2" _tab _n
*Univariate
foreach var in matage_cat epilepsy bipolar somatic_cond other_psych_gp eth5  imd5  smokstatus bmi_cat hazardous_drinking illicit parity_cat cons_cat seizure_events_CPRD_HES_cat antipsychotics_365_prepreg antidepressants_365_prepreg aed_class_gp dosage_pre_preg {
di "`var'"
levelsof `var',  local(`var'levs) sep(	)
foreach level in `r(levels)' {
    di "****** `var' = `level'"
file write `myhandle' "`var'" _tab 
file write `myhandle' "`var'==`level'" _tab
*Unadjusted
logistic outcome1_discont i.`var', cluster(patid)     
lincom _b[`level'.`var'], rrr
local minadjhr=`r(estimate)'
local minadjuci=`r(ub)'
local minadjlci=`r(lb)'

*Age-adjusted: With cluster–robust standard errors for clustering by levels of cvar
logistic outcome1_discont i.`var' ib3.matage_cat,  vce(cluster patid) 
lincom _b[`level'.`var'], rrr 
local adjhr=`r(estimate)'
local adjuci=`r(ub)'
local adjlci=`r(lb)'

file write `myhandle'  %4.2f  (`minadjhr') " (" %4.2f (`minadjlci')  "-" %4.2f (`minadjuci') ")" _tab
file write `myhandle'  %4.2f  (`adjhr') " (" %4.2f (`adjlci')  "-" %4.2f (`adjuci') ")" _tab _n
}
**#
file write `myhandle' _n 
}
di as txt `"(Results are in {browse "$Datadir\Descriptive_statistics\ASM_use_paper\Table2_ASM_use_paper_ORs_ASM_use_paper.txt"})"'	


foreach var in eth5 imd5  {
    tab `var'
}

