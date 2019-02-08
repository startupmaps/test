log using ~/kauffman_neg/output/Test_Specifications.do, text replace 


cd ~/kauffman_neg/
clear
u mstate.collapsed.dta
/*
 * Test for the correct functional Specification
 *
 */
local all_observable_measures  incyear  is_corp shortname haslastname haspropername eponymous is_DE patent trademark clust_local clust_high_tech clust_resource_int clust_traded  is_biotech is_ecommerce is_IT is_medicaldev is_semicond 

     set trace off
set tracedepth 1
local sample_period = "inrange(incyear,1995,2005)"
local measures_to_keep = ""

logit growthz `all_observable_measures' if `sample_period',vce(robust)
local ll_full_model =  `e(ll)'
foreach v in `all_observable_measures' {
    
    local leave_one_out = subinstr("`all_observable_measures'","`v'"," ",.)
    qui: logit growthz `leave_one_out' if `sample_period', vce(robust)
    local ll = `e(ll)'
    local Wald_test = 2* (`ll' - `ll_full_model')
    di "Wald Test for Including `v'.    X2=`Wald_test'       p > 99.5 critical value: 7.879"

    if `Wald_test' > 7.879 {
        local measures_to_keep `measures_to_keep' `v'
    }
}

di "Final set of useful measures: `measures_to_keep'"






log close
