cd ~/kauffman_neg/


if $mc_start_iteration == 1 {    
    clear
    gen iteration_number =.
    save mc_index_results.dta, replace
    
}


local q="qui:"
if $verbose == 1 {
    local q=""
}

forvalues i = $mc_start_iteration/$num_monte_carlo_iterations {
    di "********************************************"
    di "           Monte Carlo Iteration `i'"
    di "********************************************"

    di "Loading Data"
    clear
    u $datafile

    
    di "Sampling"
    bsample

    tab statecode 
    
    di "Build Model"
    `q' build_model , fe(11) includeemployment

    if `r(converged)' == 0 {
        * If the thing didn't converge, just skip to next iteration
        di "Error: The regression did not converge, skipping"
        continue
    }
    
    di "Build Indexes"
    build_indexes , skipstates($skip_states_in_indexes) qualityboost(qualityboost.dta)

    gen iteration_number = `i'
    append using mc_index_results.dta, force
    save mc_index_results.dta, replace


    if `i' == 1 | `i' == 10 | `i' == 50 | `i' == 100 {
        do proposal2/Index_Results.do
    }
}



