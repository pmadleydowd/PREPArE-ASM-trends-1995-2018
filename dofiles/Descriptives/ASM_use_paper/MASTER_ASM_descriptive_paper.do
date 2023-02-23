*MASTER DO FILE

***Generate dataset
do "$Dodir\Descriptives\ASM_use_paper\0_generate_study_dateset.do"

***Run analyses
do "$Dodir\Descriptives\ASM_use_paper\1an_descriptive_paper_prev_ASMs_preg.do"
do "$Dodir\Descriptives\ASM_use_paper\2an_Table1_descriptives.do"
do "$Dodir\Descriptives\ASM_use_paper\3an_patterns_of_use.do"
do "$Dodir\Descriptives\ASM_use_paper\4an_risk_factors_discontinuation.do"
do "$Dodir\Descriptives\ASM_use_paper\5an_valproate_use_patterns.do"
