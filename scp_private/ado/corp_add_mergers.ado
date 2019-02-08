capture program drop corp_add_mergers

program define corp_add_mergers, rclass
	syntax namelist(min=1 max=2), [DTApath(string)] [NOSave] MERGERpath(string) longstate(string) [nomatchdta(string)]  [skipcollapsed]


	local state="`1'"
	
	if "`dtapath'" == "" {
		local filepath = "/NOBACKUP/scratch/share_scp/scp_private/final_datasets/`state'.dta"
	}
	else {
		local filepath = "`dtapath'"
	}
	

	clear
	u `mergerpath'
	rename dateannounced mergerdate
	replace targetstate = upper(trim(itrim(targetstate)))
	keep if targetstate == "`longstate'"
	keep dateannounced match* mfull_name targetname enterprisevalue equityvalue
	replace enterprisevalue = "" if enterprisevalue == "np" 
	replace enterprisevalue = subinstr(enterprisevalue,",","",.)
	gen x = length(enterprisevalue) > 0
	gen mergeryear =year(date(dateannouncedstr,"MDY",2020))
	save /NOBACKUP/scratch/share_scp/temp/`state'.merger.dta,replace

	jnamemerge `filepath' /NOBACKUP/scratch/share_scp/temp/`state'.merger.dta , `skipcollapsed'
	
	/*
	if "`nomatchdta'" != "" {
		savesome if _mergex == "no match (rightfile)" using `nomatchdta'
	}
	drop if _mergex == "no match (rightfile)"
	*/
	
	
	safedrop _merge _mergex mergerdate maold
	gen mergerdate =date(dateannouncedstr,"MDY",2020)
	format mergerdate %d
	
	if "`nosave'" == "" {
		save  `filepath',replace 
	}
end
