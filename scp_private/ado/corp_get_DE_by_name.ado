capture program drop corp_get_DE_by_name


program define corp_get_DE_by_name , rclass
     syntax , dta(string) [DE_dta(string)] [skip_incdate_comparison]
{
    if "`DE_dta'" == "" {
        local DE_dta = "~/projects/reap_proj/data/DE_matching_set.dta"
    }
        

    capture confirm variable rowfirmid
    safedrop __firmid
    gen __firmid = _n

    save `dta' , replace
    jnamemerge  `dta' `DE_dta'
    
    replace DE_match = 0 if missing(DE_match)

    /** The local registration should happen *after* the registration in Delaware **/
    if "`skip_incdate_comparison'" == "" {
        replace DE_match = incdate >= DE_inc_date
        replace DE_match = 0 if _mergex != "name and type"
    }
    else {
        replace DE_match = _mergex == "name and type"
    }
    gsort __firmid -DE_match
    duplicates drop __firmid, force
    drop __firmid
    gen is_DE = DE_match
    safedrop _merge _mergex
}
end
