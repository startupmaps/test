capture program drop corp_add_vc

program define corp_add_vc,rclass
	syntax namelist, DTApath(string) [NOSave] VCpath(string) longstate(string) [nomatchlongstate]
	
	*set trace on

	local state="`1'"
	local filepath = "`dtapath'"
	
	clear
	u `vcpath'
	replace vcinvestmentstate = upper(trim(itrim(vcinvestmentstate)))
	di "filepath = `filepath'"
	di "LONGSTATE = `longstate'"

        if "`nomatchlongstate'" == "" { 
            keep if vcinvestmentstate == trim(itrim(upper("`longstate'")))
        }

	save /NOBACKUP/scratch/share_scp/temp/`state'vc.dta,replace
	
	jnamemerge `filepath' /NOBACKUP/scratch/share_scp/temp/`state'vc.dta

        safedrop _merge _mergex
       
	if "`nosave'" == "" {
		save  `filepath',replace 
	}
end
