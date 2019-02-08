/**
 *
 * build county population estimates
 */
{
    * add estimates from 2000-2010
    clear
    import delimited using RJ/co-est00int-tot.csv , delim(",") varnames(1)
    tostring state , replace
    tostring county, replace

    *drop totals for state
    drop if county == 0
    
    replace state = "0" + state if length(state) == 1
    replace county = "0" + county if length(county) == 2
    replace county = "00" + county if length(county) == 1
    gen fips = state + county
    drop state county
    rename fips county
    keep county popestimate*
    reshape long popestimate , i(county) j(year)
        destring county, replace
    * we will use 2010 from next file
    drop if year == 2010
    save RJ/countypop.dta , replace

    * add estimates 2010-2015
    clear
    import delimited using RJ/co-est2015-alldata.csv , delim(",") varnames(1)
    tostring state , replace
    tostring county, replace

    *drop totals for state
    drop if county == 0
    
    replace state = "0" + state if length(state) == 1
    replace county = "0" + county if length(county) == 2
    replace county = "00" + county if length(county) == 1
    gen fips = state + county
    drop state county
    rename fips county
    keep county popestimate*
    reshape long popestimate , i(county) j(year)
    
    destring county, replace
    append using RJ/countypop.dta
    save RJ/countypop.dta , replace

}

/**
 *
 * A sample of all counties
 */
{
    cd ~/kauffman_neg
    
    clear
    u analysis34.minimal.dta
    replace zipcode = "0" + zipcode if datastate == "ME"

 
    safedrop _merge

    * Add county codes for all firms
    merge m:m zipcode using county_zipcode.dta
    keep if _merge == 3
    drop _merge

    * Some stuff to make sure the data is clean
    merge m:1 county using RJ/counties.dta
    keep if _merge
    keep if datastate == stateabbr

    rename year incyear
    * add populatio values
    merge     
    *Build the right data
    replace growthz = growthz * bus_ratio
    safedrop obs
    gen obs = bus_ratio
    collapse (sum) obs growthz (mean) quality , by(county incyear)
    gen recpi = obs * quality
    gen reai = growthz/ (obs * quality)
    sort reai
    merge m:1 county using RJ/counties.dta
    drop if _merge == 2
    gen trust_data = obs >= 1000

    sort reai
    gen global_percentile_reai = _n/_N

    sort quality
    gen global_percentile_quality = _n/_N

    sort obs
    gen cumobs = sum(obs)
    egen totobs = sum(obs)
    gen global_wpct_obs = cumobs/totobs

    bysort county (incyear):gen ycumobs = sum(obs)
    bysort county (incyear): egen ytotobs = sum(obs)

    gen yearly_wpct_obs = ycumobs/ytotobs

    safedrop _merge
    * Add population
    gen year = incyear
    merge 1:1 year county using RJ/countypop.dta
    drop if _merge == 2
    drop _merge

    gen obs_pop = obs/popestimate

    gen haspop = pop != .
    bysort haspop (obs_pop):gen global_percentile_obs_pop = _n/_N
    replace global_percentile_obs_pop = . if obs_pop == .
    
    * Store in the correct format
    save RJ/all_counties_reai_quality_recpi.dta , replace
    order incyear county stateabbr statecode countyname obs quality recpi obs reai trust_data global_percentile_reai global_percentile_quality  global_wpct_obs yearly_wpct_obs
    keep incyear county stateabbr statecode countyname obs quality recpi obs reai trust_data global_percentile_reai  global_percentile_quality global_wpct_obs yearly_wpct_obs
    outsheet using output/RJ/all_counties_reai_quality_recpi.allyears.csv , replace comma names
    
}
