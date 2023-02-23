*********************************************************************************
*1.PREPARE DATASET: merge on necessary data and select eligible pregnancies
*********************************************************************************

use "$Datadir\Derived_data\Cohorts\pregnancy_cohort_final", clear

codebook pregid
count


*updated outcome
drop outcome
rename updated_outcome outcome
codebook pregid

merge 1:1 patid pregid using "$Datadir\Derived_data\Exposure\pregnancy_cohort_exposure.dta",  keep(match master) nogen
codebook pregid

* merge on covariate information
merge 1:1 patid pregid using "$Datadir\Derived_data\covariates\pregnancy_cohort_covariates.dta",  keep(match master) nogen

*merge on indication information
merge 1:1 patid pregid using "$Datadir\Derived_data\Indications\ASM_indications_pre_preg_final.dta", nogen keep(match master)

*merge on tod, lcd, deathdate_num
merge m:1 patid  using "$Rawdatdir/stata\data_gold_2021_08\collated_files\All_Patient_Files", nogen keep(match) keepusing(tod_num crd_num)
tostring patid, gen(patid_s) format(%12.0f)
gen pracid = substr(patid_s,-5,5)
destring pracid, replace
merge m:1 pracid using "$Rawdatdir/stata\data_gold_2021_08\collated_files\All_Practice_Files", nogen keep(match) keepusing(lcd_num uts_num)
codebook pregid

count

drop if outcome==13

*Restrict to completed pregnancies
keep if outcome==1 | outcome==2 | outcome==3 | outcome==11 | outcome==12
lab var epilepsy Epilepsy
lab var bipolar Bipolar
lab var somatic_cond "Other somatic conditions"
lab var other_psych_gp "Other psychiatric conditions"


save "$Datadir\Derived_data\Combined_datasets\Descriptives_paper\dataset_descriptives_paper.dta", replace