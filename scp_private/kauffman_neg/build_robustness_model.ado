program define build_robustness_model, rclass
{
    syntax , fe(string)

    levelsof datastate, local(states)
    foreach st of local states {
        safedrop statey_`st'
        gen statey_`st'  = incyear if datastate == "`st'"
        replace statey_`st' = 0 if missing(statey_`st')
    }

   safedrop statecode
   encode datastate, gen(statecode)


    di "Running Robustness Models"
    eststo clear        




       # delimit ;
        eststo: logit growthz is_corp  shortname 
                   eponymous trademark nopatent_DE patent_noDE patent_and_DE 
                 clust_local  clust_resource_int clust_traded
                  is_biotech is_ecommerce is_IT is_medicaldev is_semicond
                          ib`fe'.statecode i.incyear 
                       if trainingyears, vce(robust) or;

    eststo: logit growthz is_corp  shortname 
                   eponymous trademark nopatent_DE patent_noDE patent_and_DE 
                 clust_local  clust_resource_int clust_traded
                  is_biotech is_ecommerce is_IT is_medicaldev is_semicond
                          ib`fe'.statecode statey_*
                       if trainingyears, vce(robust) or iter(70);

    eststo: logit growthz is_corp  shortname 
                   eponymous trademark nopatent_DE patent_noDE patent_and_DE 
                 clust_local  clust_resource_int clust_traded
                  is_biotech is_ecommerce is_IT is_medicaldev is_semicond
                          ib`fe'.statecode statey_* i.incyear
                       if trainingyears, vce(robust) or iter(70);
     
       
# delimit cr
    
 esttab, pr2 eform indicate("Year Fixed-Effects = *incyear" "State FE=*statecode") order(*name eponymous is_corp is_DE patent trademark patent_noDE nopatent_DE patent_and_DE)
}
end
