***MOD data: must be run after outcome unknowns have had HES data supplemented
***AUTHOR: Harriet Forbes

/*Datasets created:

1)Identifies a single mod code from each individual dB where available, and
flags any patients with conflicting codes for dropping in do file 11. 

HES:
multiple_mod_data_opcs mod_data_opcs
multiple_mod_data_hesmt mod_data_hes_maternity
multiple_mod_data_icd mod_data_icd

CPRD data:
multiple_mod_data_read mod_data_read
mod_data_enttype

2)Combine MOD from different dBs into one variable:
MOD_final

*/
********************************************************************************
*********************************MOD CODES**************************************
********************************************************************************
*Extract all codes
use "$Rawdatdir\stata\data_linked\20_000228_hes_diagnosis_epi.dta", clear
rename icd code
merge m:1 code using "$Codelsdir\icd_mod_draft_hf", ///
keep(match) nogen
save "$Datadir\Derived_data\HES\icd_mod_data_all", replace


use  "$Rawdatdir\stata\data_linked\20_000228_hes_procedures.dta", clear
rename opcs opcscode
merge m:1 opcscode using "$Codelsdir\opcs_mod_draft_hf", ///
keep(match) nogen
save "$Datadir\Derived_data\HES\opcs_mod_data_all", replace

********************************************************************************
*HES procedures file
********************************************************************************

