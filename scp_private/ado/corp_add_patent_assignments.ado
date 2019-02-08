capture program drop corp_add_patent_assignments


program define corp_add_patent_assignments,rclass
	syntax namelist(min=2 max=3), DTApath(string) [NOSave] PATpath(string) [frommonths(integer 0)] [tomonths(integer 12)] var(string) [STATEfileexists] [aroundyear(string)] [dropexisting]  [skipcollapsed] [save_raw(string)]
{
	**** Add patents
	local pathlist = char(34) + subinstr("`patpath'"," ",char(34)+" "+char(34),.) + char(34)

	foreach x in `pathlist' {
		di "PATH: `x'"
	}

        /*** First, create a file to store to ~/temp/state.patents.dta *****/
        
	local state="`1'"
	local longstate=trim(subinstr("`2' `3'",",","",.))
	di "Long State: `longstate'"
	local first = 0 
	capture confirm file ~/temp/`state'.patents.dta
	if "`statefileexists'" == ""  | _rc != 0{
		foreach patfile in `pathlist' {
			use `patfile',replace
			keep if strpos(assignee_address,"`longstate'") > 0
			tomname assignee_name, dropexisting
			if `first' > 0 {
				append using ~/temp/`state'.patents.dta
			}
			local first = `first' + 1
			save ~/temp/`state'.patents.dta,replace
		}

                duplicates drop
                save ~/temp/`state'.patents.dta,replace
	}



        /*** Now, merge them *****/
	jnamemerge  ~/temp/`state'.patents.dta `dtapath' ,  `skipcollapsed'
	drop if _mergex == "no match"
	

        /***  Do some cleaning ***/
	*drop if length(dataid) < 3
	rename patent_date patent_date_str
	gen patent_assignment_date = date(patent_date_str,"YMD")
	
	safedrop arounddate
	if "`aroundyear'" == "" {
		gen arounddate = incdate
	}
	else {
		gen arounddate = date("1/1/`aroundyear'", "MDY")
	}
	gen diffdays = (patent_assignment_date - arounddate)

        capture confirm variable `var'
	if _rc == 0 &  "`dropexisting'" == "dropexisting" {
		drop `var'
	}
	
	gen `var' = inrange(diffdays,`frommonths'/12*365,`tomonths'/12*365)

        if "`save_raw'" != "" {
            di "Saving the file before collapsing into individual indicators to `save_raw'"
            save `save_raw', replace
        }

	collapse (sum) `var', by(dataid)

	merge 1:m dataid using `dtapath'
	drop _merge 
	
	if "`nosave'" == "" {
		save  `dtapath',replace 
	}
}
end
