
capture program drop corp_add_patent_applications

program define corp_add_patent_applications,rclass
	syntax namelist(min=2 max=3), DTApath(string) [NOSave] PATpath(string) [frommonths(integer 0)] [tomonths(integer 12)] var(string) [STATEfileexists] [aroundyear(string)]  [skipcollapsed] [dropexisting] [save_raw(string)]

{
	local state="`1'" 
	local longstate=trim("`2' `3'")
	

	capture confirm file ~/temp/`state'.patentapp.dta

	if "`statefileexists'" == "" | _rc != 0 {
		clear
		u `patpath',replace
		keep if inlist(state,"","`state'")
		tomname assignee
		safedrop _merge _mergex
		desc
		save ~/temp/`state'.patentapp.dta,replace
	}
	
	jnamemerge   ~/temp/`state'.patentapp.dta `dtapath' ,  `skipcollapsed'

	drop if _mergex == "no match"
	safedrop _merge _mergex
	

	safedrop arounddate
	if "`aroundyear'" == "" {
		gen arounddate = incdate
	}
	else {
		gen arounddate = date("1/1/`aroundyear'", "MDY")
	}
	

	rename applicationdate patent_application_date
	gen diffdays = (patent_application_date - arounddate)


        capture confirm variable `var'
        if _rc == 0 & "`dropexisting'" == "dropexisting" {
            drop `var'
        }
        gen `var' = inrange(diffdays,`frommonths'/12*365,`tomonths'/12*365) 


        if "`save_raw'" != "" {
            di "Saving the file before collapsing into individual indicators to `save_raw'"
            save `save_raw', replace
        }


	collapse (sum) `var', by(dataid)

	merge 1:m dataid using  `dtapath'
	drop _merge 
	if "`nosave'" == "" {
		save  `dtapath',replace 
	}
}
end
