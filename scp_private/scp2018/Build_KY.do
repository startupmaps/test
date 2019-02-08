cd /NOBACKUP/scratch/share_scp/scp_private/scp2018

global mergetempsuffix KY

clear

import delimited /NOBACKUP/scratch/share_scp/raw_data/Kentucky/2018/2018_12/AllCompanies20181231.txt,delim(tab)

rename v1 dataid
rename v4 entityname

/* Non Profit */
drop if v41=="N"

save KY.dta, replace

rename v9 type
gen is_corp = 1 if regexm(type,"CO")
replace is_corp = 0 if missing(is_corp)
drop if regexm(type,"NP")

gen address = v18 + " " + v19 + " "+v20 + " "+v21
gen city = v22
gen state = v23
gen zipcode = v24

replace state = trim(itrim(state))
replace city = upper(trim(itrim(city)))
replace zipcode = trim(itrim(zipcode))
replace address = upper(trim(itrim(address)))


gen shortname = wordcount(entityname) < 4

rename v8 jurisdiction 
replace jurisdiction = "KY" if missing(jurisdiction) 
replace jurisdiction = trim(itrim(upper(jurisdiction)))
keep if inlist(jurisdiction, "DE", "KY")
gen is_DE = 1 if jurisdiction == "DE"

gen local_firm= inlist(jurisdiction,"KY","DE") | state == "KY" 

/* Generating Variables */

gen incdate = date(v28,"MDY")
gen incyear = year(incdate)

drop if missing(incdate)
drop if missing(entityname)

tostring dataid, replace
tostring v2, replace
replace dataid = dataid + v2+ substr(v3,4,2)
keep if incyear < 2019 & incyear > 1987
keep dataid entityname incdate incyear type is_DE jurisdiction zipcode state city address is_corp shortname local_firm

duplicates drop
compress
save KY.dta,replace


/* Build Director File *
clear

import delimited /NOBACKUP/scratch/share_scp/raw_data/Kentucky/2018/2018_12/AllOfficers20181231.txt , delim(tab)
save KY.directors.dta,replace

rename v4 role
keep if regexm(role,"P")


tostring v1,replace
tostring v2,replace
tostring v3,replace
gen dataid = v1 + v2 + substr(v3,4,2)
rename (v5 v6 v7) (firstname middlename lastname)

	replace lastname = subinstr(lastname,"."," ",.)
	replace lastname = subinstr(lastname,"*"," ",.)
	replace lastname = subinstr(lastname,","," ",.)
	replace lastname = upper(trim(itrim(lastname)))
	
	
	replace firstname = subinstr(firstname,"."," ",.)
	replace firstname = subinstr(firstname,"*"," ",.)
	replace firstname = subinstr(firstname,","," ",.)
	replace firstname = upper(trim(itrim(firstname)))
	
	replace middlename = subinstr(middlename,"."," ",.)
	replace middlename = subinstr(middlename,"*"," ",.)
	replace middlename = subinstr(middlename,","," ",.)
	replace middlename = upper(trim(itrim(middlename)))
	
	
	gen fullname = firstname + " " + middlename + " " + lastname
	replace fullname = trim(itrim(fullname))

keep dataid fullname role 
drop if missing(fullname)
compress
save KY.directors.dta, replace


**/
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	clear
	u KY.dta , replace
	tomname entityname
	save KY.dta ,replace
	
	corp_add_eponymy, dtapath(KY.dta) directorpath(KY.directors.dta)


       corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(KY.dta)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(KY.dta)
	
	
	# delimit ;
	corp_add_trademarks KY , 
		dta(KY.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications KY KENTUCKY , 
		dta(KY.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_applications/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	corp_add_patent_assignments KY KENTUCKY , 
		dta(KY.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_assignments/patent_assignments.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 KY  ,dta(KY.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta)  longstate(KENTUCKY) 
	
/******** Clean up merger datafile ******

use  /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers.dta , clear
rename targetprimarysiccode targetsic
destring equityvalue, replace force
drop if strpos( upper(targetname), "UNDISCLOSE")
drop if strpos( upper(targetname), "CERTAIN ASSET")
drop if strpos( upper(targetname), "CERT ASSET")
drop if strpos( upper(targetname), "CERTAIN AST")
drop if regexm( upper(targetname), "\-AST(S)*$")
drop if regexm( upper(targetname), "\-PPTY$")
collapse (min) dateannounced (max) equityvalue , by(targetname targetstate targetsic)
tomname targetname , commasplit parendrop
save /NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers_2018.dta , replace

*************/
corp_add_mergers KY  ,dta(KY.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers_2018.dta)  longstate(KENTUCKY) 
duplicates drop
save KY.dta, replace
