
capture program drop bulk_rename
program define bulk_rename,  rclass
        syntax namelist  , [add] [remove] suffix(string)
{
    di "Names: `namelist'"
    if "`add'" == "add" {
        foreach v in `namelist' {
            rename `v' `v'`suffix'
        }     
    }

    if "`remove'" == "remove" {
        foreach v in `namelist' {
            local v_new = subinstr("`v'","`suffix'","",.)
            rename `v' `v_new'
        }     

    }

}
end
