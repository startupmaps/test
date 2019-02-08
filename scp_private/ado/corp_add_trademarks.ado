capture program drop corp_add_trademarks

program define corp_add_trademarks,rclass
	syntax name, DTAfile(string) TRADEMARKfile(string) OWNERfile(string) [STATEfileexists] [frommonths(integer 0)] [tomonths(integer 12)] var(string) [aroundyear(string)] [CLASSificationfile(string)]  [skipcollapsed] [dropexisting] [save_raw(string)]

	local state="`1'"
	local file="`dtafile'"
	di "State = `state' , File = `file'"

	capture confirm file ~/temp/`state'.trademarks.dta
	di _rc
	if "`statefileexists'" == ""  | _rc != 0{
		di "Making new temp trademark file"
		clear
		u `ownerfile'
		keep if inlist(own_addr_state_cd,"`state'")

		merge m:1 serial_no using `trademarkfile'
		drop if _merge != 3
		drop _merge
		keep serial_no registration_dt own_name
		
		if "`classificationfile'" == "" {
			collapse (min) registration_dt, by(own_name)
		} 
		else {
			merge m:m serial_no using `classificationfile'
			keep serial_no registration_dt own_name tradeclass_*
			collapse (min) registration_dt (max) tradeclass_*, by(own_name)
		}
		
		
		tomname own_name
		save ~/temp/`state'.trademarks.dta,replace
	}
	
	jnamemerge  ~/temp/`state'.trademarks.dta `dtafile' ,  `skipcollapsed'

	keep if _mergex != "no match"
	keep if !missing(registration_dt)
	
	if "`aroundyear'" == "" { 
		gen arounddate = incdate
	}
	else {
		gen arounddate = date("1/1/`aroundyear'","MDY")
	}
	
	gen diffdays = (registration_dt - arounddate)

        capture confirm variable `var'

        if _rc == 0 & "`dropexisting'" == "dropexisting" { 
	    safedrop `var'
         }        
	
	gen `var' = inrange(diffdays,`frommonths'/12*365,`tomonths'/12*365)	
        drop diffdays

	local tradeclass = ""
	if "`classificationfile'" != "" {

		foreach v of varlist tradeclass*{
			replace `v' = . if !`var'
		}
	}

        if "`save_raw'" != "" {
            di "Saving the file before collapsing into individual indicators to `save_raw'"
            save `save_raw', replace
        }

	collapse (sum) `var' `tradeclass',by(dataid)
	merge 1:m dataid using `file'
	drop if _merge == 1
	drop _merge
	save `file',replace 
end
