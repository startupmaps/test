



    /******************************/
    /* Scripts to build map files */



capture program drop build_address_map_file
program define build_address_map_file, rclass
     syntax namelist(min=1 max=1)
{
    local state `1'

    capture confirm file /NOBACKUP/scratch/share_scp/geocoded/dta/`state'.geocoded.bypoint.dta

    if _rc == 0 {
        clear
        capture u /NOBACKUP/scratch/share_scp/geocoded/dta/`state'.geocoded.bypoint.dta
        if _rc == 0 {
            
            save /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/`state'_address.dta , replace
        }
        else {

        }
    }

}
end


capture program drop build_city_map_file
program define build_city_map_file , rclass
    syntax namelist(min=1 max=1) , [refresh] [usetext(string)]
{
    local state `1'


    capture confirm file  /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/`state'_cities_lat_lon.dta
    if _rc != 0  | "`refresh'" == "refresh" {
        di "begin geocoding for `state' "
        clear
        u /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/analysis34.minimal.dta
        keep if datastate == "`state'"
        safedrop obs
        gen obs = 1
        drop if quality ==.
        replace city = itrim(trim(upper(city)))
        collapse (sum) obs , by(city)

        di "Di distribution of cities"
        sum obs
        keep if (obs > 50 )
        gen state = "`state'"
        opencagegeo , key("381ff451c2fe760725ffac6085b16f20") city(city) state(state)
        
        drop obs

        // Just keep the ones matched at the city level
        keep if g_quality == 3
        save /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/`state'_cities_
_lon.dta , replace
    }

    //Loads from a text file that geocoded through a python script
    if "`usetext'" != "" {
        clear
        import delimited id blank add g_lat g_lon  using /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/outfile.txt 

        keep id g_lat g_lon
        duplicates drop
        
        merge 1:1 id using /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/map_cities.dta 
        keep if _merge == 3
        drop _merge
        keep if datastate  == "`state'"
        rename datastate state
        safedrop blank id
        drop if g_lat ==. | g_lon == .
        save /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/`state'_cities_lat_lon.dta , replace

        local N=_N
        di "`N' cities geocoded"
        
    }

    clear
    u /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/analysis34.minimal.dta
    keep if datastate == "`state'"
    safedrop obs
    gen obs = 1
    replace city = itrim(trim(upper(city)))

    collapse (sum) obs growthz (mean) quality , by(city incyear)
    replace city = upper(city)
    gen state = "`state'"
    gen recpi = quality * obs
    gen reai = growthz/recpi

    /** Just drop all cities that are blank **/
    // TO DO: Potentially there could be a better approach
    drop if city == ""
    merge m:1 city using /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/`state'_cities_lat_lon.dta
    keep if _merge == 3
    drop _merge     

    local N = _N
    
    /** this process drops all cities that are clearly not in the state **/
    quietly {
        foreach coordvar in latitude longitude {
            capture confirm variable `coordvar'
            if _rc != 0 {
                continue
            }
            
            winsor `coordvar', gen(clean`coordvar') p(.02) highonly
            sum clean`coordvar'
            local top = `r(mean)' + 4 * `r(sd)'
            local bottom = `r(mean)' - 4 * `r(sd)'
            drop if `coordvar' != . & (`coordvar' > `top'  | `coordvar' < `bottom')
        }
    }

    local N_final  = _N
    di "We have a total of `N' cities in `state' before dropping the outer ones. "
    di "We ended up with `N_final'"

    return scalar tot = `N_final'


    //Some bad Cities to Drop
    gen l = length(city)
    drop if l < 2
    save /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/`state'_cities.dta , replace
}
end


