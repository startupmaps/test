capture program drop corp_add_vc_time_bounded

/***
-- Script to re-Build the Dataset

clear
import delimited using "/home/jorgeg/projects/reap_proj/raw_data/VentureCapital/USVC.csv", delim("|") varnames(1)
keep companyname investmentdate companystateregion dealvalueusdmil equityamountusdmil valuationattransactiondateusdmil naiccode siccode allinvestorfirms

rename valuationattransactiondateusdmil valuationusdmil

foreach v of varlist investmentdate dealvalueusdmil equityamountusdmil valuationusdmil allinvestorfirms {
    di "splitting `v'"
    split `v' , parse("\n")
     rename `v' full_`v'
}

gen id = _n
reshape long investmentdate dealvalueusdmil equityamountusdmil valuationusdmil allinvestorfirms , i(id) j(roundnumber) 

drop full_*

drop if equityamountusdmil == "" & investmentdate == ""
replace equityamountusdmil  = subinstr(equityamountusdmil,",","",.)
destring equityamountusdmil,  gen(vc_investment_equity) force

drop roundnumber
gen vc_event_date = date(investmentdate,"MDY")
format vc_event_date %d
drop if vc_event_date == .
bysort id (vc_event_date): gen roundnumber = _n
tomname companyname
save ~/final_datasets/VX_all_investments.dta , replace

**/


program define corp_add_vc_time_bounded, rclass
	syntax , DTApath(string) [NOSave] [VCpath(string)] state(string) longstate(string) frommonths(integer) tomonths(integer) var_num_events(string) var_equity_amount(string)
{	
    if  "`vcpath'" == "" {
        local vcpath ~/final_datasets/VX_all_investments.dta 
    }


    local filepath = "`dtapath'"
    
    clear
    u `vcpath'
    replace companystateregion = upper(trim(itrim(companystateregion)))
    di "filepath = `filepath'"
    di "LONGSTATE = `longstate'"
    
    if "`nomatchlongstate'" == "" { 
        keep if companystateregion == trim(itrim(upper("`longstate'")))
    }
    
    save ~/temp/`state'vc_a.dta,replace
    
    jnamemerge `filepath' ~/temp/`state'vc_a.dta

    safedrop _merge _mergex
    gen months_to_event = month(vc_event_date) - month(incdate) + 12*(year(vc_event_date) - year(incdate))
    keep if inrange( months_to_event , `frommonths' , `tomonths')


    if _N >  0 { 

        gen num_vc_investments = 1
        collapse (sum) `var_num_events'=num_vc_investments `var_equity_amount'=vc_investment_equity, by(dataid )
        
        merge 1:m dataid using `filepath'
        drop if _merge == 1
        drop _merge 
        save  `filepath', replace 
    
    }
    else {
        clear
        u `filepath'
        gen `var_num_events' = 0
        gen `var_equity_amount' = .
        save `filepath' , replace
    }
}

end
