/*
 * This program changes the name of the firm to be its original 
 * name instead of its current name.
 */

program define corp_add_names, rclass
	syntax, DTApath(string) NAMESpath(string) [nosave]

	clear	
	u `namespath'	
	
	merge m:m dataid using `dtapath'
	by dataid (namechangeddate),sort: gen firstentityname = _n == 1
	keep if _merge == 3
	replace entityname = oldname
	safedrop _merge oldname namechangeddate
	
	append using `dtapath', force
	by dataid, sort: egen numnames = sum(1)
	replace firstentityname = 1 if numnames == 1
	replace firstentityname = 0 if missing(firstentityname)
	safedrop numnames
	
	if "`nosave'" == "" {
		save `dtapath',replace
	}
	else {
		di "nosave option provided. File not saved."
	}
	
end
 
