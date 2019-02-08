/************************************************************************************/
/* The reson to have a script is that we do not know if the                         */
/* geocoding data that we're going to use matches well to the stuff in Kauffman_NEG */
/************************************************************************************/
cd ~/kauffman_neg/

local state $state
di "On State `state'"
clear
u ~/final_datasets/`state'.dta
tostring dataid , replace
duplicates drop dataid,  force



keep if state == "`state'"
safedrop incyear
gen incyear = year(incdate)
keep if incyear >= 1988

keep dataid incyear incdate entityname address city state zipcode 

tostring zipcode, replace
replace zipcode = "0" + zipcode if length(zipcode) ==4

rename (entityname address city state zipcode) (Business Address City State ZIP)
replace Business = subinstr(Business, "," ,"", .)



foreach v of varlist _all {
    tostring `v', replace
    replace `v' = subinstr(`v', `"""',  "", .)
    replace `v' = subinstr(`v', `"""',  "", .)
    replace `v' = subinstr(`v', `"""',  "", .)
}

outsheet using ~/projects/reap_proj/geocoding/input_files/`state'_input_smartystreets_08112017_1988to2014.csv , names comma replace
/*

*/
