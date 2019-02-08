cd /projects/reap.proj/reapindex/NorthDakota


clear

import delimited /projects/reap.proj/raw_data/NorthDakota/corpa.txt,delim(tab)

save ND.dta,replace
clear

import delimited /projects/reap.proj/raw_data/NorthDakota/corpb.txt,delim(tab)

merge 1:1 v1 using ND.dta
drop if _merge == 3
drop _merge

save ND.dta,replace

gen dataid =trim(substr(v1,1,10))
gen type =trim(substr(v1,11,4))
gen date = substr(v1,29,8)
gen jurisdiction = substr(v1,37,2)
gen entityname = trim(substr(v1,39,500))
gen address = trim(substr(v1,1239,60))
gen city = substr(v1,1299,20)
gen state = substr(v1,1319,2)
gen zipcode = substr(v1,1321,5)

save ND.dta, replace

clear 
import delimited /projects/reap.proj/raw_data/NorthDakota/lplst.txt , delim(tab)

gen dataid =trim(substr(v1,1,10))
gen type = trim(substr(v1,11,4))
gen date = substr(v1,31,8)
gen jurisdiction = substr(v1,15,2)
gen entityname = trim(substr(v1,69,300))
gen address = trim(substr(v1,420,60))
gen city = substr(v1,480,20)
gen state = substr(v1,500,2)
gen zipcode = substr(v1,502,5)

merge 1:1 dataid using ND.dta
drop if _merge == 3
drop _merge
save ND.dta,replace

gen is_corp = 1 if inlist(type,"C","F","BC")

gen shortname = wordcount(entityname) < 4
gen is_DE = 1 if regexm(jurisdiction,"DE")
keep if inlist(jurisdiction,"DE","ND")
drop if jurisdiction == "DE" & state != "ND"
/* Generating Variables */

gen incdate = date(date,"YMD")
gen incyear = year(incdate)

drop if missing(incdate)
drop if missing(entityname)



keep dataid entityname incdate incyear type is_DE jurisdiction zipcode state city address is_corp shortname

compress
save ND.dta,replace
/*
No Presidents
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
*/

**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u ND.dta , replace
	tomname entityname
	
	gen eponymous = 0
	save ND.dta, replace
	
       corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(ND.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(ND.dta)
	
	
	# delimit ;
	corp_add_trademarks ND , 
		dta(ND.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications ND NORTH DAKOTA , 
		dta(ND.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments ND NORTH DAKOTA , 
		dta(ND.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta"  "/projects/reap.proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 ND  ,dta(ND.dta) ipo(/projects/reap.proj/data/ipoallUS.dta)  longstate(NORTH DAKOTA) 
	corp_add_mergers ND  ,dta(ND.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(NORTH DAKOTA) 
