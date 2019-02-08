cd /projects/reap.proj/reapindex/Utah

global mergetempsuffix UT

clear

import delimited /projects/reap.proj/raw_data/Utah/busentity.csv,delim(",")

rename entityid dataid
rename businessname entityname


rename entitytype type

drop if inlist(type,"Name Reservation","Trademark","Certification Authority","Commercial Registered Agent","DBA")
drop if inlist(type,"Business Trust","Collection Agency")

drop if regexm(licensetype,"Non-Profit")

save UT.dta, replace

gen is_corp = 1 if type == "Corporation"
replace is_corp = 0 if missing(is_corp)
replace address = address + address2

duplicates drop dataid, force
gen shortname = wordcount(entityname) < 4

gen jurisdiction = homestate
replace jurisdiction = "UT" if missing(jurisdiction) 
gen is_DE = jurisdiction == "DE"

gen local_firm = inlist(jurisdiction,"UT","DE")

/* Generating Variables */

gen incdate = date(registrationdate,"YMD")
gen incyear = year(incdate)

drop if missing(incdate)
drop if missing(entityname)

keep dataid entityname incdate incyear type is_DE jurisdiction zipcode state city address is_corp shortname local_firm 

compress
tostring dataid , replace
save UT.dta,replace

/* Build Director File */
clear

import delimited /projects/reap.proj/raw_data/Utah/principal.csv,delim(",") varname(1)
save UT.directors.dta,replace


rename entityid dataid

rename memberposition role
keep if regexm(role,"President")
drop if regexm(role,"Vice")

keep dataid fullname role 
drop if missing(fullname)
compress
save UT.directors.dta, replace


**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u UT.dta , replace
	tomname entityname
	save UT.dta, replace

	corp_add_eponymy, dtapath(UT.dta) directorpath(UT.directors.dta)


	
       corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(UT.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(UT.dta)
	
	
	# delimit ;
	corp_add_trademarks UT , 
		dta(UT.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications UT UTAH , 
		dta(UT.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments  UT UTAH , 
		dta(UT.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta"  "/projects/reap.proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 UT  ,dta(UT.dta) ipo(/projects/reap.proj/data/ipoallUS.dta)  longstate(UTAH) 
	corp_add_mergers UT  ,dta(UT.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(UTAH) 
