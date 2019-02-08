
/**
 ** This code tests the quality of fit by state and year.
 ** The state and year code are exactly the same, but they iterate across a different variable.
 ** The output is Tables B2 and B3 in the supplementary materials of TSOAE.
 **/


if $test_by_state == 1 {
    clear
    gen fold = .
    save test_states.dta , replace
    forvalues testfold=1/9 { 
        clear
        u $datafile
        drop quality
        replace trainingyears = inrange(incyear,1988,2008) & fold != `testfold'
        build_model, fe(11) onlymain 
        keep if fold == `testfold'
        sort datastate quality
        keep if inrange(incyear,1988,2008)
        by datastate: gen percentile = _n/_N
        gen top10gr = growthz if percentile >= .90
        gen top5gr = growthz if percentile >= .95
        gen top1gr = growthz if percentile >= .99
        collapse (sum) growthz top10gr top5gr top1gr, by(datastate)
        levelsof datastate, local(states)

        foreach t in 10 5 1 {
            gen sharetop`t' =. 
        
            foreach st in `states' {
                replace sharetop`t' = top`t'gr/growthz if datastate == "`st'"
            }

            drop top`t'gr
        }
        append using test_states.dta
        save test_states.dta , replace
    }
    clear
    u test_states.dta
    collapse (max) max1 = sharetop1 max5=sharetop5 max10 = sharetop10 (min) min1 = sharetop1 min5=sharetop5 min10 = sharetop10 (p50) med1 = sharetop1 med5=sharetop5 med10 = sharetop10 , by(datastate)
    outsheet using output/state_test_shares.csv, comma names replace

    clear
    u $datafile
    gen originalquality = quality
    drop if incyear > 2012
    safedrop statequality
    gen statequality = .
    levelsof datastate , local(states)
    foreach st in `states' {
        di "Model for state `st'"
        replace trainingyears = inrange(incyear,1988,2008) & datastate == "`st'"
        capture noisily build_model, onlymain fe(1) nopredict

        if _rc != 0 {
            continue
        }
        
        safedrop predstatequality
        predict predstatequality
        replace statequality = predstatequality if datastate == "`st'"
    }

    save analysis34.qualityanalytics.dta , replace
    
    capture postclose qcorrs
    postfile qcorrs str2 datastate qcorr using state_quality_correlations.dta , replace every(1)
    foreach st in `states' {
        di "correlation for state `st'"
         pwcorr originalquality statequality if datastate == "`st'"
        if _rc == 0 & "`r(rho)'" != ""{
            di "post qcorrs (`st') (`r(rho)')"
            post qcorrs ("`st'") (`r(rho)')
        }
        else {
            di "....Failed"
        }
        
    }
    postclose qcorrs

    clear
    u $datafile
    keep if inrange(incyera,1988,2008)
    collapse (sum) total_growth_events = growthz, by(datastate)
    merge 1:1 datastate using state_quality_correlations.dta

    list , clean noobs
    outsheet using output/state_quality.csv , comma names replace
}


/*********************************************************************/
/**     State level testing ends -- Year level testing begins      ***/
/*********************************************************************/

if $test_by_year == 1 {
    clear
    gen fold = .
    save test_years.dta , replace
    forvalues testfold=1/9 { 
        clear
        u $datafile
        drop quality
        replace trainingyears = inrange(incyear,1988,2008) & fold != `testfold'
        build_model, fe(11) onlymain 
        keep if fold == `testfold'
        sort incyear quality
        keep if inrange(incyear,1988,2008)
        by incyear: gen percentile = _n/_N
        gen top10gr = growthz if percentile >= .90
        gen top5gr = growthz if percentile >= .95
        gen top1gr = growthz if percentile >= .99
        collapse (sum) growthz top10gr top5gr top1gr, by(incyear)
        levelsof incyear, local(years)

        foreach t in 10 5 1 {
            gen sharetop`t' =. 
        
            foreach y in `years' {
                replace sharetop`t' = top`t'gr/growthz if incyear == `y'
            }

            drop top`t'gr
        }
        append using test_years.dta
        save test_years.dta , replace
    }


    clear
    u test_years.dta
    collapse (max) max1 = sharetop1 max5=sharetop5 max10 = sharetop10 (min) min1 = sharetop1 min5=sharetop5 min10 = sharetop10 (p50) med1 = sharetop1 med5=sharetop5 med10 = sharetop10 , by(incyear)
    outsheet using output/year_test_shares.csv, comma names replace

    clear
    u $datafile
    gen originalquality = quality
    drop if incyear > 2012
    safedrop yearquality
    gen yearquality = .
    levelsof incyear , local(years)
    foreach y in `years' {
        di "Model for year `y'"
        replace trainingyears = incyear == `y'
        capture noisily build_model, onlymain fe(1) nopredict

        if _rc != 0 {
            continue
        }
        
        safedrop predyearquality
        predict predyearquality
        replace yearquality = predyearquality if incyear == `y'
    }

    save analysis34.qualityanalytics.dta , replace
    
    capture postclose qcorrs
    postfile qcorrs incyear qcorr using year_quality_correlations.dta , replace every(1)
    foreach y in `years' {
        di "correlation for state `y'"
         pwcorr originalquality yearquality if incyear == `y'
        if _rc == 0 & "`r(rho)'" != ""{
            di "post qcorrs (y') (`r(rho)')"
            post qcorrs (`y') (`r(rho)')
        }
        else {
            di "....Failed"
        }
        
    }
    postclose qcorrs

    clear
    u $datafile
    drop if quality == .
    keep if inrange(incyear,1988,2008)
    safedrop trainingsample

    sort rsort
    replace trainingyears = _n/_N < .3
    build_model, fe(11) onlymain 

    drop if trainingyears
    
    sort quality
    gen percentile = _n/_N
   
    gen top10gr = growthz if percentile >= .90
    gen top5gr = growthz if percentile >= .95
    gen top1gr = growthz if percentile >= .99
    
    collapse (sum) total_growth_events = growthz top1gr top5gr top10gr , by(incyear)
    merge 1:1 incyear using year_quality_correlations.dta

    list , clean noobs
    drop _merge
    outsheet using output/year_quality.csv , comma names replace
}


