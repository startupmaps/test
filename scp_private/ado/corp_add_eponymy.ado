capture program drop corp_add_eponymy
program define corp_add_eponymy, rclass
	syntax,DIRECTORpath(string) DTApath(string) [nosave]
	clear
	u `directorpath'
	drop if length(fullname) < 4
	joinby dataid using `dtapath'
	
	/*Eponymy is only done on the first name the firm has, not all names, to calculate
		the characteristics at birth */
	capture confirm variable firstentityname 
	if _rc == 0 {
		keep if !missing(firstentityname)
	}
	
	replace entityname = upper(entityname)
	replace fullname = itrim(trim(upper(fullname)))
	split fullname
	rename fullname full_fullname
	safedrop _id
	gen _id = _n
	keep _id fullname1 fullname2 fullname3 fullname4 fullname5 entityname dataid
	reshape long fullname,i(_id) j(nameorder)
	drop if fullname == ""
	drop if length(fullname) < 4

	gen eponymous = strpos(entityname,fullname) > 0
	collapse (max) eponymous, by(dataid)

	merge 1:m dataid using `dtapath'
	replace eponymous = 0 if missing(eponymous)
	drop if _merge == 1
	drop _merge

	if "`nosave'" == "" {
		save `dtapath',replace
	}
	else {
		di "nosave option provided. File not saved."
	}
end
