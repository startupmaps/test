clear
cd ~/kauffman_neg

u analysis34.minimal.dta


safedrop ri_quality
gen ri_quality = .
forvalues y = 1995/2014 {
    di ""
    di ""
    di " ********************************************** Running Model for Year *******************"
    
    logit growthz is_corp shortname eponymous trademark patent_noDE nopatent_DE patent_and_DE clust_local  clust_resource_int clust_traded is_biotech is_ecommerce is_IT is_medicaldev is_semicond ib10.statecode if incyear < (`y' -6)  , vce(robust)

    safedrop q_temp
    predict  q_temp if incyear == `y'
    replace  ri_quality = q_temp if incyear == `y'

}

/*save analysis34.minimal.dta , replace*/


drop if quality == .
drop obs
gen obs = 1
collapse (mean)ri_quality (sum) obs growthz, by(incyear) 
