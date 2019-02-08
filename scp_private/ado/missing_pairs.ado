/**
 ** Author: Jorge Guzman
 **/

capture program drop missing_pairs
program define missing_pairs, rclass
    syntax varlist(min=2 max=2), [add_missing]  [quiet]

{
    local left_var  `1'
    local right_var `2'
    di "quiet = `quiet', add_missing = `add_missing'"

    
    qui levelsof `left_var', local(left_vals) clean
    qui levelsof `right_var' , local(right_vals) clean
    local all_vals_dups `left_vals' `right_vals'
    local all_vals_uniq : list uniq all_vals_dups
    local n: word count `all_vals_uniq'

    
    capture confirm numeric variable `left_var'
    local is_numeric = _rc == 0
    
    local count = 0
    forvalues i=1/`n' {
        forvalues j = 1/`n' {

            if `i' == `j' {
                /** not looking for self-pairs **/
                continue
            }
            
            local left : word `i' of `all_vals_uniq'
            local right :word `j' of `all_vals_uniq'

            if `is_numeric' == 1 {
                qui: count if `left_var' == `left' & `right_var' == `right'
            }
            else {
                qui: count if `left_var' == "`left'" & `right_var' == "`right'"
            }

            if `r(N)' == 0 {
                if "`quiet'" != "quiet" {
                    di "pair `left'- `right' not found"
                }

                if "`add_missing'" == "add_missing" {
                    local new = _N+1
                    qui: set obs `new'
                    if `is_numeric' == 1 {
                        qui replace `right_var' = `right' if _n == _N
                        qui replace `left_var'  = `left' if _n == _N
                    }
                    else {
                        qui replace `right_var' = "`right'" if _n == _N
                        qui replace `left_var'  = "`left'" if _n == _N
                    }
                    local count = `count' + 1
               }
            }
        }
        local percent = floor(`i'/`n'*100)
        /*di "`percent'% . " _continue*/
    }

    di "Added `count' new rows"
    
}
end
