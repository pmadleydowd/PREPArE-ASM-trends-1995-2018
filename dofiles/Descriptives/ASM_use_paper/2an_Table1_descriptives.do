cap log close
log using "$Logdir\LOG_an_Table1_ASM_use_paper.txt", text replace
********************************************************************************
* do file author:	H Forbes
* Date: 			18 January 2022
* Description: 		Creation of Table 1 descriptive statistics for ASM use paper
* Notes:			
********************************************************************************
* Notes on major updates (Date - description):
********************************************************************************

********************************************************************************
* Install required packages
********************************************************************************
*ssc install table1_mc

********************************************************************************
* Contents
********************************************************************************
* 1 - Prepare formats for data for output
* 2 - Create descriptive statistics using table1_mc package 
* 3 - Characteristics over time
* 4 - Characteristics over time among ASM users 


********************************************************************************
* load cohort
use "$Datadir\Derived_data\Combined_datasets\Descriptives_paper\dataset_descriptives_paper.dta", clear

********************************************************************************
* 1 - Prepare formats for data for output
********************************************************************************

*tidy indication variable
gen no_ind=1 if epilepsy==. & bipolar==. & other_psych_gp==. & somatic_cond==. 
foreach var in no_ind epilepsy bipolar other_psych_gp somatic_cond {
	recode `var' .=0
}


********************************************************************************
* 2 - Create descriptive statistics using table1_mc package 
********************************************************************************
table1_mc,  by(flag_anydrug_preg) ///
			vars( /// 
				 matage_cat cat %5.1f \ ///
				 eth5 cat %5.1f \ ///
				 epilepsy cat %5.1f \ ///
				 bipolar cat %5.1f \ ///
				 somatic_cond cat %5.1f \ ///
				 other_psych_gp cat %5.1f \ ///
				 no_ind cat %5.1f \ ///
				 imd5 cat %5.1f \ ///
				 smokstatus cat %5.1f \ ///
				 bmi_cat cat %5.1f \ ///
				 hazardous_drinking cat %5.1f \ ///
				 illicit cat %5.1f \ ///
				 parity_cat cat %5.1f \ ///
				 CPRD_consultation_events_cat cat %5.1f \ ///
				 antipsychotics_365_prepreg cat %5.1f \ ///
				 antidepressants_365_prepreg cat %5.1f \ ///
				) ///
			nospace onecol missing total(before) ///
			saving("$Datadir\Descriptive_statistics\ASM_use_paper\Table1_ASM_use_paper.xlsx", replace)
				 
********************************************************************************
* 3 - Characteristics over time
********************************************************************************
table1_mc,  by(pregstart_year_cat) ///
			vars( /// 
				 matage_cat cat %5.1f \ ///
				 eth5 cat %5.1f \ ///
				 epilepsy cat %5.1f \ ///
				 bipolar cat %5.1f \ ///
				 somatic_cond cat %5.1f \ ///
				 other_psych_gp cat %5.1f \ ///
				 no_ind cat %5.1f \ ///
				 imd5 cat %5.1f \ ///
				 smokstatus cat %5.1f \ ///
				 bmi_cat cat %5.1f \ ///
				 hazardous_drinking cat %5.1f \ ///
				 illicit cat %5.1f \ ///
				 parity_cat cat %5.1f \ ///
				 CPRD_consultation_events_cat cat %5.1f \ ///
				 antipsychotics_365_prepreg cat %5.1f \ ///
				 antidepressants_365_prepreg cat %5.1f \ ///
				) ///
			nospace onecol missing total(before) ///
			saving("$Datadir\Descriptive_statistics\ASM_use_paper\SUPP_desc_characteristics_over_time.xlsx", replace)


********************************************************************************
* 4 - Characteristics over time among ASM users 
********************************************************************************
keep if flag_anydrug_preg==1 | flag_anydrug_prepreg==1 // use in year before or during pregnancy

table1_mc,  by(pregstart_year_cat) ///
			vars( /// 
				 matage_cat cat %5.1f \ ///
				 eth5 cat %5.1f \ ///
				 epilepsy cat %5.1f \ ///
				 bipolar cat %5.1f \ ///
				 somatic_cond cat %5.1f \ ///
				 other_psych_gp cat %5.1f \ ///
				 no_ind cat %5.1f \ ///
				 imd5 cat %5.1f \ ///
				 smokstatus cat %5.1f \ ///
				 bmi_cat cat %5.1f \ ///
				 hazardous_drinking cat %5.1f \ ///
				 illicit cat %5.1f \ ///
				 parity_cat cat %5.1f \ ///
				 CPRD_consultation_events_cat cat %5.1f \ ///
				 antipsychotics_365_prepreg cat %5.1f \ ///
				 antidepressants_365_prepreg cat %5.1f \ ///
				) ///
			nospace onecol missing total(before) ///
			saving("$Datadir\Descriptive_statistics\ASM_use_paper\SUPP_desc_characteristics_over_time_ASM_user.xlsx", replace)			 
				 


********************************************************************************
log close