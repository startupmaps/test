cd /NOBACKUP/scratch/share_scp/scp_private/scp2018
global mergetempsuffix VABuild
clear
import delimited using /NOBACKUP/scratch/share_scp/raw_data/Virginia/2018/Corp.csv, delim(",")
gen is_corp = 1
save VA.dta ,replace

clear
import delimited using /NOBACKUP/scratch/share_scp/raw_data/Virginia/2018/LP.csv , delim(",")
merge 1:1 entityid using VA.dta, force
drop _merge
tostring(zip),replace
save VA.dta, replace

clear
import delimited using /NOBACKUP/scratch/share_scp/raw_data/Virginia/2018/LLC.csv , delim(",")
merge 1:1 entityid using VA.dta, force
drop _merge

save VA.dta, replace

replace is_corp = 0 if missing(is_corp)

rename entityid dataid
rename name entityname
rename zip zipcode

gen address = street1
replace address = street1 + " " + street2 if !missing(street2)

replace zipcode = substr(zipcode,0,5)

gen shortname = wordcount(entityname) < 4

gen jurisdiction = incorpstate
gen is_DE = jurisdiction == "DE"

gen potentiallylocal=  inlist(jurisdiction,"VA","DE")

/* Generating Variables */
tostring(incorpdate), replace
gen incdate = date(incorpdate,"YMD")
gen incyear = year(incdate)

drop if missing(incdate)
drop if missing(entityname)
// gen country = "USA" if missing(corpforeign) | corpforeign == "0"
keep dataid entityname incdate incyear is_DE jurisdiction zipcode state city address is_corp shortname potentiallylocal

replace entityname = upper(trim(itrim(entityname))
replace state = trim(itrim(state))
replace city = upper(trim(itrim(city)))
replace zipcode = trim(itrim(zipcode))
replace address = upper(trim(itrim(address)))

gen stateaddress = state
compress

save VA.dta,replace


/* Build Director File */
clear
import delimited /NOBACKUP/scratch/share_scp/scp_private/scp2018/raw_data/Virginia/Officer.csv, delim(",") varname(1)
rename entityid dataid
rename officerlastname lastname
replace lastname = subinstr(lastname,"."," ",.)
replace lastname = trim(itrim(lastname))

rename officerfirstname firstname
replace firstname = subinstr(firstname,"."," ",.)
replace firstname = trim(itrim(firstname))

rename officermiddlename middlename
replace middlename = subinstr(middlename,"."," ",.)
replace middlename = trim(itrim(middlename))

gen fullname = firstname + " " + middlename + " " + lastname

rename officertitle role
replace role = upper(trim(itrim(role)))
replace fullname = trim(itrim(fullname))

**** for legislator use, comment below 4 lines
keep if regexm(role,"PRES") 
drop if regexm(role,"VICE") 
drop if regexm(role,"PAS")
drop if missing(fullname)

keep dataid role fullname
save VA.directors.dta, replace

 


**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
clear
	u VA.dta , replace
	tomname entityname
	save VA.dta, replace

	corp_add_eponymy, dtapath(VA.dta) directorpath(VA.directors.dta)


       corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(VA.dta)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(VA.dta)
	
	
	# delimit ;
	corp_add_trademarks VA , 
		dta(VA.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications VA VIRGINIA , 
		dta(VA.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_applications/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments  VA VIRGINIA , 
		dta(VA.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_assignments/patent_assignments.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 VA  ,dta(VA.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta)  longstate(VIRGINIA) 
	corp_add_mergers VA  ,dta(VA.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers_2018.dta)  longstate(VIRGINIA) 
	replace targetsic = trim(targetsic)
	foreach var of varlist equityvalue mergeryear mergerdate{
	rename `var' `var'_new
	}
	corp_add_vc 	 WA  ,dta(WA.dta) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(VIRGINIA)
