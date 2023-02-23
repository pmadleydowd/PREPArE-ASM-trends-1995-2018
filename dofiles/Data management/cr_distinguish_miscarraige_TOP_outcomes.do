*AIM: To identify loss type where outcome in PR is Probable TOP
*AUTHOR: Harriet Forbes
 
 
 
 
********************************************************************************
*****************************3.0 pregnancy losses*******************************
********************************************************************************

********************************************************************************
*3.1 HES APC
********************************************************************************
*HES diagnoses, using all ICD-10 codes for early pregnancy loss across an episode of care. 
use "$Rawdatdir\stata\data_linked\20_000228_hes_diagnosis_epi.dta", replace
merge m:1 icd  using "$Codelsdir\ICD_10_OPCS_loss_codes_with_flag_SA_TOP", keep(match)
rename loss_type outcome
lab define outcome 1 "Live birth" 2 "Stillbirth" 3 "Live birth or still birth" ///
4 "Miscarriage" 5 "TOP" 6 "Probable TOP" 7"Ectopic" 8 "Molar" 9 "Blighted ovum" 10 "Unspecified loss" 11 "Delivery based on a third trimester pregnancy record" 12 "Delivery based on a late pregnancy record4"  13 "Outcome unknown"
lab val outcome outcome
tab outcome

*The start date of the episode of care (epistart) was used to date the pregnancy loss.
gen loss_date_hes_apc=epistart_num
keep patid epikey loss_date_hes_apc outcome
duplicates drop
duplicates report patid epikey 

*Deal with conflicting loss codes in same pregnancy episode
gen loss_rank=1 if outcome==7 /*ectopic*/
replace loss_rank=2 if outcome==5 /*TOP*/
replace loss_rank=3 if outcome==4 /*Miscarriage*/
replace loss_rank=4 if outcome==6 /*Probable TOP*/
replace loss_rank=5 if outcome==8 /*Molar*/
replace loss_rank=6 if outcome==10  /*Unspec*/
replace loss_rank=7 if outcome==9 /*blighted ovum*/
bysort patid epikey (loss_rank): gen loss_rank_highest=outcome if _n==1
bysort patid epikey: egen loss_rank_highest_max=max(loss_rank_highest)
replace outcome=loss_rank_highest_max

keep patid epikey loss_date_hes_apc outcome
duplicates drop
duplicates report patid epikey

bysort patid epikey (loss_date_hes_apc): keep if _n==1

duplicates report patid epikey

save "$Datadir\Derived_data\HES\hes_icd_losses", replace


********************************************************************************
*3.3 OPCS
********************************************************************************
*	the HES procedures file, using OPCS codes for early pregnancy loss procedures (category 3, S5-Table). As for deliveries, the date of the procedure (evdate) was used (when not missing), otherwise epistart was used. 
use "$Rawdatdir\stata\data_linked\20_000228_hes_procedures.dta", clear
merge m:1 opcs using "$Codelsdir\OPCS_loss_codes_CMIN_with_categories.dta", ///
keep(match) nogen
gen hes=2
gen loss_date_hes_opcs=evdate_num
replace loss_date_hes_opcs=epistart_num if loss_date_hes_opcs==.
keep patid epikey loss_date_hes_opcs outcome
duplicates drop
duplicates report patid epikey

*Deal with conflicting loss codes in same pregnancy episode
gen loss_rank=1 if outcome==7 /*ectopic*/
replace loss_rank=2 if outcome==5 /*TOP*/
replace loss_rank=3 if outcome==4 /*Miscarriage*/
replace loss_rank=4 if outcome==6 /*Probable TOP*/
replace loss_rank=5 if outcome==8 /*Molar*/
replace loss_rank=6 if outcome==10  /*Unspec*/
replace loss_rank=7 if outcome==9 /*blighted ovum*/
bysort patid epikey (loss_rank): gen loss_rank_highest=outcome if _n==1
bysort patid epikey: egen loss_rank_highest_max=max(loss_rank_highest)
replace outcome=loss_rank_highest_max

keep patid epikey loss_date_hes_opcs outcome
duplicates drop
duplicates report patid epikey

bysort patid epikey (loss_date_hes_opcs): keep if _n==1

duplicates report patid epikey
save "$Datadir\Derived_data\HES\hes_opcs_losses", replace

