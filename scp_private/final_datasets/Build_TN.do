cd /projects/reap.proj/reapindex/Tennessee

global mergetempsuffix TN    

clear

import delimited /projects/reap.proj/raw_data/Tennessee/FILING.txt,delim("|")


rename control_no dataid
rename filing_name entityname

drop if inlist(filing_type,"Nonprofit Corporation","Reserved Name","Foreign Registered Name")


rename filing_type type

gen is_corp = inlist(type,"For-profit Corporation")
gen address = principle_addr1 + principle_addr2 + principle_addr3
gen city = principle_city
gen addrstate = principle_state
gen zip5 = principle_postal_code

replace address = mail_addr1 + mail_addr2 +mail_addr3 if missing(address)
replace city = mail_city if missing(city)
replace addrstate = mail_state if missing(addrstate)
replace zip5 = mail_postal_code if missing(zip5)

gen country = principle_country
gen jurisdiction = formation_locale
replace jurisdiction = "TENNESSEE" if missing(jurisdiction) & country == "USA"
gen is_DE = jurisdiction == "DELAWARE"

gen local_firm= inlist(jurisdiction,"TENNESSEE","DELAWARE")


/* Generating Variables */

gen incdate = date(filing_date,"MDY")
gen incyear = year(incdate)

gen shortname = wordcount(entityname) < 4

drop if missing(incdate)
drop if missing(entityname)


replace country = "USA" if missing(country)
keep dataid entityname incdate incyear type is_DE jurisdiction country zip5 addrstate city address is_corp shortname local_firm

compress
rename zip5 zipcode
rename addrstate state
save TN.dta , replace

/* Build Director File  */
clear

import delimited data using /projects/reap.proj/raw_data/Tennessee/PARTY.txt, delim("|")
save TN.directors.dta,replace

rename data dataid
gen fullname = first_name + middle_name + last_name 
rename individual_title role
//No specified role

keep dataid fullname role 
drop if missing(fullname)
save TN.directors.dta, replace


**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u TN.dta , replace
	tomname entityname
	save TN.dta, replace

	corp_add_eponymy, dtapath(TN.dta) directorpath(TN.directors.dta)

	replace eponymous = 0

       corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(TN.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(TN.dta)
	
	
	# delimit ;
	corp_add_trademarks TN , 
		dta(TN.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications TN TENNESSEE , 
		dta(TN.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments  TN TENNESSEE , 
		dta(TN.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta"  "/projects/reap.proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
;
	# delimit cr	

	

	corp_add_ipos	 TN  ,dta(TN.dta) ipo(/projects/reap.proj/data/ipoallUS.dta)  longstate(TENNESSEE) 
	corp_add_mergers TN  ,dta(TN.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(TENNESSEE) 
