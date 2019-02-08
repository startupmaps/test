capture program drop midpoint
program midpoint, rclass
syntax varname [if]
{
    local indexvar  `varname'
    qui: sum `indexvar' `if' , detail

    return scalar midpoint=`r(p50)'
}
end

capture program drop cdf_range
program cdf_range, rclass

syntax varname [if] , weightvar(varname)
{
    local indexvar `varname'
    safedrop __x1
    qui: cumul `indexvar' `if' [w=`weightvar'] , gen(__x1)
    sum `x1' `if'
    return scalar cdf=`r(max)'
    }
end




capture program drop greweight
program define greweight , rclass
syntax , [weightvar(varname)] outcomevar(varname) indexvar(varname) [start(string)] [end(string)]   [iteration]
{

    
    
    /*** A bunch of early setup **/
    if "`iteration'" == "" {
        local weightvar __weight
        safedrop __weight
        gen __weight =1
        cumul `indexvar' if `outcomevar' == 1 , gen(cum)
        }

    if "`start'" == "" {
        qui:sum `indexvar'
        local start `r(min)'
        }

    if "`end'" == "" {
        qui: sum `indexvar'
        local end `r(max)'
        }

    midpoint `indexvar' if `outcomevar' == 1 & inrange(`indexvar',`start',`end')
    local splitpoint =  `r(midpoint)'


    /*** Get CDF Values
    *   These are by definition 1 and 1 in positive outcome group
     *
     ***/
    cdf_range `indexvar' if inrange(`indexvar',`start',`splitpoint') & `outcomevar' == 0 , weightvar(`weightvar')
    local c1 = `r(cdf)'

    cdf_range `indexvar' if inrange(`indexvar',`splitpoint', `end') & `outcomevar' == 0 , weightvar(`weightvar')
    local c2 = `r(cdf)'

    /** re-weight **/

    replace `weightvar' = `c2'/`c1' if inrange(`indexvar',`start',`splitpoint') & `outcomevar' == 0
    replace `weightvar' = `c1'/`c2' if inrange(`indexvar',`splitpoint', `end') & `outcomevar' == 0

    /** Recursive calls **/

    guzmanreweight , iteration weightvar(`weightvar') outcomevar(`outcomevar') indexvar(`indexvar') start(`start') end(`splitpoint')
    guzmanreweight , iteration weightvar(`weightvar') outcomevar(`outcomevar') indexvar(`indexvar') start(`splitpoint') end(`end')

    }

end


