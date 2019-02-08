
capture log close

log using ~/kauffman_neg/output/Build_National_results.log, replace text


capture program drop univariate
capture program drop build_preliminary_model
capture program drop build_model
capture program drop build_robustness_model


cd ~/kauffman_neg
clear
u $datafile

safedrop trainingyears
gen trainingyears = inrange(incyear,1988,2008)
save $datafile,replace


safedrop obs
gen obs = 1
label variable growthz "Growth"

if $results_summary_stats == 1 {
  /*
  * Summary Statistics
  */
      local all_observable_measures   is_corp shortname eponymous is_DE patent trademark clust_local  clust_resource_int clust_traded  is_biotech is_ecommerce is_IT is_medicaldev is_semicond 
      replace growthz = . if incyear > 2008
      replace patent = . if incyear > 2012
      replace trademark = . if incyear > 2012

      eststo clear
      estpost tabstat growthz `all_observable_measures', columns(statistics) statistics(count mean sd) 
      esttab ,  cells("count mean sd") nomtitle nonumber label varwidth(30)
      esttab using output/SummaryStatistics$output_suffix.csv ,  cells("count mean sd") nomtitle nonumber label varwidth(30) replace plain
}


/*
 * Econometric Model
 */
 
safedrop statecode
encode datastate, gen(statecode)

     
if $build_model == 1 {  


    if $build_model_univariate == 1 {
        univariate
        esttab using output/Univariate_Model$output_suffix.csv, se pr2 eform  replace label
    }

    if $build_model_preliminary == 1 {
        build_preliminary_model, fe(11)
        esttab using ~/kauffman_neg/output/RegressionModel_Intermediate_$output_suffix.csv, eform se pr2 replace
    }

    if $build_main_model == 1 {
        build_model, $model_params noestclear fe(11)  
        esttab using ~/kauffman_neg/output/RegressionModel$output_suffix.csv, eform se pr2 replace
        save $datafile, replace
    }

    
    if $build_model_robustness == 1 {
        build_robustness_model, fe(11) 
        esttab using ~/kauffman_neg/output/RegressionModel_Robustness$output_suffix.csv, eform se pr2 replace
    }


    if $build_model_employment == 1 {
        build_employment_model, fe(11) 
        esttab using ~/kauffman_neg/output/RegressionModel_Employment$output_suffix.csv, eform se pr2 replace

    }




    

log close
