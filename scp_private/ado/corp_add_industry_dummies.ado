
capture confirm program drop corp_add_industry_dummies

program define corp_add_industry_dummies, rclass 
	syntax ,INDustrypath(string) DTApath(string) [dropexisting]
	
	
	u `industrypath',replace
	local industries = "" 
	foreach v of varlist use_* {
		local industries = "`industries' " + subinstr("`v'","use_","",.) 
	}

	di "Industries: `industries'"
	u `dtapath', replace
	foreach industry in `industries' {
		di "On Industry: `industry'"
		
		if "`dropexisting'" == "dropexisting" { 
			safedrop is_`industry'
		}
		
		**countinset entityname if firstentityname , wordfile(`industrypath') wordvar(coname) newvar(is_`industry') filtercol(use_`industry')
		countinset entityname , wordfile(`industrypath') wordvar(coname) newvar(is_`industry') filtercol(use_`industry')
		save `dtapath',replace
	}
		
end
