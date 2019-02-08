

program define corp_add_recapitalizations, rclass
	syntax, DTApath(string) MERGERpath(string) matchvariable(string)

	u `mergerpath', replace
	rename histmergedintoid `matchvariable'
	drop if missing(`matchvariable')
	merge m:m corpnumber using `dtapath'
	drop if _merge == 1
	safedrop _merge diffmr
	gen diffmr = incdate - histmergerdate
	local originalvars   = ""
	foreach var of varlist _all {
		local originalvars = "`originalvars' othermr_`var'"  
		rename `var' origmr_`var'
	}


	rename origmr_histmergedid `matchvariable'

	* 90 days before or after
	replace `matchvariable' = "" if !inrange(origmr_diffmr,-3*30,3*30)
	drop if `matchvariable' == ""

	merge m:m `matchvariable' using `dtapath'
	drop if _merge == 1
	drop _merge
	foreach v of varlist jurisdiction incdate dataid {
		replace origmr_`v' = `v' 
	} 

	keep origmr_*

	foreach var of varlist _all {
		local newname = regexr("`var'", "origmr_","")
		rename `var' `newname'
	}


	save `dtapath',replace
end
