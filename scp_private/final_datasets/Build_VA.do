cd ~/projects/reap_proj/final_datasets
global mergetempsuffix VABuild
clear
import delimited using /NOBACKUP/scratch/share_scp/raw_data/Virginia/06_20_2017/2_corporate.csv , delim(",")
gen is_corp = 1
save VA.dta ,replace

clear
import delimited using /NOBACKUP/scratch/share_scp/raw_data/Virginia/3_lp.csv , delim(",")
merge 1:1 corpid using VA.dta
drop _merge
tostring(corpzip),replace
save VA.dta, replace

clear
import delimited using /NOBACKUP/scratch/share_scp/raw_data/Virginia/9_llc.csv , delim(",")
merge 1:1 corpid using VA.dta
drop _merge

save VA.dta, replace

replace is_corp = 0 if missing(is_corp)

rename corpid dataid
rename corpname entityname


gen address = corpstreet1 + corpstreet2
gen city = corpcity
gen state = corpstate
gen zipcode = corpzip
replace zipcode = substr(zipcode,0,5)

gen shortname = wordcount(entityname) < 4

gen jurisdiction = corpstateinc
gen is_DE = jurisdiction == "DE"

gen potentiallylocal=  inlist(jurisdiction,"VA","DE")

/* Generating Variables */
tostring(corpincdate), replace
gen incdate = date(corpincdate,"YMD")
gen incyear = year(incdate)

drop if missing(incdate)
drop if missing(entityname)
gen country = "USA" if missing(corpforeign) | corpforeign == "0"
keep dataid entityname incdate incyear is_DE jurisdiction country zipcode state city address is_corp shortname country potentiallylocal
gen stateaddress = state
compress

save VA.dta,replace


/* Build Director File */
clear

import delimited /NOBACKUP/scratch/share_scp/raw_data/Virginia/06_20_2017/5_officers.csv, delim(",") varname(1)
rename mirzamyaqubvpasstsecr v1
gen dataid = upper(trim(itrim(substr(v1,1,9))))
gen lastname = upper(trim(itrim(substr(v1, 10, 15))))
replace lastname = subinstr(lastname,"."," ",.)
gen firstname = upper(trim(itrim(substr(v1, 40, 15))))
replace firstname = upper(trim(itrim(substr(v2, 25, 30)))) if !missing(v2)
replace firstname = subinstr(firstname,"."," ",.)
gen role = upper(trim(itrim(substr(v1,80,16))))
replace role = upper(trim(itrim(substr(v2, 70, 10)))) if !missing(v2)
gen fullname = firstname + " " +lastname
replace fullname = trim(itrim(fullname))
// keep if regexm(role,"PRES")  for legislator task
// drop if regexm(role,"VICE") 
// drop if regexm(role,"PAS")
// drop if missing(fullname)
keep dataid role fullname
save VA.directors_2017.dta, replace // latest data

*************
clear

import delimited /NOBACKUP/scratch/share_scp/raw_data/Virginia/04_26_2016/5_officers.csv, delim(",") varname(1)

rename dirccorpid dataid
gen fullname = dircfirstname + " " + dircmiddlename + " " + dirclastname
rename dirctitle role
// keep if regexm(role,"PRES") for legislator task
// drop if regexm(role,"VICE")
// drop if regexm(role,"PAS")

keep dataid fullname role 
drop if missing(fullname)
save /NOBACKUP/scratch/share_scp/scp_private/final_datasets/VA.directors.dta, replace

 


**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u VA.dta , replace
	tomname entityname
	save VA.dta, replace

	corp_add_eponymy, dtapath(VA.dta) directorpath(VA.directors.dta)


       corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(VA.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(VA.dta)
	
	
	# delimit ;
	corp_add_trademarks VA , 
		dta(VA.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications VA VIRGINIA , 
		dta(VA.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments  VA VIRGINIA , 
		dta(VA.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta"  "/projects/reap.proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 VA  ,dta(VA.dta) ipo(/projects/reap.proj/data/ipoallUS.dta)  longstate(VIRGINIA) 
	corp_add_mergers VA  ,dta(VA.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(VIRGINIA) 