capture program drop output_agg_by_state_file
program define output_agg_by_state_file, rclass
    syntax namelist
{
    clear
    u /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/analysis34.minimal.dta
    drop if incyear == .
    collapse (mean) quality (sum) obs, by(datastate incyear)
    rename datastate _stateabbr
    merge m:1 _stateabbr using /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/State_lat_lon.dta
    keep if _merge == 3
    drop _merge
    rename _stateabbr stateabbr
    encode stateabbr, gen(statecode)
    sort quality
    gen percentile = floor(_n/_N*1000)
    replace percentile = 999 if percentile == 1000
    replace percentile = percentile +1 
    rename percentile qp
    rename obs o
    safedrop stateabbr quality

    reshape wide o qp , i(statecode) j(incyear)
    save /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/allstates_states.dta , replace
    outsheet using /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/output/geocode/agg_by_state.csv , comma names replace noquote 
}
end


capture program drop  create_empty_county_file
program define create_empty_county_file , rclass
     syntax namelist(min=1 max=1)
{
    local state `1'
    
    clear
    u /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/countylist.dta
    keep if state == "`state'"

    forvalues y=1988/2014 {
        gen reai_`y' = ""
    }
    save /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/`state'_counties.dta , replace
}
end



capture program drop build_county_map_file
program define build_county_map_file , rclass
    syntax namelist(min=1 max=1)
{
    local state `1'
    clear
    u /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/analysis34.minimal.dta
    keep if datastate == "`state'"

    /** If this data does not exist, create emply county file **/
    if _N == 0 {
        create_empty_county_file `state'
        exit
    }
    
    safedrop _merge
    merge m:m zipcode using /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/county_zipcode.dta 

    keep zipcode county bus_ratio quality incyear growthz
    tostring county, replace
    replace county = "0" + county if length(county) == 4
    
    gen obs = 1
    replace obs = obs *bus_ratio
    replace growthz = growthz *bus_ratio

    collapse (sum) obs growthz (mean) quality , by(county incyear)

    rename county countycode
    rename incyear year

    drop if year == .

    gen recpi = obs * quality
    gen raw_reai = growthz/recpi
    replace raw_reai = . if year  > 2008
    gen reai =  raw_reai * 100
    replace reai = 1 if reai == 0
    
    keep  countycode year reai
    reshape wide reai , i (countycode) j(year)
    drop if countycode == ""
    rename reai* reai_*
    gen statefp = substr(countycode,1,2)
    gen countyfp = substr(countycode,3,3)

    merge 1:1  statefp countyfp using /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/countylist.dta 
    keep if state == "`state'"
    foreach v of varlist reai* {
        tostring `v', replace force
        replace  `v' = "" if `v' == "."
    }
    save /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/`state'_counties.dta , replace
    

}
end

capture program drop  build_all_states_map_file
program define build_all_states_map_file  , rclass
{

    clear
    u /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/analysis34.minimal.dta

    safedrop obs
    gen obs=  1
    collapse (sum) growthz  obs recpi = quality , by(incyear datastate)
    gen reai = growthz/recpi if incyear <= 2008
    rename (incyear datastate) (year state)
    drop growthz
    save /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/by_state.dta , replace


}
end



         /**************************/
         /* Script to output files */
         /**************************/

capture program drop output_all_states_file
program define output_all_states_file , rclass
{
    clear
    u /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/by_state.dta
    outsheet using /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/output/geocode/all_states_by_state.csv , comma names replace noquote
}
end

capture program drop output_files
program define output_files, rclass
     syntax  namelist , file_suffix(string) [replace]

{
    local statelist `namelist'

    foreach state in `statelist' {
        capture confirm file /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/`state'`file_suffix'
        if _rc != 0 {

            di "Creating blank file /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/`state'`file_suffix'"
            clear
            gen blank = ""
            save /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/`state'`file_suffix', replace
        }
    }
    
    
    clear
    u /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/allstates`file_suffix'
    safedrop reai_2015
    safedrop _merge

    if "`file_suffix'" == "_counties.dta" {
        order countycode datastate state statefp countyfp countyname
        replace countycode = statefp + countyfp if countycode == ""
    }
    
    foreach state in `statelist' {

        local csv = subinstr("`state'`file_suffix'", ".dta",".csv",.)
        outsheet if datastate == "`state'" using /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/output/geocode/`csv' , replace comma noquote
    }

    local csv = subinstr("`state'`file_suffix'", ".dta",".csv",.)
    outsheet using /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/output/geocode/allstates`csv' , replace comma noquote

}
end


capture program drop  append_all_states
program define append_all_states , rclass
    syntax namelist , file_suffix(string)  [failonerror]
{
    local statelist `namelist'

    foreach state in `statelist' {
        capture confirm file /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/`state'`file_suffix'
        if _rc != 0 {
            clear
            gen blank = ""
            save /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/`state'`file_suffix', replace
        }
    }
    
    
    clear
    gen state = ""
    save /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/allstates`file_suffix',  replace
    foreach state in `statelist' {
        di "Adding State `state' to file allstates`file_suffix'"
        clear
         u /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/`state'`file_suffix'
        capture rename incyear year
        safedrop datastate
        gen datastate = "`state'"

       
        capture confirm variable g_lat
        if _rc == 0 {
            rename g_lat latitude
        }

        capture confirm variable g_lon
        if _rc == 0 {
            rename g_lon longitude
        }

        append using /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/allstates`file_suffix'
        save /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/allstates`file_suffix' , replace
        
	*if _N > 0 {
            *tabstat latitude longitude ,by(datastate)
        *}
    }
 

   /* Drop the duplicates in the same lat/lon in cities */
    if "`file_suffix'" == "_cities.dta" {
        save /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/allstates_cities.complete.dta , replace
        safedrop keepme point
        egen point = group(latitude longitude)
        bysort point city datastate: egen totobs = sum(obs)        
        bysort point: egen maxobs = max(totobs)
        keep if maxobs == totobs
        gsort -totobs
        duplicates drop point year, force
        save /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/allstates`file_suffix' , replace
    }

}
end

capture program drop add_quality_percentiles
program define add_quality_percentiles , rclass
     syntax namelist , file_suffix(string) [keep(namelist)]

{

    local statelist $statelist
    use /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/allstates`file_suffix' , replace

    local before_quality =subinstr("`file_suffix'", ".dta",".before_quality.dta",.)
    save /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/allstates`before_quality' , replace

    /** Add Quality Percentiles **/
    sort quality


    capture confirm variable num_observations
    if _rc == 0 {
        rename num_observations obs
    }

    //just make sure to remove all this missign stuff
    drop if year > 2012
    
    safedrop quality_percentile_global quality_percentile_yearly quality_percentile_state
    gen  quality_percentile_global = floor((_n-1)/_N*1000)
    replace quality_percentile_global = quality_percentile_global +1 
    bysort year (quality): gen quality_percentile_yearly= floor((_n-1)/_N * 1000)
    replace quality_percentile_yearly = quality_percentile_yearly +1
    
    drop if obs == .

    /** Keep only the main one **/
    bysort  datastate latitude longitude: egen num_in_state = sum(obs)
    bysort  latitude longitude: egen num_max = max(num_in_state)
    keep if num_in_state == num_max

    /** there are a few duplicates remaining, they are too small, too few and do not matter, just force to kill one **/
    safedrop keepme
    bysort latitude longitude: gen keepme = datastate == datastate[1]
    keep if keepme
    drop keepme
    rename (obs quality_percentile_global quality_percentile_yearly) (o qg qy)
    safedrop id
    egen id = group(latitude longitude)
    drop if latitude == . | longitude == . | year < 1988
    keep datastate id year lat lon o qg qy `keep'


    
    reshape wide o qg qy , i(id) j(year)

    foreach v of varlist o* qy* qg* {
        tostring `v' , replace force
        // the value of 0 means no value in the map
        replace `v' = "0" if `v' == "."
    }

    order id datastate `keep' latitude longitude 

    save /NOBACKUP/scratch/share_scp/scp_private/kauffman_neg/SCP_mapping/dta/allstates`file_suffix' , replace
 }
end

// This program reshapes the data in a wide format that is best for
// mapping in mapbox.
capture program drop reshape_wide
program define reshape_wide , rclass
         syntax namelist , file_suffix(string) 
{
//    use ~/ka
}
end

capture program drop print_data_statistics
program define print_data_statistics
{
    //nothing here yet
}
end