*Loops through with completed pregnancies and merges with OPCS data
forvalues x=1/17 {
use "$Datadir\Derived_data\CPRD\pregnancy_cohort_final_`x'", clear
keep if outcome==1 | outcome==2 /*completed pregnancies*/
merge 1:m patid using "$Datadir\Derived_data\HES/opcs_mod_data_all", keep(match master) 
tempfile preg`x'
save `preg`x''
}

use `preg1'
forvalues x=2/19 {
append using `preg`x''
}

*Patients with ZERO OPCS codes
codebook pregid if _m==1 & linked==1
*N=XXX pregnancies have ZERO Opcs code

*Save OPCS codes occuring within 60 days either side of preg.register pregend
gen diff=abs(evdate-pregend)
sum diff, d
gen eligiblecode=1 if diff<60
/*Vary days: 
10: 1611  (27%)
30: 1173 (20%)
60: 1036 (17%)
90: 994 (17%)
180: 908 (15%)
*/

*Explore those with no eligible codes
bysort pregid: egen anyeligible=max(eligiblecode)
tab anyeligible, miss
tab year anyeligible, miss row /*from 2008 onwards delmethod is available for >90% pats*/

preserve
keep if anyeligible==.
codebook pregid /*1036 with no eligible codes in 60days */
keep patid pregid pregstart pregend
bysort patid: keep if _n==1
save "$Datadir\Derived_data\HES\pats_no_opcs_code", replace
restore

drop if eligiblecode==.
codebook pregid /*4957*/


*Keep codes only from p_order==1 for singleton births
drop if multiple==0 & p_order!=1 
codebook pregid /*4914*/

*For multiple births, create combinations
preserve
keep if multiple==1
keep patid pregid pregend evdate mod5 multiple
bysort patid pregid mod5: keep if _n==1
bysort patid pregid (mod5): gen totalN=_n
*bysort patid pregid (mod5): drop if _N==1 /*drop those with just one type*/
reshape wide mod5, i(pregid) j(totalN)
gen slash="/"
egen all_methods5=concat(mod51 slash mod52), format(%9.0g)
codebook pregid /*21 pregs have conflicting codes*/
tab all_methods5, nolab

lab  define all_methods5 31 "VD and Instrumental VD"  32 "VD and Elective CS" ///
  33 "VD and Emergency CS"  34  "Instrumental VD and Elective CS" ///
  35 "Instrumental VD and Emergency CS"  36  "Elective CS and Emergency CS" ///
  37 "VD and CS NOS"   38 "Instrum VD and CS NOS"   39 "VD and other" ///
  40 "Instrum VD and Other" 41 "Elective CS and CS NOS"  42 "Elective CS and Other"  ///
  43 "Emergency CS and CS NOS"  44 "Emergency CS and Other" 45 "CS NOS and other"
replace all_methods5="0" if all_methods5=="0/." 
replace all_methods5="1" if all_methods5=="1/." 
replace all_methods5="2" if all_methods5=="2/." 
replace all_methods5="3" if all_methods5=="3/." 
replace all_methods5="4" if all_methods5=="4/." 
replace all_methods5="5" if all_methods5=="5/." 
replace all_methods5="31" if all_methods5=="0/1" 
replace all_methods5="32" if all_methods5=="0/2"
replace all_methods5="33" if all_methods5=="0/3"
replace all_methods5="34" if all_methods5=="1/2"
replace all_methods5="35" if all_methods5=="1/3"
replace all_methods5="36" if all_methods5=="2/3"
replace all_methods5="37" if all_methods5=="0/4"
replace all_methods5="38" if all_methods5=="1/4"
replace all_methods5="39" if all_methods5=="0/5"
replace all_methods5="40" if all_methods5=="1/5"
replace all_methods5="41" if all_methods5=="2/4"
replace all_methods5="42" if all_methods5=="2/5"
replace all_methods5="43" if all_methods5=="3/4"
replace all_methods5="44" if all_methods5=="3/5"
replace all_methods5="45" if all_methods5=="4/5"
destring all_methods5, gen(multiple_mod_opcs)
lab val multiple_mod_opcs all_methods5
save "$Datadir\Derived_data\HES\multiple_mod_data_opcs", replace
restore

drop if multiple==1
append using "$Datadir\Derived_data\HES\multiple_mod_data_opcs"

*br patid pregid pregend p_order evdate opcsterm if pregid==111944203 
*br patid pregid pregend p_order evdate opcsterm if pregid==3147746203

/*
////*Look at combinations of codes*/////////
keep patid pregid pregend evdate mod21 multiple
bysort patid pregid mod21: keep if _n==1
bysort patid pregid (mod): gen totalN=_n
bysort patid pregid (mod): drop if _N==1 /*drop those with just one type*/
reshape wide mod21, i(pregid) j(totalN)
egen all_mod21=concat(mod211 mod212), format(%9.0g)
codebook pregid /*21 pregs have conflicting codes*/
tab all_mod21
list if all_mod21=="013" 
list if all_mod21=="018"
list if all_mod21=="02"
list if all_mod21=="04"
list if all_mod21=="05"
list if all_mod21=="06"
list if all_mod21=="1013"
list if all_mod21=="1321"
list if all_mod21=="412"
list if all_mod21=="513"
list if all_mod21=="56"
list if all_mod21=="615"

*DECISISON: take code from p_order==1
*/

******************************
keep patid pregid pregend mod* multiple*
duplicates drop
rename mod2 opcs_mod2
rename mod5 opcs_mod5
rename mod21 opcs_mod21
save "$Datadir\Derived_data\HES\mod_data_opcs", replace

********************
/*
/*Explore those with no eligible OPCS codes*/
use  $Rawdatdir\stata\data_linked\20_000228_hes_procedures.dta", clear
rename opcs opcscode
merge m:1 opcscode using J:\EHR-Working\Harriet\Codelists\all_dictionaries_opcs, keep(match) force nogen
sort patid epistart
merge m:1 patid using "$Datadir\Derived_data\HES\pats_no_opcs_code"
*keep codes within yr of pregend
gen diff=abs(evdate-pregend)
sum diff, d
keep if diff<365.25
br  pregend evdate opcsterm if _m==3
bysort opcster: keep if _n==1
keep opcsterm opcscode
*/
********************




********************************************************************************
*HES Maternity tail: delivery method data only
********************************************************************************

forvalues x=1/17 {
use "$Datadir\Derived_data\CPRD\pregnancy_cohort_final_`x'", clear
keep if outcome==1 | outcome==2 /*completed pregnancies*/
merge 1:m patid using "$Datadir\Derived_data\HES/20_000228_hes_maternity.dta", keep(match) nogen ///
keepusing(mod* epistart birordr delplac delonset delint delprean gestat time_in_hosp_hesmt)
tempfile preg`x'
save `preg`x''
}

use `preg1'
forvalues x=2/19 {
append using `preg`x''
}


*Flag multiple births, as recorded in the HES maternity tail
*!!!Some multiple births not being picked up in PREG REGISTER!!!!
replace birord="." if birord=="X"
destring birord, replace
gen hesmt_multiple_ev_temp=1 if birord==2
bysort pregid: egen hesmt_multiple_ev=max(hesmt_multiple_ev_temp)
recode hesmt_multiple_ev .=0
drop hesmt_multiple_ev_temp
drop birordr
*NB Other is coded as "9"; could have been mistakenly coded as 9 when meant missing

*Drop if delmethod is missing and keep those within 60 days of pregend
drop if mod21==99 | mod21==. | mod21==21
gen diff=abs(epistart-pregend)
sum diff, d
keep if diff<60

codebook pregid /*4145/5993 (69%)*/

bysort pregid: gen bign=_N
tab bign if multiple==0 & hesmt_multiple_ev==0 /*~2% of singleton records have multiple delmeth codes
0.7% if exclude of "9's"*/
br patid pregid pregend epistart mod* multiple* hesmt_multiple_ev bign if bign>1

*For multiple births, create combinations
preserve
keep if multiple==1 | hesmt_multiple_ev==1
keep patid pregid pregend epistart mod5 multiple hesmt_multiple_ev delplac 
bysort patid pregid mod5: keep if _n==1
bysort patid pregid (mod5): gen totalN=_n
*bysort patid pregid (mod5): drop if _N==1 /*drop those with just one type*/
reshape wide mod5, i(pregid) j(totalN)
gen slash="/"
egen all_methods5=concat(mod51 slash mod52), format(%9.0g)
codebook pregid /*21 pregs have conflicting codes*/
tab all_methods5
replace all_methods5="0" if all_methods5=="0/." 
replace all_methods5="1" if all_methods5=="1/." 
replace all_methods5="2" if all_methods5=="2/." 
replace all_methods5="3" if all_methods5=="3/." 
replace all_methods5="4" if all_methods5=="4/." 
replace all_methods5="5" if all_methods5=="5/." 
replace all_methods5="31" if all_methods5=="0/1" 
replace all_methods5="32" if all_methods5=="0/2"
replace all_methods5="33" if all_methods5=="0/3"
replace all_methods5="34" if all_methods5=="1/2"
replace all_methods5="35" if all_methods5=="1/3"
replace all_methods5="36" if all_methods5=="2/3"
replace all_methods5="37" if all_methods5=="0/4"
replace all_methods5="38" if all_methods5=="1/4"
replace all_methods5="39" if all_methods5=="0/5"
replace all_methods5="40" if all_methods5=="1/5"
replace all_methods5="41" if all_methods5=="2/4"
replace all_methods5="42" if all_methods5=="2/5"
replace all_methods5="43" if all_methods5=="3/4"
replace all_methods5="44" if all_methods5=="3/5"
replace all_methods5="45" if all_methods5=="4/5"
destring all_methods5, gen(multiple_mod_hesmt)
lab val multiple_mod_hesmt   all_methods5
tab multiple_mod_hesmt
save "$Datadir\Derived_data\HES\multiple_mod_data_hesmt", replace
codebook pregid
restore

drop if multiple==1 | hesmt_multiple_ev==1
append using "$Datadir\Derived_data\HES\multiple_mod_data_hesmt"

/*Look at inconsistent delivery codes in singleton births - NONE
keep if multiple==0 & hesmt_multiple_ev==0
keep patid pregid pregend delmeth
bysort pregid delmeth: keep if _n==1
bysort patid: gen totalN=_n
reshape wide delmeth, i(pregid) j(totalN)
egen all_methods=concat(delmeth1 delmeth2), format(%9.0g)
tab all_methods*/

******************************
keep patid pregid pregend mod* multiple* hesmt_multiple_ev delplac  time_in_hosp_hesmt
duplicates drop
rename mod2 hesmt_mod2
rename mod5 hesmt_mod5
rename mod21 hesmt_mod21
save "$Datadir\Derived_data\HES\mod_data_hes_maternity", replace
codebook pregid

********************************************************************************
*HES episodes file
********************************************************************************
forvalues x=1/17 {
use "$Datadir\Derived_data\CPRD\pregnancy_cohort_final_`x'", clear
merge 1:m patid using "$Datadir\Derived_data\HES\icd_mod_data_all", keep(match master)  
tempfile preg`x'
save `preg`x''
}

use `preg1'
forvalues x=2/19 {
append using `preg`x''
}

*Patients with ZERO ICD10 codes
codebook pregid if _m==1
*N=4229/5,993 pregnancies have ZERO ICD10 code

*Keep those within 60 days either side of pregend
gen diff=abs(epistart-pregend)
sum diff, d
keep if diff<60
codebook pregid /*803 pregs*/


*Keep codes only from p_order==1 for singleton births
drop if multiple==0 & d_order!=1 
codebook pregid if multiple==0 /**/

bysort pregid: gen bign=_N
tab bign if multiple==0  /*0% of singleton records have multiple mod codes*/


*For multiple births, create combinations - NO INCONSISTENCIES in feas data
preserve
keep if multiple==1
keep patid pregid pregend epistart mod5 multiple
bysort patid pregid mod5: keep if _n==1
bysort patid pregid (mod5): gen totalN=_n
/*bysort patid pregid (mod5): drop if _N==1 /*drop those with just one type*/
reshape wide mod5, i(pregid) j(totalN)
gen slash="/"
egen all_methods5=concat(mod51 slash mod52), format(%9.0g)
codebook pregid /*21 pregs have conflicting codes*/
tab all_methods5
replace all_methods5="0" if all_methods5=="0/." 
replace all_methods5="1" if all_methods5=="1/." 
replace all_methods5="2" if all_methods5=="2/." 
replace all_methods5="3" if all_methods5=="3/." 
replace all_methods5="4" if all_methods5=="4/." 
replace all_methods5="5" if all_methods5=="5/." 

replace all_methods5="31" if all_methods5=="0/1" 
replace all_methods5="32" if all_methods5=="0/2"
replace all_methods5="33" if all_methods5=="0/3"
replace all_methods5="34" if all_methods5=="1/2"
replace all_methods5="35" if all_methods5=="1/3"
replace all_methods5="36" if all_methods5=="2/3"
replace all_methods5="37" if all_methods5=="0/4"
replace all_methods5="38" if all_methods5=="1/4"
replace all_methods5="39" if all_methods5=="0/5"
replace all_methods5="40" if all_methods5=="1/5"
replace all_methods5="41" if all_methods5=="2/4"
replace all_methods5="42" if all_methods5=="2/5"
replace all_methods5="43" if all_methods5=="3/4"
replace all_methods5="44" if all_methods5=="3/5"
replace all_methods5="45" if all_methods5=="4/5"
destring all_methods5, gen(multiple_mod_hesmt)
lab val multiple_mod_hesmt   all_methods5
tab multiple_mod_hesmt
*/
save "$Datadir\Derived_data\HES\multiple_mod_data_icd", replace
restore

drop if multiple==1
append using "$Datadir\Derived_data\HES\multiple_mod_data_icd"


keep patid pregid pregend mod5 mod21 mod2 multiple*
duplicates drop

bysort pregid: gen bign=_N
sum bign

rename mod2 icd_mod2
rename mod5 icd_mod5
rename mod21 icd_mod21
save "$Datadir\Derived_data\HES\mod_data_icd", replace
codebook pregid /*should be all unique values*/


********************************************************************************
*CPRD - clinical file
********************************************************************************

use "$Rawdatdir\stata\data_gold_2021_08\collated_files\All_Clinical_Files.dta", clear
merge m:1 medcode using "$codes\mode of delivery\read_mod_draft_hf", keep(match) nogen
save "$Datadir\Derived_data\CPRD\clinical_mod_reduced", replace



forvalues x=1/17 {
use "$Datadir\Derived_data\CPRD\pregnancy_cohort_final_`x'", clear
merge 1:m patid using "$Datadir\Derived_data\CPRD\clinical_mod_reduced", keep(match master)  keepusing(eventdate mod21 mod5 mod2)
tempfile preg`x'
save `preg`x''
}

use `preg1'
forvalues x=2/17 {
append using `preg`x''
}

duplicates drop

*Patients with ZERO READ codes
codebook pregid if _m==1
*N=1265/5,993 pregnancies have ZERO READ code

*Keep those within 60 days either side of pregend
gen diff=abs(eventdate-pregend)
sum diff, d
keep if diff<60
codebook pregid /*3845 pregs*/

duplicates drop patid pregid mod21, force

bysort pregid: gen bign=_N
tab bign if multiple==0  /*~3.5% of singleton records have multiple mod codes*/
br patid pregid pregend eventdate mod21 multiple bign if bign>1
codebook patid

*If CS Unspecified and CS specified, choose CS specified
sort patid pregid mod21
*Flag specific CS, wehre followed by a non-specific CS
bysort pregid (mod21):  gen flag=1 if (mod21[_n==1]==14 | mod21[_n==1]==15 | ///
mod21[_n==1]==16 | mod21[_n==1]==17 | mod21[_n==1]==18 | mod21[_n==1]==19) & ///
mod21[_n+1]==20 
*Keeps flagged CS
bysort pregid (mod21): drop if [_n+1] & flag==1
codebook patid

drop bign
bysort pregid: gen bign=_N
tab bign if multiple==0  /*~1.6% of singleton records have multiple mod codes*/
br patid pregid pregend eventdate mod21 multiple bign if bign>1
codebook patid
drop flag

*If Elective CS LUS and Elective CS unspec, choose Elective CS LUS
*Flag specific CS, wehre followed by a less specific CS
bysort pregid (mod21):  gen flag=1 if (mod21[_n==1]==15 ) & ///
mod21[_n+1]==16 
br patid pregid pregend eventdate mod21 multiple bign flag if bign>1

*Keeps flagged CS
bysort pregid (mod21): drop if [_n+1] & flag==1
codebook patid
drop bign
bysort pregid: gen bign=_N
tab bign if multiple==0  /*~1.6% of singleton records have multiple mod codes*/
br patid pregid pregend eventdate mod21 multiple bign if bign>1
codebook patid
drop flag

*Pick latest, then most complex (if two inconsistent codes appeared same day)?

*Drop if have conflicting MOD codes within singleton deliveries
preserve 
keep if bign>1 & multiple==0
keep patid
duplicates drop 
save "$Datadir\Derived_data\CPRD\patids_conflicting_codes_in_CPRD", replace
restore
drop if bign>1 & multiple==0

*For multiple births, create combinations
preserve
keep if multiple==1 
keep patid pregid pregend eventdate mod5 multiple
bysort patid pregid mod5: keep if _n==1
bysort patid pregid (mod5): gen totalN=_n
*bysort patid pregid (mod5): drop if _N==1 /*drop those with just one type*/
reshape wide mod5, i(pregid) j(totalN)
gen slash="/"
egen all_methods5=concat(mod51 slash mod52), format(%9.0g)
codebook pregid /*21 pregs have conflicting codes*/
tab all_methods5
replace all_methods5="0" if all_methods5=="0/." 
replace all_methods5="1" if all_methods5=="1/." 
replace all_methods5="2" if all_methods5=="2/." 
replace all_methods5="3" if all_methods5=="3/." 
replace all_methods5="4" if all_methods5=="4/." 
replace all_methods5="5" if all_methods5=="5/." 
replace all_methods5="31" if all_methods5=="0/1" 
replace all_methods5="32" if all_methods5=="0/2"
replace all_methods5="33" if all_methods5=="0/3"
replace all_methods5="34" if all_methods5=="1/2"
replace all_methods5="35" if all_methods5=="1/3"
replace all_methods5="36" if all_methods5=="2/3"
replace all_methods5="37" if all_methods5=="0/4"
replace all_methods5="38" if all_methods5=="1/4"
replace all_methods5="39" if all_methods5=="0/5"
replace all_methods5="40" if all_methods5=="1/5"
replace all_methods5="41" if all_methods5=="2/4"
replace all_methods5="42" if all_methods5=="2/5"
replace all_methods5="43" if all_methods5=="3/4"
replace all_methods5="44" if all_methods5=="3/5"
replace all_methods5="45" if all_methods5=="4/5"
destring all_methods5, gen(multiple_mod_read)
lab val multiple_mod_read   all_methods5
tab multiple_mod_read
save "$Datadir\Derived_data\CPRD\multiple_mod_data_read", replace
codebook pregid
restore

drop if multiple==1
append using "$Datadir\Derived_data\CPRD\multiple_mod_data_read"

rename mod2 read_mod2
rename mod21 read_mod21
rename mod5 read_mod5
codebook pregid
save "$Datadir\Derived_data\CPRD\mod_data_read", replace

********************************************************************************
/*CPRD - additional clinical details file
114	Pregnancy outcome	Clinical	Maternity	2	Discharge Date	dd/mm/yyyy	Birth status	LIV												
115	Delivery Details (CHS)	Clinical	Child Health Surveillance	2	Birth Mode	BMO	Birth Presentation	BPR												
120	Gestational age of baby	Clinical	Child Health Surveillance	3	Weeks 		Unit of measure	SUM	Outcome of Delivery	SIN										
93	Delivery details	Clinical	Maternity	0																
*/

*CPRD additional details 
********************************************************************************
use "$Rawdatdir\stata\data_gold_2021_08\collated_files\All_Clinical_Files.dta", clear
keep if  enttype==115 
merge 1:m patid enttype adid using "$Rawdatdir\stata\data_gold_2021_08\collated_files\All_Additional_Files.dta", keep(match)
keep if data1!=.
/*Code	Birth Mode
0	Data Not Entered
1	Normal
2	Forceps
3	Ventouse
4	Caesarian
5	Unknown*/
gen mod21=data1
recode mod21 0=. 1=0 2=12 3=13 4=20 5=.
lab val mod21 mod21

gen mod5=data1
recode mod5 0=. 1=0 2=1 3=1 4=4 5=.
lab val mod5 mod5

gen mod2=mod5
recode mod2 0/1=0 2/4=1 5=2 
lab define mod2 ///
0 "VD"  ///
1 "CS"  ///
2 "Other"
lab val mod2 mod2

save "$Datadir\Derived_data\CPRD\cprd_entity_BMO_all", replace


forvalues x=1/17 {
use "$Datadir\Derived_data\CPRD\pregnancy_cohort_final_`x'", clear
merge 1:m patid using "$Datadir\Derived_data\CPRD\cprd_entity_BMO_all", keep(match master)  keepusing(eventdate mod21 mod5 mod2)
tempfile preg`x'
save `preg`x''
}

use `preg1'
forvalues x=2/17 {
append using `preg`x''
}

duplicates drop

*Patients with ZERO enttype codes
codebook pregid if _m==1
*N=5890/5,993 pregnancies have ZERO enttype code

*Keep those within 60 days either side of pregend
gen diff=abs(eventdate-pregend)
sum diff, d
keep if diff<60
codebook pregid /*57 pregs*/

duplicates drop patid pregid mod21, force

bysort pregid: gen bign=_N
tab bign if multiple==0  /*0% of singleton records have multiple mod codes*/

/*For multiple births, create combinations - NONE
preserve
keep if multiple==1 
keep patid pregid pregend eventdate mod21 multiple
bysort patid pregid mod21: keep if _n==1
bysort patid pregid (mod21): gen totalN=_n
*bysort patid pregid (mod21): drop if _N==1 /*drop those with just one type*/
reshape wide mod21, i(pregid) j(totalN)
gen slash="/"
egen all_methods=concat(mod211 slash mod212), format(%9.0g)
codebook pregid /*21 pregs have conflicting codes*/
tab all_methods
encode all_methods, gen(multiple_mod_enttype)
save "$Datadir\Derived_data\CPRD\multiple_mod_data_enttype", replace
codebook pregid
restore

drop if multiple==1
append using "$Datadir\Derived_data\CPRD\multiple_mod_data_enttype"
*/

keep patid pregid pregend mod5 mod21 mod2 multiple*
rename mod2 enttype_mod2
rename mod21 enttype_mod21
rename mod5 enttype_mod5
codebook pregid
save "$Datadir\Derived_data\CPRD\mod_data_enttype", replace


********************************************************************************
***********************COMBINE MOD DATA FROM INDIVIDUAL DBs*********************
********************************************************************************

use "$Datadir\Derived_data\CPRD\pregnancy_cohort_final_final", clear


*Year
gen yeargp=year
recode yeargp 1998/2000=1997 2002/2005=2001 2007/2010=2006 2012/2015=2011 2017=2016

*Merge in HES dBs for MOD
merge 1:1 pregid using "$Datadir\Derived_data\HES\mod_data_opcs", nogen
tab opcs_mod5, miss
merge 1:1 pregid using "$Datadir\Derived_data\HES\mod_data_hes_maternity", keep(match master) nogen
tab hesmt_mod5, miss
merge 1:1 pregid using "$Datadir\Derived_data\HES\mod_data_icd", keep(match master) nogen
tab icd_mod5, miss
merge 1:1 pregid using "$Datadir\Derived_data\CPRD\mod_data_read", keep(match master) nogen
tab read_mod5, miss
merge 1:1 pregid using "$Datadir\Derived_data\CPRD\mod_data_enttype", keep(match master) nogen
tab enttype_mod5, miss

*Recode "CS NOS" and "Other" to missing
foreach var in opcs_mod5 hesmt_mod5 icd_mod5 read_mod5 enttype_mod5 ///
multiple_mod_opcs multiple_mod_hesmt  multiple_mod_read  {
recode `var' 4=. 5=.
}

count

/*Identify agreements
egen hes_count=anycount(opcs_mod5 icd_mod5 hesmt_mod5), values (0 1 2 3 4)
gen hes_match=99 if hes_count==0
recode hes_match .=9 if hes_count==1
recode hes_match .=1 if hes_count==2 & ///
((opcs_mod5==icd_mod5) | ( opcs_mod5==hesmt_mod5) | ( icd_mod5==hesmt_mod5))
recode hes_match .=1 if hes_count==3 & (opcs_mod5==icd_mod5) & opcs_mod5==hesmt_mod5 
recode hes_match .=0
recode hes_match 9=1 99=. /*3% mismatch in HES*/
tab hes_match

egen cprd_count=anycount(read_mod5 enttype_mod5), values (0 1 2 3 4)
gen cprd_match=99 if cprd_count==0
recode cprd_match .=9 if cprd_count==1
recode cprd_match .=1 if cprd_count==2 & (read_mod5==read_mod5) 
recode cprd_match .=0
recode cprd_match 9=1 99=. /*3% mismatch in cprd*/
tab cprd_match
*/

*Drop pregnancies where there are discrepancies either within cprd or within hes
drop if hes_match==0
drop if cprd_match==0

/*Flag inconsistencies between CPRD and HES
gen hes_final=max(opcs_mod5, icd_mod5, hesmt_mod5)
gen cprd_final=max(read_mod5, enttype_mod5)

egen hes_cprd_count=anycount(cprd_final hes_final), values (0 1 2 3 4)
gen hes_cprd_match=99 if hes_cprd_count==0
recode hes_cprd_match .=9 if hes_cprd_count==1
recode hes_cprd_match .=1 if hes_cprd_count==2 & (hes_final==cprd_final) 
recode hes_cprd_match .=0
recode hes_cprd_match 9=1 99=. /*3% mismatch in hes_cprd*/
tab hes_cprd_match
*/

count

/**Missing flag
misstable sum icd_mod5 read_mod5 opcs_mod5 hesmt_mod5 enttype_mod5, gen(_miss_)
foreach var in _miss_icd_mod5 _miss_read_mod5 ///
 _miss_opcs_mod5 _miss_enttype_mod5 _miss_hesmt_mod5 {
 recode `var' 1=0 0=1
 }
rename _miss_icd_mod5 icd
rename _miss_read_mod5 read
rename  _miss_opcs_mod5 opcs
rename  _miss_enttype_mod5 enttype
rename  _miss_hesmt_mod5 hesmt


*Totals
tab hesmt_multiple_ev
tab multiple_ev
tab multiple_ev hesmt_multiple_ev
*/

lab define multiple_mod ///
0 "VD non-instrumental"  ///
1 "VD Instrum"  ///
2 "Elective CS"  ///
3 "Emerg CS"  ///
4 "Caesarean Not specified"  ///
 31 "VD and Instrumental VD"  32 "VD and Elective CS" ///
  33 "VD and Emergency CS"  34  "Instrumental VD and Elective CS" ///
  35 "Instrumental VD and Emergency CS"  36  "Elective CS and Emergency CS" ///
  37 "VD and CS NOS"   38 "Instrum VD and CS NOS"   39 "VD and other" ///
  40 "Instrum VD and Other" 41 "Elective CS and CS NOS"  42 "Elective CS and Other"  ///
  43 "Emergency CS and CS NOS"  44 "Emergency CS and Other" 45 "CS NOS and other" ///
  99 Missing

*Incorporate MULTIPLE MOD into mod5
foreach var in opcs hesmt read {
tab multiple_mod_`var'
replace multiple_mod_`var'=`var'_mod5  if multiple_mod_`var'==. & multiple_ev==1
replace multiple_mod_`var'=99 if multiple_mod_`var'==5 
replace multiple_mod_`var'=99 if multiple_mod_`var'==. & multiple_ev==1
lab val multiple_mod_`var' multiple_mod
tab multiple_mod_`var'
}

drop if multiple_ev==1

*CReate a variable which uses all data sources
gen comb_mod5=opcs_mod5
tab comb_mod5, miss
gen source=1 if comb_mod5!=.
replace comb_mod5=hesmt_mod5 if comb_mod5==.
tab comb_mod5, miss
recode source .=2 if comb_mod5!=.
replace comb_mod5=icd_mod5 if comb_mod5==.
tab comb_mod5, miss
recode source .=3 if comb_mod5!=.
replace comb_mod5=read_mod5 if comb_mod5==.
tab comb_mod5, miss
recode source .=4 if comb_mod5!=.
replace comb_mod5=enttype_mod5 if comb_mod5==.
tab comb_mod5, miss
recode source .=5 if comb_mod5!=.
lab val comb_mod5 mod5
tab comb_mod5, miss
tab comb_mod5 source, miss row

tab comb_mod5 if year>=2010, miss
tab comb_mod5 fetal_lie_final, miss row chi

save $Datadir\Derived_data\CPRD\MOD_final", replace
