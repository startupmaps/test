capture program drop corp_add_ipos

program define corp_add_ipos,rclass
	syntax namelist(min=1 max=1), [DTApath(string)] [NOSave] IPOpath(string) longstate(string) [nomatchdta(string)]  [skipcollapsed]
	
	*set trace on

	local state="`1'"
	
	if "`dtapath'" == "" {
		local filepath = "/NOBACKUP/scratch/share_scp/scp_private/final_datasets/`state'.dta"
	}
	else {
		local filepath = "`dtapath'"
	}
	
	
	clear
	u `ipopath'
	replace state = upper(trim(itrim(state)))
	di "filepath = `filepath'"
	di "LONGSTATE = `longstate'"
	keep if state == trim(itrim(upper("`longstate'")))

        gen financial_ipo = strpos(mainsic,"6") == 1
        rename businessdescription ipo_businessdescription
        keep issuedate match* mfull_name issuer financial_ipo ipo_businessdescription
	rename issuedate ipodate
	save /NOBACKUP/scratch/share_scp/temp/`state'ipo.dta,replace
 
	jnamemerge `filepath' /NOBACKUP/scratch/share_scp/temp/`state'ipo.dta , `skipcollapsed'
	
	/*
	if "`nomatchdta'" != "" {
		savesome if _mergex == "no match (rightfile)" using `nomatchdta'
	}
	drop if _mergex == "no match (rightfile)"
	*/
	
	safedrop _merge _mergex
	
	if "`nosave'" == "" {
		save  `filepath',replace 
	}
end