******************************************************************************** 
*2.4 Extract losses data from HES OUTPATIENT
********************************************************************************
*Diagnoses
foreach x in 01 02 03 04 05 06 07 08 09 10 11 12 {
use "$Rawdatdir\stata\data_linked\20_000228_hesop_clinical.dta", clear
drop if diag_01=="R69X6"
rename diag_`x' code
keep patid attendkey code 
gen code_new=code
replace code_new=substr(code_new,1,3)+"."+substr(code_new,4,3)
drop code
rename code_new icd
merge m:1 icd using "$Codelsdir\ICD_10_OPCS_loss_codes_with_flag_SA_TOP.dta", keep(match)
count
rename loss_type outcome
if `r(N)'!=0 {
merge 1:1 patid attendkey using "$Rawdatdir\stata\data_linked\20_000228_hesop_appointment.dta", keep(3) nogen
keep if inlist(attended, 5, 6) // keep only appointments where the patient was seen 
gen del_date_hesop=apptdate_num
format del_date_hesop %td
keep patid attendkey icd del_date outcome
gen hes=4
save "$Datadir\Derived_data\HES\_temp\dxhesop_`x'", replace
}
}

*Operations
foreach x in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24  {
use "$Rawdatdir\stata\data_linked\20_000228_hesop_clinical.dta", clear
drop if diag_01=="R69X6"
rename opertn_`x' opcs
keep patid attendkey opcs 
merge m:1 opcs using "$Codelsdir\OPCS_loss_codes_CMIN_with_categories", ///
keep(match) nogen
count
if `r(N)'!=0 {
merge 1:1 patid attendkey using "$Rawdatdir\stata\data_linked\20_000228_hesop_appointment.dta", keep(3) nogen
keep if inlist(attended, 5, 6) // keep only appointments where the patient was seen 
gen del_date_hesop=apptdate_num
format del_date_hesop %td
keep patid attendkey opcs del_date outcome
gen hes=4
save "$Datadir\Derived_data\HES\_temp\opertnhesop_`x'", replace
}
}

*Combine
use "$Datadir\Derived_data\HES\_temp\dxhesop_01", clear
append using "$Datadir\Derived_data\HES\_temp\opertnhesop_01"
foreach x in  02 03 04 05 06 07 08 09 10 11 12 {
	di `x'
cap	append using "$Datadir\Derived_data\HES\_temp\dxhesop_`x'"
cap	append using "$Datadir\Derived_data\HES\_temp\opertnhesop_`x'"
}
foreach x in  13 14 15 16 17 18 19 20 21 22 23 24  {
cap	append using "$Datadir\Derived_data\HES\_temp\opertnhesop_`x'"
}

keep patid del_date_hesop attendkey outcome
duplicates drop
duplicates report patid attendkey

*Deal with conflicting loss codes in same pregnancy episode
gen loss_rank=1 if outcome==7 /*ectopic*/
replace loss_rank=2 if outcome==5 /*TOP*/
replace loss_rank=3 if outcome==4 /*Miscarriage*/
replace loss_rank=4 if outcome==6 /*Probable TOP*/
replace loss_rank=5 if outcome==8 /*Molar*/
replace loss_rank=6 if outcome==10  /*Unspec*/
replace loss_rank=7 if outcome==9 /*blighted ovum*/
bysort patid attendkey (loss_rank): gen loss_rank_highest=outcome if _n==1
bysort patid attendkey: egen loss_rank_highest_max=max(loss_rank_highest)
replace outcome=loss_rank_highest_max

drop loss_rank*

save "$Datadir\Derived_data\HES\_temp\hesop_outcomes_loss", replace

erase  "$Datadir\Derived_data\HES\_temp\dxhesop_01.dta"
erase "$Datadir\Derived_data\HES\_temp\opertnhesop_01.dta"
foreach x in  02 03 04 05 06 07 08 09 10 11 12 {
cap erase "$Datadir\Derived_data\HES\_temp\dxhesop_`x'.dta"
cap erase "$Datadir\Derived_data\HES\_temp\opertnhesop_`x'.dta"
}

foreach x in  13 14 15 16 17 18 19 20 21 22 23 24  {
cap erase "$Datadir\Derived_data\HES\_temp\opertnhesop_`x'.dta"
}

 
********************************************************************************
*3.4 COMBINE LOSS DATA FROM  OPCS, and DIAG  and merge with cohort
********************************************************************************

use "$Datadir\Derived_data\HES\hes_icd_losses", clear
merge 1:1 patid epikey using "$Datadir\Derived_data\HES\hes_opcs_losses", nogen

append using "$Datadir\Derived_data\HES\_temp\hesop_outcomes_loss"

*Deal with conflicting loss codes in same pregnancy episode
gen loss_rank=1 if outcome==7 /*ectopic*/
replace loss_rank=2 if outcome==5 /*TOP*/
replace loss_rank=3 if outcome==4 /*Miscarriage*/
replace loss_rank=4 if outcome==6 /*Probable TOP*/
replace loss_rank=5 if outcome==8 /*Molar*/
replace loss_rank=6 if outcome==10  /*Unspec*/
replace loss_rank=7 if outcome==9 /*blighted ovum*/
bysort patid epikey (loss_rank): gen loss_rank_highest=outcome if _n==1
bysort patid epikey: egen loss_rank_highest_max=max(loss_rank_highest)
replace outcome=loss_rank_highest_max

