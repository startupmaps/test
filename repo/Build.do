cd ~/projects/reap_proj/final_datasets/

clear
import delimited ~/projects/reap_proj/raw_data/Kentucky/2018/AllCompanies20180831.txt,delim(tab)

rename v1 dataid
rename v4 entityname

/* Non Profit */
drop if v41=="N"

rename v9 type
gen is_corp = 1 if regexm(type,"CO")

replace is_corp = 0 if missing(is_corp)
drop if regexm(type,"NP")
gen address = v18 + " " + v19 + " " + v20 + " " + v21
gen city = v22
gen state = v23
gen zipcode = v24

gen shortname = wordcount(entityname) < 4

rename v8 jurisdiction 
replace jurisdiction = "KY" if missing(jurisdiction) 
gen is_DE = 1 if regexm(jurisdiction,"DE")

keep if inlist(jurisdiction,"KY","DE")

/* Generating Variables */

gen incdate = date(v28,"MDY")
gen incyear = year(incdate)

drop if missing(incdate)
drop if missing(entityname)

tostring dataid, replace
tostring v2, replace
gen initial_dataid = dataid
replace dataid = dataid + v2+ substr(v3,4,2)
keep dataid entityname incdate incyear type is_DE jurisdiction zipcode state city address is_corp shortname

duplicates drop dataid, force
compress
drop if is_DE & state != "KY"
save KY.dta,replace


/* Build Director File */
clear

import delimited ~/projects/reap_proj/raw_data/Kentucky/AllOfficers20160430.txt , delim(tab)
save KY.directors.dta,replace

rename v4 role
keep if regexm(role,"P")


tostring v1,replace
tostring v2,replace
tostring v3,replace
gen dataid = v1 + v2 + substr(v3,4,2)

gen fullname = v5+ v6 + v7

keep dataid fullname role 
drop if missing(fullname)
compress

save KY.directors.dta, replace


**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u KY.dta , replace
	tomname entityname
	save KY.dta ,replace
	
        corp_add_eponymy, dtapath(KY.dta) directorpath(KY.directors.dta)
        corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(KY.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(KY.dta)
	
	
	# delimit ;
	corp_add_trademarks KY , 
		dta(KY.dta) 
		trademarkfile(~/projects/reap_proj/data/trademarks.dta) 
		ownerfile(~/projects/reap_proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications KY KENTUCKY , 
		dta(KY.dta) 
		pat(~/projects/reap_proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments KY KENTUCKY , 
		dta(KY.dta)
		pat("~/projects/reap_proj/data_share/patent_assignments.dta" "~/projects/reap_proj/data_share/patent_assignments2.dta"  "~/projects/reap_proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 KY  ,dta(KY.dta) ipo(~/projects/reap_proj/data/ipoallUS.dta)  longstate(KENTUCKY) 
	corp_add_mergers KY  ,dta(KY.dta) merger(~/projects/reap_proj/data/mergers.dta)  longstate(KENTUCKY) 
