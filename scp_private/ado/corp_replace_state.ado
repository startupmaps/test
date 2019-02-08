program define corp_replace_state , rclass
    syntax , analysisdta(string) replacedta(string) datastate(string) [add]
{
    clear
    u `analysisdta'
    if "`add'" == "" { 
        qui: sum is_corp if datastate== "`datastate'"

        if `r(N)' == 0 {
            di " **** ERROR ******"
            di "   Does not have "
            stop here
        }
    }
    
    drop if datastate == "`datastate'"
    save `analysisdta', replace

    
    clear
     use `replacedta'
    capture confirm datastate
    if _rc != 0 {
        gen datastate = "`datastate'"
    }

    tostring dataid , replace
    append using `analysisdta'
    save `analysisdta' , replace
}
end