drop loss_rank*

*Generate an estimated delivery date for each retained record: taking the earliest of the potential delivery dates (based on antedur or postdur) and procedure dates. For records with no potential delivery dates or procedures, epistart was used.
gen loss_date=.
replace loss_date=min(loss_date_hes_opcs, loss_date_hes_apc)
 drop if loss_date==.
 format loss_date %td
 keep patid epikey loss_date outcome

 tab outcome
 
*Create delivery episodes:grouping together records relating to the same delivery (records with an estimated delivery date <8 weeks  (56 days) after the initial record were deemed to relate to the same delivery)
gen toassign = -1
gen group = 0
local g = 1
qui count if toassign

qui while r(N) > 0 {
    bysort patid (toassign loss_date) : replace group = `g' if (loss_date - loss_date[1]) <= 56 & toassign
      replace toassign = 0 if group == `g'
      local ++g
      count if toassign
}

*Deal with conflicting loss codes in same pregnancy episode
gen loss_rank=1 if outcome==7 /*ectopic*/
replace loss_rank=2 if outcome==5 /*TOP*/
replace loss_rank=3 if outcome==4 /*Miscarriage*/
replace loss_rank=4 if outcome==6 /*Probable TOP*/
replace loss_rank=5 if outcome==8 /*Molar*/
replace loss_rank=6 if outcome==10  /*Unspec*/
replace loss_rank=7 if outcome==9 /*blighted ovum*/
bysort patid group (loss_rank): gen loss_rank_highest=outcome if _n==1
bysort patid group: egen loss_rank_highest_max=max(loss_rank_highest)
replace outcome=loss_rank_highest_max

*Keep first first in delivery episode
bysort patid group (loss_date): keep if _n==1 

save "$Datadir\Derived_data\HES\hes_losses_all", replace

**************ADD in pregnancy cohort: keep losses with 140 days of preg start
forvalues x=1/17 {
use "$Datadir\Derived_data\CPRD\_temp\pregreg_hesoutcomesstep_extra_vars_`x'", clear
keep if outcome==6 | outcome==10 /* probable TOP and unspecified losses*/
keep if linkage_hes==1
drop outcome
merge 1:m patid using "$Datadir\Derived_data\HES\hes_losses_all", keep(match)
gen diff=loss_date-(pregstart_num+28)
sum diff, d
if `r(N)'!=0 {
keep if diff>=0 & diff<=140
tempfile episodes_all_`x'
save `episodes_all_`x'' 
}
}

use `episodes_all_1', clear
forvalues x=2/16 {
	di `x'
append using `episodes_all_`x''
}

drop loss_rank*
*Deal with conflicting loss codes in same pregnancy episode
gen loss_rank=1 if outcome==7 /*ectopic*/
replace loss_rank=2 if outcome==5 /*TOP*/
replace loss_rank=3 if outcome==4 /*Miscarriage*/
replace loss_rank=4 if outcome==6 /*Probable TOP*/
replace loss_rank=5 if outcome==8 /*Molar*/
replace loss_rank=6 if outcome==10  /*Unspec*/
replace loss_rank=7 if outcome==9 /*blighted ovum*/
bysort patid group (loss_rank): gen loss_rank_highest=outcome if _n==1
bysort patid group: egen loss_rank_highest_max=max(loss_rank_highest)
replace outcome=loss_rank_highest_max

*Keep first loss record in episode
bysort patid pregid (loss_date): keep if _n==1 
codebook pregid /*8,920*/

*Recalculate pregnancy start dates
*9 wks for ectopic and 12 wks for other losses
replace pregstart_num=loss_date-63 if outcome==7
replace pregstart_num=loss_date-84 if outcome!=7

drop pregend*
gen pregend_num=loss_date

keep patid pregid pregstart_num pregend_num outcome 
save "$Datadir\Derived_data\Outcomes\Maternal_outcomes\hes_losses_outcome_6_10_final", replace


*erase interim datasets
erase "$Datadir\Derived_data\HES\hes_losses_all.dta"
erase "$Datadir\Derived_data\HES\hes_opcs_losses.dta"
erase "$Datadir\Derived_data\HES\hes_icd_losses.dta"


/******Gestational age info
use "$Datadir\Derived_data\CPRD\_temp\pregreg_hesoutcomesstep_extra_vars", clear
merge 1:1 patid pregid using "$Rawdatdir\stata\data_linked\20_000228_pregnancy_register.dta", keep(match) nogen
sum *adj*
*No information of source of start date or gestational age