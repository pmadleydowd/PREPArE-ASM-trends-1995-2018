
/* - done as part of cr_select_elligible pregnancies
*CReate inidividual datasets with unique patient IDS.  If a woman has several pregnancies, we need to calculate her covariate at each pregnancy start. 

use "$Datadir\Derived_data\CPRD\pregnancy_cohort_matids_pregids.dta", clear

merge 1:1 patid pregid using "$Projectdir\rawdatafiles\stata\data_linked\20_000228_pregnancy_register.dta", keep(match) nogen

merge m:1 patid using "$Projectdir\rawdatafiles\stata\data_linked\linkage_eligibility_gold21", keep(match master) keepusing(hes_e) nogen

gen linkage_hes=1 if hes_e==1
recode linkage_hes .=0

lab define outcome 1 "Live birth" 2 "Stillbirth" 3 "Live birth or still birth" ///
4 "Miscarriage" 5 "TOP" 6 "MIscarraige or TOP" 7"Ectopic" 8 "Molar" 9 "Blighted ovum" 10 "Unspecified loss" 11 "Delivery based on a third trimester pregnancy record" 12 "Delivery based on a late pregnancy record4"  13 "Outcome unknown"
lab val outcome outcome

save "$Datadir\Derived_data\CPRD\pregnancy_cohort_final", replace


*Create datasets containing unique patids combinations
*(occurs because there can be multiple pregnancies for one mum)
bysort patid: gen bign=_N /*unique patids*/
tab bign /*max 17 pregnancies*/
sort patid pregstart
drop big

forvalues x=1/17 {
use "$Datadir\Derived_data\CPRD\pregnancy_cohort_final", clear
bysort patid (pregid): keep if _n==`x' /*unique patids*/
save "$Datadir\Derived_data\CPRD/pregnancy_cohort_final_`x'", replace
}
*/

/*Reduce size of clinical, therapy and additional datasets*/
use "$Rawdatdir/stata\data_gold_2021_08\collated_files\All_Clinical_Files", clear
keep patid eventdate_num medcode adid
save "$Rawdatdir/stata\data_gold_2021_08\collated_files\All_Clinical_Files_reduced", replace
sample 10
save "$Rawdatdir/stata\data_gold_2021_08\collated_files\All_Clinical_Files_reduced_10percent_sample", replace

use "$Rawdatdir/stata\data_gold_2021_08\collated_files\All_Therapy_Files", clear
keep patid eventdate_num prodcode
save "$Rawdatdir/stata\data_gold_2021_08\collated_files\All_Therapy_Files_reduced", replace
sample 10
save "$Rawdatdir/stata\data_gold_2021_08\collated_files\All_Therapy_Files_reduced_10percent_sample", replace

use "$Rawdatdir/stata\data_gold_2021_08\collated_files\All_Additional_Files", clear
sample 10
save "$Rawdatdir/stata\data_gold_2021_08\collated_files\All_Additional_Files_reduced_10percent_sample", replace
