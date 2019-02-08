
clear
u analysis34.collapsed.dta
duplicates drop dataid datastate , force
capture drop emp_over_*
safedrop _merge
save analysis34.collapsed.dta , replace

clear
u only_employment.dta
duplicates drop dataid datastate , force
merge 1:m dataid datastate using ~/kauffman_neg/analysis34.collapsed.dta 
drop if _merge == 1
drop _merge

foreach v of varlist emp_over_* {
    replace `v' = 0 if missing(`v')
}
save analysis34.collapsed.dta  , replace

