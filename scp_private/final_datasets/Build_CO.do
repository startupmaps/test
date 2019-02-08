cd /projects/reap.proj/reapindex/Colorado

clear

import delimited /NOBACKUP/scratch/share_scp/raw_dataColorado/Entityextract-DLLC-DPC-FLLC-FPC-GOOD.txt,delim(tab)


rename entityid dataid
rename entitynm entityname

rename entitytyp type


gen address = epaddress1 + epaddress2
gen city = epcity
gen addrstate = epstatecd
gen zip5 = epzip

gen is_corp = inlist(type,"DPC","FPC")
gen shortname = wordcount(entityname) < 4

replace address = emaddress1 + emaddress2 if missing(address)
replace city = emcity if missing(city)
replace addrstate = emstatecd if missing(addrstate)
replace zip5 = emzip if missing(zip5)

gen country = epcountrycd
gen jurisdiction = jrsdctnform
replace jurisdiction = "CO" if missing(jurisdiction) & country == "US"
gen is_DE = jurisdiction == "DE"

gen local_firm= inlist(jurisdiction,"CO","DE")

/* Generating Variables */

gen incdate = date(entformdt,"MDY")
gen incyear = year(incdate)

drop if missing(incdate)
drop if missing(entityname)

replace country = "US" if missing(country)
keep dataid entityname incdate incyear type is_DE jurisdiction country zip5 addrstate city address is_corp shortname local_firm

compress
rename zip5 zipcode
rename addrstate state
save CO.dta,replace

/* Build Director File No role*/
clear
import delimited /NOBACKUP/scratch/share_scp/raw_data/Colorado/Entityextract-DLLC-DPC-FLLC-FPC-GOOD.txt,delim(tab)

rename entityid dataid
replace agfirstnm = upper(trim(itrim(agfirstnm)))
replace agmiddlenm = upper(trim(itrim(agmiddlenm)))
replace aglastnm = upper(trim(itrim(aglastnm)))

gen fullname = agfirstnm + " " + agmiddlenm + " "+ aglastnm
replace fullname = trim(itrim(fullname))

//No specified role, only agents
gen role = "AGENT"
keep dataid fullname role 
drop if missing(fullname)
save /NOBACKUP/scratch/share_scp/scp_private/final_datasets/CO.directors.dta, replace


**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u CO.dta , replace
	tomname entityname
	save CO.dta, replace

	corp_add_eponymy, dtapath(CO.dta) directorpath(CO.directors.dta)

	replace eponymous = 0
	
       corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(CO.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(CO.dta)
	
	
	# delimit ;
	corp_add_trademarks CO , 
		dta(CO.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications CO COLORADO , 
		dta(CO.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments  CO COLORADO , 
		dta(CO.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta"  "/projects/reap.proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 CO  ,dta(CO.dta) ipo(/projects/reap.proj/data/ipoallUS.dta)  longstate(COLORADO) 
	corp_add_mergers CO  ,dta(CO.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(COLORADO) 
