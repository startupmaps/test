

global mergetempsuffix NJDTA

cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets

clear

import delimited /NOBACKUP/scratch/share_scp/raw_data/NewJersey/corp_recs.imp,delim(tab)

gen data = v1 + v2 + v3 + v4 + v5 + v6

keep data
// save NJ.dta, replace

gen dataid = substr(data,1,10)
gen entityname = substr(data,11,100)
gen idate = substr(data,111,8)

gen type = substr(data,119,3)
replace type = trim(type)

drop if regexm(type,"NP")
gen is_corp = inlist(type,"DP","FR")


gen jurisdiction = substr(data,125,2)
gen potentiallylocal = inlist(jurisdiction,"DE","NJ")

gen address = trim(substr(data,288,70))
gen city = trim(substr(data,358,30))
gen state = trim(substr(data,388,2))
gen zipcode = trim(substr(data,390,5))

replace address = trim(substr(data,399,70)) if missing(address)
replace city = trim(substr(data,469,30)) if missing(city)
replace state = trim(substr(data,499,2)) if missing(state)
replace zipcode = trim(substr(data,501,5)) if missing(zipcode)

replace address = trim(substr(data, 177, 70)) if missing(address)
replace city = trim(substr(data, 247, 30)) if missing(city)
replace state = trim(substr(data, 277, 2)) if missing(state)
replace zipcode = trim(substr(data, 279, 5)) if missing(zipcode)
/*
corp number 10
corp name 100
incorp date 8 (YYYYMMDD)
type code 3
status code 3
incorp state 2
agent name 50 127 
agent address1 35 177
agent address2 35 212
agent city 30 247
agent state 2 277
agent zip 5 279
agent zip ext 4 284
main business line1 35 288
main business line2 35
main business city 30
main business state 2
main business zip 5
main business zip ext 4 395
principle address1  35
principle address2  35
principle city  30
principle state  2
principle zip  5
principle zip ext 4
last ar filing  8  (YYYYMMDD)
*/

gen shortname = wordcount(entityname) < 4

gen is_DE = 1 if regexm(jurisdiction,"DE")
replace is_DE = 0 if is_DE == .

**** Fix Agent Address *****
duplicates tag address, gen(dup)
replace address = "" if dup > 5 // & is_DE == 1
replace city = "" if dup > 5 // & is_DE == 1
replace state = "" if dup > 5 // & is_DE == 1
replace zipcode = "" if dup > 5 // & is_DE == 1
duplicates tag address, gen(dup2)
/* Generating Variables */

gen incdate = date(idate,"YMD")
gen incyear = year(incdate)

drop if missing(incdate)
drop if missing(entityname)

replace zipcode = "0" + zipcode if strlen(zipcode) == 4

keep dataid entityname incdate incyear type is_DE jurisdiction zipcode state city address is_corp shortname potentiallylocal 

gen stateaddress = state
gen local_firm = potentiallylocal


save NJ.dta,replace



**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u NJ.dta , replace
	tomname entityname
	save NJ.dta ,replace
	
	gen eponymous = 0
	save NJ.dta, replace
      
	
	# delimit ;
	corp_add_trademarks NJ , 
		dta(NJ.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications NJ NEW JERSEY , 
		dta(NJ.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments NJ NEW JERSEY , 
		dta(NJ.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/patent_assignments.dta" "/NOBACKUP/scratch/share_scp/ext_data/patent_assignments2.dta"  "/NOBACKUP/scratch/share_scp/ext_data/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 NJ  ,dta(NJ.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta)  longstate(NEW JERSEY) 
	corp_add_mergers NJ  ,dta(NJ.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/mergers.dta)  longstate(NEW JERSEY) 
	
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(NJ.dta)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(NJ.dta)
	
      corp_add_vc        NJ ,dta(NJ.dta) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(NEW JERSEY)
     compress
     save NJ.dta, replace
     save /NOBACKUP/scratch/share_scp/migration/datafiles/NJ.dta, replace
