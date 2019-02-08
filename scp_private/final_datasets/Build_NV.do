
cd /projects/reap.proj/reapindex/Nevada
global mergetempsuffix NV

clear

import delimited /projects/reap.proj/raw_data/Nevada/Corporations.Crprtn.36579.051616112545.csv,delim(",")

rename v1 dataid
rename v7 entityname

/* Non Profit and others*/
drop if inlist(v4,"Mark","Other","Reserved Name","Corp Sole")
rename v3 type
drop if regexm(type,"Non-Profit")
gen is_corp = 1 if regexm(v4,"Corporation")

save NV.dta, replace

rename v8 jurisdiction 
replace jurisdiction = "NV" if missing(jurisdiction) 
gen is_DE = 1 if regexm(jurisdiction,"DE")

gen potentiallylocal =  inlist(jurisdiction,"NV","DE")

gen address = v16
gen city = v18
gen state = v19
gen zipcode = v20

gen shortname = wordcount(entityname) < 5

/* Generating Variables */

gen incdate = date(v22,"MDY")
gen incyear = year(incdate)

drop if missing(incdate)
drop if missing(entityname)

keep dataid v2 entityname incdate incyear type is_DE jurisdiction is_corp shortname potentiallylocal address city zipcode state
gen stateaddress = state

save NV.dta,replace
/*
clear

import delimited /projects/reap.proj/raw_data/Nevada/Corporations.RsdnAgn.36579.051616112545.csv,delim(",")

keep dataid entityname incdate incyear type is_DE jurisdiction zipcode state city address is_corp shortname

compress
save NV.dta,replace
*/

/* Build Director File */
clear

import delimited /projects/reap.proj/raw_data/Nevada/Corporations.CrprtOffc.36579.051616112545.csv,delim(",")
rename v3 role
keep if regexm(role,"Pre")


rename v1 dataid
gen fullname = v5+" "+v6 + " "+v4

keep dataid fullname role 
drop if missing(fullname)
compress
save NV.directors.dta, replace


**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u NV.dta , replace
	tomname entityname
	save NV.dta ,replace
	
	corp_add_eponymy, dtapath(NV.dta) directorpath(NV.directors.dta)

       corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(NV.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(NV.dta)
	
	
	# delimit ;
	corp_add_trademarks NV , 
		dta(NV.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications NV NEVADA , 
		dta(NV.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments NV NEVADA , 
		dta(NV.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta"  "/projects/reap.proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 NV  ,dta(NV.dta) ipo(/projects/reap.proj/data/ipoallUS.dta)  longstate(NEVADA) 
	corp_add_mergers NV  ,dta(NV.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(NEVADA) 
