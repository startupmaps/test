capture program drop multiple_match

program define multiple_match, rclass
     syntax varlist [if], samplevar(string) [limit(string)] [force(varname)] [match_id(string)]
{
    if "`match_id'" == "" {
        local match_id match_id
    }
    
    tempvar fgroups
    tempvar groups
    egen `fgroups' = group(`varlist') `if'
    safedrop tot_migrants 
    
   
    bysort `fgroups': egen tot_migrants = sum(`samplevar')
    replace `fgroups' = . if tot_migrants == 0
    egen `groups' = group(`fgroups') if `fgroups' != .

    
    if "`force'" != "" {
        local force_sort -`force'
    }

    if "`limit'" != "" {
        tempvar rand
        tempvar numsuccess
        tempvar numobs
        gen `rand' = runiform()

        gsort `groups' `force_sort' `rand'
        by `groups': gen `numobs' = _n
        by `groups': egen `numsuccess'= sum(`samplevar')
        replace `groups' = . if `numobs' > (`limit' * `numsuccess') & `samplevar' != 1
    }

    safedrop `match_id'
    egen  `match_id' = group(`groups') if `groups' != .
}
end
