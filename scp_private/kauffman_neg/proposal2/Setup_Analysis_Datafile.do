
local filename = "mstate.collapsed.dta"


local potentially_dropvars firstvc female male deathyeary deathdate tradeclass* hasnews is_nonprofit meanvcquality maxvcquality diffdeath femaleflag maleflag is_dead diffvc getsvc2 getsvc4 getsvc6 getsvc8 

if "$state_to_use" == "" {
    clear
    u mstate.collapsed.dta
    keep if inrange(incyear,1988,2014)

    foreach v in `potentially_dropvars' {
        di "Trying to drop `v'"
        safedrop `v'
    }
    capture drop *vcquality*
    capture drop *tradeclass*
    replace city = trim(city)
    compress
    save $datafile, replace

}
else {
    clear
    u mstate.collapsed.dta
    safedrop keepme
    gen keepme = 0
    foreach state in $dataset_state_list {
        replace keepme = 1 if datastate == "`state'"
    }
    keep if keepme
    drop keepme

    di "Rnning data with the following states "
    levelsof datastate

    keep if inrange(incyear,1988,2014)
    save $datafile, replace 
}
