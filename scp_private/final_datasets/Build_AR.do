cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets
global mergetempsuffix ARMERGE
global only_DE 0


clear 
import delimited using /NOBACKUP/scratch/share_scp/raw_data/Arkansas/corp_data.txt, delim(tab)

rename v1 dataid
tostring dataid , replace
gen  entityname = trim(v6)
rename v19 jurisdiction
replace jurisdiction = "AR" if missing(jurisdiction)
rename v2 type
drop if type == 3 | type == 4 | type == 14 | type == 23
drop if type > 25
/* 1 observation*/
duplicates drop dataid , force
gen is_corp = inlist(type,1,2,5,6,13)
replace jurisdiction = trim(jurisdiction)
gen potentiallylocal= inlist(jurisdiction,"DE","AR")

// save AR.dta, replace

rename v25 city
rename v26 state
rename v27 zipcode

gen address =trim(v23 + " " +v24)
gen fulladdress = address if missing(v24)
// fix state
replace fulladdress = trim(itrim(fulladdress))
split fulladdress, parse(",")

gen str statezip = ""
gen str cityinfo = ""
forvalues i = 6(-1)2{
	replace statezip = fulladdress`i' if !missing(fulladdress`i') & missing(statezip)
	local a = `i'-1
	replace cityinfo = fulladdress`a' if statezip == fulladdress`i' & !missing(fulladdress`i')

}

replace city = cityinfo if missing(city) | city == "X"
save AR_temp.dta, replace
forvalues i = 2(1)5{
	local a = `i' + 1
	replace fulladdress1 = fulladdress1 + " "+ fulladdress`i' if fulladdress`i' != city & fulladdress`a' != statezip &!missing(fulladdress`i') & !missing(fulladdress`a')
	}
replace address = fulladdress1 if !missing(fulladdress1)
replace city = upper(trim(itrim(city)))

replace statezip = trim(itrim(statezip))
split statezip, parse(" ")

replace statezip1 = trim(itrim(statezip1))
replace statezip2 = trim(itrim(statezip2))

replace state = statezip1 if strlen(statezip1) == 2 & missing(state)
replace state = "AR" if missing(state) & jurisdiction == "AR"
// fix zip
split statezip2, parse("-")

replace zipcode = statezip21 if strlen(statezip21) == 5  & missing(zipcode) & regexm(statezip2, "[0-9][0-9][0-9][0-9][0-9]")
replace zipcode = substr(zipcode,1,5)
replace zipcode = "" if regexm(zipcode, "[a-zA-Z]") | regexm(zipcode, " ") | regexm(zipcode, "-") |strlen(zipcode)!=5
replace zipcode = trim(itrim(zipcode))
destring zipcode, gen(zip5) force

replace state = "AR" if inrange(zip5,85001 ,86556)
replace state = trim(itrim(state))


replace zipcode = trim(itrim(zipcode))
replace address = upper(trim(itrim(address)))

gen stateaddress = state
gen shortname = wordcount(entityname) < 4
gen is_DE  = 1 if jurisdiction == "DE"
replace is_DE = 0 if missing(is_DE)
gen incdate = date(v4,"MDY")
gen incyear = year(incdate)




drop if missing(incdate)
drop if missing(entityname)




keep dataid entityname incdate incyear is_DE jurisdiction zipcode state city address is_corp shortname potentiallylocal stateaddress

compress

if $only_DE == 1 {
    keep if is_DE == 1
}

save AR.dta, replace

/* Build Director File */
clear

import delimited /NOBACKUP/scratch/share_scp/raw_data/Arkansas/corp_officer_data.txt, delim(tab)
save AR.directors.dta,replace

tostring v1 , generate(dataid)
gen role = trim(v4)

rename (v9 v10 v8) (firstname middlename lastname)

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
	

keep if inlist(role,"President")

keep dataid fullname role 
drop if missing(fullname)
save AR.directors.dta, replace


**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u /NOBACKUP/scratch/share_scp/scp_private/final_datasets/AR.dta , replace
	
	tomname entityname
	save /NOBACKUP/scratch/share_scp/scp_private/final_datasets/AR.dta, replace

	corp_add_eponymy, dtapath(/NOBACKUP/scratch/share_scp/scp_private/final_datasets/AR.dta) directorpath(/NOBACKUP/scratch/share_scp/scp_private/final_datasets/AR.directors.dta)


       corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(/NOBACKUP/scratch/share_scp/scp_private/final_datasets/AR.dta)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(/NOBACKUP/scratch/share_scp/scp_private/final_datasets/AR.dta)
	
	
	# delimit ;
	corp_add_trademarks AR , 
		dta(/NOBACKUP/scratch/share_scp/scp_private/final_datasets/AR.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications AR ARKANSAS , 
		dta(/NOBACKUP/scratch/share_scp/scp_private/final_datasets/AR.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments  AR ARKANSAS , 
		dta(AR.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/patent_assignments.dta" "/NOBACKUP/scratch/share_scp/ext_data/patent_assignments2.dta"  "/NOBACKUP/scratch/share_scp/ext_data/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 AR  ,dta(/NOBACKUP/scratch/share_scp/scp_private/final_datasets/AR.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta)  longstate(ARKANSAS)
	corp_add_mergers AR  ,dta(/NOBACKUP/scratch/share_scp/scp_private/final_datasets/AR.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/mergers.dta)  longstate(ARKANSAS) 

	corp_add_vc        AR ,dta(/NOBACKUP/scratch/share_scp/scp_private/final_datasets/AR.dta) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(ARKANSAS)
      
	save /NOBACKUP/scratch/share_scp/migration/datafiles/AR.dta, replace //do the migration
