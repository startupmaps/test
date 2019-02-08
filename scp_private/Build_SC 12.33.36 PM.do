cd ~/migration/datafiles/build_scripts/
global mergetempsuffix SC




clear

import delimited ~/projects/reap_proj/raw_data/South_Carolina/CORPORATION.TXT,delim(",") varname(1)

rename corpid dataid
rename corpname entityname


rename corporationtypecode type

save SC.dta, replace

gen is_corp = 1 if regexm(type,"CORP")
replace is_corp = 1 if type == "BUS"
replace is_corp = 0 if missing(is_corp)

gen address = agentaddress1 + agentaddress2
gen city = agentcity
rename agentstate state
rename agentzip zipcode

gen shortname = wordcount(entityname) < 4

gen jurisdiction = incstate
replace jurisdiction = "SC" if missing(jurisdiction) 
gen is_DE = 1 if regexm(jurisdiction,"DE")

gen local_firm= regexm(jurisdiction,"CAROLINA") | regexm(jurisdiction,"SC")| regexm(jurisdiction,"DE")
replace local_firm = 0 if regexm(jurisdiction,"WIS") | regexm(jurisdiction,"RHODE") | regexm(jurisdiction,"SCOT") 
replace local_firm = 0 if regexm(jurisdiction,"NOR")

/* Generating Variables */

gen incdate = date(originalfilingdate,"YMD")
gen incyear = year(incdate)

drop if missing(incdate)
drop if missing(entityname)



keep dataid entityname incdate incyear type is_DE jurisdiction zipcode state city address is_corp shortname local_firm

compress
save SC.dta,replace


**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u SC.dta , replace
	tomname entityname
	
	gen eponymous = 0
	save SC.dta, replace
	
       corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(SC.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(SC.dta)
	
	
	# delimit ;
	corp_add_trademarks SC , 
		dta(SC.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications SC SOUTH CAROLINA , 
		dta(SC.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments SC SOUTH CAROLINA , 
		dta(SC.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta"  "/projects/reap.proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 SC  ,dta(SC.dta) ipo(/projects/reap.proj/data/ipoallUS.dta)  longstate(SOUTH CAROLINA) 
	corp_add_mergers SC  ,dta(SC.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(SOUTH CAROLINA) 
