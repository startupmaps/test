capture log close growthreg
log using ~/kauffman_neg/output/Growth_Regression.log, name(growthreg) text replace 

cd ~/kauffman_neg
set matafavor speed
global do_pvar 0

clear
u state_indexes.dta, replace
merge 1:1 stateabbr year using GSP.dta
keep if _merge == 3
drop _merge
merge 1:1 stateabbr year using state_external.dta
drop if _merge == 2
drop _merge

drop growth*y
encode stateabbr,gen(id)
sort id year

drop if year == 2014
replace recpi = recpinow if missing(recpi) | recpi == 0

outsheet using ~/kauffman_neg/output/Growth_Regression_raw_data.csv, names comma replace
foreach v of varlist recpi recpinow obs gsp firmbirthsbds { 
    replace `v' = ln(`v')
}
gen gdprecpi = recpi/gsp
gen gdpobs = obs/gsp
gen gdpbdsbirths = firmbirthsbds/gsp
xtset id year
rename firmbirthsbds bdsbirths


gen growth = F6.gsp - gsp
sum  growth gsp reallocation_rate bdsbirths obs quality recpi
pwcorr  growth gsp reallocation_rate bdsbirths obs quality recpi, sig star(0.05)





capture program drop growth_regression
growth_regression, forward_lag(6) iv_lag(2 4) save(~/kauffman_neg/output/GrowthRegression_6yrsout$output_suffix.csv) quietly 
growth_regression, forward_lag(6) iv_lag(2 2) robustness save(~/kauffman_neg/output/GrowthRegression_6yrsout_Robustness$output_suffix.csv) quietly



log close growthreg



