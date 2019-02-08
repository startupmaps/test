program define univariate, rclass

# delimit ;
local all_regressors shortname eponymous is_corp is_DE patent trademark
                  clust_local  clust_resource_int clust_traded
                  is_biotech is_ecommerce is_IT is_medicaldev is_semicond;


eststo clear;
foreach r in `all_regressors'{;
    eststo: logit growthz `r' if inrange(incyear,1988,2008) ,vce(robust) or;
 };

esttab;

# delimit cr

end
