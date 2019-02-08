program define build_employment_model, rclass 
    syntax , fe(string)

# delimit ;
 local full_model_params is_corp shortname
                        eponymous
                        trademark patent_noDE nopatent_DE patent_and_DE 
                        clust_local  clust_resource_int clust_traded
                        is_biotech is_ecommerce is_IT is_medicaldev is_semicond
                        ib`fe'.statecode;

          di "Running Employment Model 100/500"

          eststo clear
          eststo, title("All States"):logit growthz `full_model_params' if inrange(incyear,1997-6,2011-6), vce(robust) or iter(60)
          eststo, title("All States"):logit emp_over_250 `full_model_params' if inrange(incyear,1997-6,2011-6), vce(robust) or iter(60)
          eststo, title("All States"):logit emp_over_500 `full_model_params' if inrange(incyear,1997-6,2011-6), vce(robust) or iter(60)
          eststo, title("All States"):logit emp_over_1000 `full_model_params' if inrange(incyear,1997-6,2011-6), vce(robust) or iter(60)

         esttab, pr2 se star(* .1 ** .05)
