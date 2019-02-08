/*
 * models hasmanagerfe statefe epon noepon
 */

program define build_model, rclass
    syntax ,   [model(string)] [fe(string)] [noestclear] [across(string)] [nopredict] [includeemployment] [montecarlo] [onlymain]


    if "`model'" == "" {
        local model noepon
    }

    di "Params:fe ==`fe' ; noestclear=`noestclear'"


    /*
     * Model dependent variables
     */
         local eponorder *eponymous
       if "`model'" == "hasmanagerfe" {
           replace eponymous = has_eponymous_X_eponymous
           local eponymousregressors has_eponymous eponymous
       }
       else if "`model'" == "statefe" {
           local eponymousregressors eponymous i.statecode
       }
       else if "`model'" == "epon" {
           local eponymousregressors eponymous
       }
       else if "`model'" == "noepon" {
           local eponymousregressors 
           local eponorder
       }
       else {
           di "Error, model not known"
           return 111
       }


    /*
     * Build Model
     */
         
     if "`noestclear'" == "" {
         eststo clear
     }


     if "`across'" == "" {
         if "`nopredict'" == "" {
             safedrop quality qualitynow quality2
         }

         replace eponymous = 0 if missing(eponymous)

         if "`onlymain'" == "" { 
         
             di "Running Nowcasting Model"
                 # delimit ;
                    eststo: logit growthz shortname eponymous
                            is_corp is_DE
                            clust_local  clust_resource_int clust_traded
                            is_biotech is_ecommerce is_IT is_medicaldev is_semicond
                             ib`fe'.statecode
                                      if trainingyears, vce(robust) or iter(60);

                 # delimit cr

             if `e(converged)' == 0 {
                 return scalar converged=0
                 exit
             }

             if "`nopredict'" == "" {
                 predict qualitynow
                 di "Nowcasted estimate stored in variable qualitynow"
             }

             di "Estimate stored in variable qualitynow"
         }

         di "Running Main Model"
           # delimit ;

 local full_model_params is_corp shortname
                        eponymous
                        trademark patent_noDE nopatent_DE patent_and_DE 
                        clust_local  clust_resource_int clust_traded
                        is_biotech is_ecommerce is_IT is_medicaldev is_semicond
                        ib`fe'.statecode;

                eststo, title("All States"):logit growthz
                                 `full_model_params'
                                if trainingyears, vce(robust) or iter(60);
            
                  # delimit cr

         if `e(converged)' == 0 {
             return scalar converged=0
             exit
         }
         
         if "`nopredict'" == "" {
             predict quality
             di "entreprenuerial quality estimate stored in variable quality"
         }
     }



      if "`includeemployment'" ==  "includeemployment" {
          di "Running Employment Model 100/500"
          
          eststo, title("All States"):logit emp_over_250 `full_model_params' if inrange(incyear,1997-6,2011-6), vce(robust) or iter(60)
          
          if `e(converged)' == 0 {
              return scalar converged=0
              exit
          }
          
          if "`nopredict'" == "" {
                safedrop qualityemp
                predict qualityemp
                di "qualityemp variable estimated"
                
            }
         }

    # delimit ;
    esttab, se pr2 eform label
           order(is_corp eponorder shortname haslastname haspropername has_unique_name eponymous is_DE patent trademark patent_noDE nopatent_DE patent_and_DE) gap;
        
           
    # delimit cr

   return scalar converged=1
end 
