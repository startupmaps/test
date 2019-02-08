capture program drop matchedsample_bylevels

program define matchedsample_bylevels , rclass
     syntax varlist , samplevar(string) levels(varlist) stringdataid dropexisting [ITERations(integer 20)]
{
    di "matching sample at the levels `levels'"

    local exactmatch `varlist'
    tempfile nomatches 
    tempfile matches
    safedrop inanalysis
    gen inanalysis = .
    save `matches' , replace
    
    foreach v of varlist `levels' {
        di "matching by `exactmatch' `v'"
        
        matchedsample `exactmatch' `v' , samplevar(`samplevar')  iter(`iterations') `dropexisting' `stringdataid'

        savesome if !inanalysis | missing(`v') using `nomatches', replace
        keep if inanalysis & !missing(`v')
        append using `matches'
        save `matches' , replace
 
        clear
        u `nomatches', replace
    }

    append using `matches'
    save `matches' , replace
 
}
end
