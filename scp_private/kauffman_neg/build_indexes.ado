program define build_indexes, rclass
      syntax , [addby(string)] [skipstates(string)] [predictreai] [qualityboost(string)] [includesum(namelist)]

safedrop obs
gen obs = 1
keep if inrange(incyear,1988,2014)

if "$verbose" == "1" {
    di "############################################"
    di "--> Method build_indexes.ado Debugging"
    di "--> Existing quality variables:"
    sum quality*

    di "--> Firms with missing quality:"
    qui:sum obs if missing(quality)
    di "--> Missing quality: `r(N)'. By Year: "

    tab incyear if missing(quality)
    
    qui:sum obs if missing(qualitynow)
    di "--> Missing qualitynow: `r(N)'. By Year:"
    tab incyear if missing(qualitynow)

    di "--> End of Debugging"
    di "###########################################"
}


if "`skipstates'" != "" {
    foreach state in `skipstates' {
        di "Skipping State in build_indexes: `state' "
        drop if datastate == "`state'"
    }
}

forvalues y = 1/5 {
    safedrop growth`y'y
    gen growth`y'y = !missing(ipodate) & inrange(diffipo,0,365*`y') | !missing(mergerdate) & inrange(mergerdate,0, 365*`y')
}


qui: sum obs if missing(quality) & missing(qualitynow)
di "Dropping `r(N)' Firms with no Quality Score"
drop if missing(quality) & missing(qualitynow)
saferename incyear year

safedrop reaiquality
gen reaiquality = quality

if "`predictreai'" == "predictreai" {
        # delimit ;

    local full_model_params is_corp eponymous shortname
                  trademark patent_noDE nopatent_DE patent_and_DE 
                  clust_local  clust_resource_int clust_traded
                  is_biotech is_ecommerce is_IT is_medicaldev is_semicond ib11.statecode;

    # delimit cr

    forvalues y=2009/2012 {
        local d = 6- (`y'-2008)
        logit growth`d'y `full_model_params' if trainingsample, vce(robust) or
        safedrop x
        predict x
        replace reaiquality = x if year == `y'
      }
}



collapse (mean) quality qualitynow reaiquality qualityemp (sum) obs  growth* `includesum' realgrowth, by(year `addby')



gen recpinow = qualitynow * obs
gen recpi = quality * obs
gen recpiemp = qualityemp * obs
    
safedrop predgrowth
gen predgrowth = growthz
gen reairecpi = reaiquality *obs
gen reai = growthz/reairecpi if year <= 2012

replace reai = realgrowth/reairecpi if year >2008 & year <= 2012


recast float growthz, force


sum growthz if inrange(year,1995,2008)
local sum_growthz = `r(sum)'
forvalues  y=2009/2012 {
    local d = 2014 - `y'
    qui:sum growth`d'y if inrange(year,1995,2008)
    local augment_factor = `sum_growthz' / `r(sum)'
    replace predgrowth = predgrowth * `augment_factor' if year== `y'
}

replace predgrowth = . if year > 2012
replace recpi = . if year > 2012



/*
 * Only in the cases where this is a yearly index, append the yearly stuff
 */
if "`addby'" == "" {
    gen obs_tm1 = obs[_n-1]
    regress  obs year obs_tm1 if inrange(year, 2002,2014)
    predict pobs
    
    /*Use a predicted number of observations but realized 2015 quality*/
    replace recpinow = qualitynow * pobs if year == 2015

    merge 1:1 year using external_data_yearly.dta
    drop if _merge == 2
    drop _merge
    gen recpi_over_gdp = recpi/samplegsp
    gen bdsbirths_over_gdp = samplebdsbirths/samplegsp
}
end 
