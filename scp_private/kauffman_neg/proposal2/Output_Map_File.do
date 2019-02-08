/**
 **
  This code creates a new output file used to create a map of the US.
   by normalizing for each ZIP Code.
 **/


cd ~/kauffman_neg

// Define the key variables used in the script.
// While these are also defined in Master.do, this file is meant to be run
// separately.

global dataset_state_list IL WI OH NC MN NJ AR WY VA RI AZ NM ME ND IA KY UT SC CO TN VA RI ID MO OK CA FL MA WA TX NY WY AK OR GA MI VT 
global report_at_state_level NY OK WA AR OH

global datafile analysis34.minimal.dta


/** Save a file with all states and ZIP Codes **/
{
    clear
    insheet using free-zipcode-database-Primary.csv , comma names
    keep state zipcode
    tostring zipcode , replace

    forvalues i=1/4 {
        replace zipcode = "0" + zipcode if length(zipcode) < 5 & zipcode != ""
    }
    save zipcodes_with_state.dta, replace
}

/** Store a file for states aggregated at the state level **/
{
    clear
    u $datafile
    keep if inlist(datastate,"NY","OK","WA","AR","OH","VA")

    collapse (mean) quality (sum) stateobs = obs, by(datastate incyear)
    rename datastate state
    merge m:m state using zipcodes_with_state.dta
    bysort incyear zipcode: egen numzips = sum(1)
    gen obs = stateobs / numzips
    gen stabbr = state
    save state_aggregate_zipcodes.dta , replace
}


/**Create the Output File **/
{
    //Load the data
    clear
    u $datafile
    replace zipcode = trim(zipcode)
    replace zipcode = substr(zipcode,1,5)
    drop if zipcode == "" | zipcode == "."
    safedrop _merge

    //Load a state file so we only keep the ZIP Codes
    // that are *actually* in the states we want to keep
    merge m:m zipcode using zip_state
    keep if _merge == 3

    gen keepme = 0
    foreach st in $dataset_state_list {
        if inlist("`st'", "NY","OH","WA","OK","AR","VA") {
            continue
        }
        replace keepme = 1 if stabbr == "`st'" & datastate == "`st'"
    }
    keep if keepme

    //Add the state-level files
    append using state_aggregate_zipcodes

    //Keep only 2012, the year of the map 
    keep if incyear == 2012

    //Make actual indexes, addby parameters tells is to do by stabbr and zipcode
    build_indexes , addby(stabbr zipcode)
    keep zipcode recpi quality obs year stabbr growthz
    map_buckets quality
    outsheet using ~/kauffman_neg/output/Map_ZIPCodes.csv, comma names replace
}
