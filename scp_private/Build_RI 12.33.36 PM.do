cd /projects/reap.proj/reapindex/RhodeIsland

global mergetempsuffix RIFiles

clear
import delimited data using /projects/reap.proj/raw_data/Rhode/entities_active.txt,delim(tab)




rename data dataid

gen address = businessaddr1 + businessaddr2 
gen city = businesscity
gen addrstate = businessstate
gen zip5 = businesszip

replace address = mailingaddr1 + mailingaddr2 if missing(address)
replace city = mailingcity if missing(city)
replace addrstate = mailingstate if missing(addrstate)
replace zip5 = mailingzip if missing(zip5)

gen country = countryofincorp
gen jurisdiction = stateofincorp
replace country = "USA" if missing(country)
replace jurisdiction = "RI" if missing(jurisdiction) & country =="USA"
gen is_DE = jurisdiction == "DE"


drop if charter == "Domestic Non-Profit Corporation"
drop if charter == "Foreign Non-Profit Corporation"

gen is_corp = regexm(charter,"Corporation")
/* Generating VarCTbles */

gen incdate = date(dateoforganization,"MDY")
gen incyear = year(incdate)

drop if missing(incdate)
drop if missing(entityname)

gen shortname = wordcount(entityname) < 4
keep dataid entityname incdate incyear charter is_DE jurisdiction country zip5 addrstate city address is_corp shortname

gen potentiallylocal= inlist(jurisdiction,"DE","RI")
gen local_firm = potentiallylocal
compress
rename zip5 zipcode
rename addrstate state

save RI.dta,replace

/* Build Director File */
clear

import delimited data using /projects/reap.proj/raw_data/Rhode/officers_active.txt
save RI.directors.dta,replace

rename data dataid
gen fullname = firstname + middlename + lastname 
rename individualtitle role
keep if strpos(role,"PRESIDENT") | strpos(role,"MANAGER")
drop if strpos(role,"VICE")

keep dataid fullname role 
save RI.directors.dta, replace


**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u RI.dta , replace
	tomname entityname
	save RI.dta, replace

	corp_add_eponymy, dtapath(RI.dta) directorpath(RI.directors.dta)


       corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(RI.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(RI.dta)
	
	
	# delimit ;
	corp_add_trademarks RI , 
		dta(RI.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications RI RHODE ISLAND , 
		dta(RI.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
/* 163 Observations */	
	corp_add_patent_assignments  RI RHODE ISLAND , 
		dta(RI.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta"  "/projects/reap.proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 RI  ,dta(RI.dta) ipo(/projects/reap.proj/data/ipoallUS.dta)  longstate(RHODE ISLAND) 
	corp_add_mergers RI  ,dta(RI.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(RHODE ISLAND) 

