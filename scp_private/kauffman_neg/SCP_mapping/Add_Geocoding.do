cd ~/kauffman_neg/

clear
foreach state in CA NY IL TX {
    di ""
    di ""
    di "******************    LOOKING AT STATE `state'   ****************"
    
    capture confirm file ~/projects/reap_proj/geocoding/`state'.geocoded.byfirm.dta
    if _rc != 0 {

        di "        File ~/projects/reap_proj/geocoding/`state'.geocoded.byfirm.dta not found"
        continue
    }

    clear
    use ~/projects/reap_proj/geocoding/`state'.geocoded.byfirm.dta
    safedrop incyear
    gen incyear = year(incdate)
    tab incyear 
    tostring dataid , replace
    gen datastate  = "`state'"
    merge m:m dataid datastate using analysis34.collapsed.dta
    

}




