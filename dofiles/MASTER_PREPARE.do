
********************************************************************************
* do file author:	Paul Madley-Dowd
* Date: 			28 September 2021
* Description: 		Master file for the PREPArE study
* Notes on major updates (Date - description):
* 
********************************************************************************
* Contents
/********************************************************************************
* 1 - Run global file
* 2 - Insheet and format raw text data files 
* 3 - Select eligible participants (create cohorts)
* 4 - Clean ASM prescribing data and derive exposure variables 
* 5 - Identify indications
* 6 - Derive covariates 
* 7 -  Derive outcomes */


********************************************************************************
* 1 - Run global file and libraruy file
********************************************************************************
* Clear all macros
macro drop _all

* Preliminary step - set up $Gitdir\ to where it is stored on your computer 
global Gitdir "YOUR_PATHWAY\github"

* Run global file held in $Gitdir
do "$Gitdir\dofiles\global.do"

* Run lobal file held in $Gitdir 
do "$Gitdir\dofiles\library.do"


********************************************************************************
* 2 - Insheet and format raw text data files 
********************************************************************************
*CPRD data
do "$Dodir\Data management\cr_Insheet_and_format_CPRD.do"
do "$Dodir\Data management\cr_Insheet_CPRD_lookup.do"
*HES data
do "$Dodir\Data management\cr_Insheet_and_format_HES.do"
*IMD data
do "$Dodir\Data management\cr_Insheet_and_format_IMD.do"
*ONS data
do "$Dodir\Data management\cr_Inssheet_and_format_ONS.do"


********************************************************************************
* 3 - Select eligible participants (create cohorts)
********************************************************************************
do "$Dodir\Data management\cr_Select_eligible_participants.do" 


********************************************************************************
* 4 - Clean ASM prescribing data and derive exposure variables 
********************************************************************************
* Extract and clean individual ASM prescriptions (define dose, length, ASM type)
do "$Dodir\Data management\cr_ASM_prescriptions_cleaning.do"

* Derive exposure variable information from cleaned prescriptions data
do "$Dodir\Data management\cr_ASM_prescriptions_exposure_derivation.do"



********************************************************************************
* 5 - Identify indications
********************************************************************************
do "$Dodir\Data management\cr_ASM_prescription_indications.do"


********************************************************************************
* 6 - Derive covariates 
********************************************************************************
do "$Dodir\Data management\cr_Covariates_derivation.do" 







