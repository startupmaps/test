/*****
     This file does a merge for <INDIVIDUAL> on names. It's pretty straightforwad and does not do any fuzzy name matching

*****/

capture program drop pnamemerge

program define pnamemerge, rclass
      syntax varlist , mdta(string) mfirst(string) mlast(string)
{
    local first  `1'
    local last  `2'

    if "`first'" == "" | "`last'" == "" {
        di "ERROR: Incorrect syntax"
        exit
    }

    quietly replace `first' = itrim(trim(`first'))
    quietly replace `last' = itrim(trim(`last'))

    rename `first' `mfirst'
    rename `last' `mlast'
    joinby `mfirst' `mlast' using `mdta' , unmatched(master)

    rename (`mfirst' `mlast') (`first' `last')

    di "The current file has been matched to `mdta'"
    tab _merge
}
end
