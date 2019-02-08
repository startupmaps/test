cd ~/final_datasets


*do ~/final_datasets/Build_High_Employment_File.do

cd ~/kauffman_neg

/*
clear
u analysis32.minimal.dta
levelsof datastate, local(states)
*/

local states IL WI



foreach st in `states' {


    
    di "In State `st'"
    di "Removing Merger Varialbne"
    clear
    u ~/final_datasets/`st'.dta
    safedrop _merge
    safedrop _mergex
    save ~/final_datasets/`st'.dta , replace
    
    di "Starting Analysis"
    clear
    u ~/final_datasets/high_employment_infogroup.allstates.dta
    keep if state == "`st'"
    gen incyear = fileyear-6
    save ~/temp/employment`st'.dta , replace
    jnamemerge ~/final_datasets/`st'.dta  ~/temp/employment`st'.dta

    collapse (max) emp_over_* , by(dataid)
    foreach v of varlist emp_over_* {
        replace `v' = 0 if missing(`v')
    }
    
    di "In State `st'"
    tabstat emp_over_*, columns(variables) stats(sum mean max N)
    
    merge 1:m dataid using ~/final_datasets/`st'.dta
    drop if _merge == 1
    drop _merge
    save  ~/final_datasets/`st'.dta , replace

    
 

}



corp_replace_state , analysisdta(analysis34.collapsed.dta) replacedta(~/final_datasets/WI.collapsed.dta) datastate(WI) add

program define corp_replace_state , rclass
    syntax , analysisdta(string) replacedta(string) datastate(string) [add]



stop here

clear
gen dataid = ""
save only_employment.dta , replace

foreach st in `states' {
    clear
    di "In State `state'"
       corp_collapse_any_state `st' , workingfolder(~/final_datasets/) force_local_firm extra(emp_over_*)
    u ~/final_datasets/`st'.collapsed.dta
    gen datastate = "`st'"
    tostring dataid , replace
    keep dataid datastate emp_over*
    append using only_employment.dta
    save only_employment.dta , replace
}



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

