cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets/
global mergetempsuffix AZdata
global only_DE 0


clear
import delimited using /NOBACKUP/scratch/share_scp/raw_data/Arizona/corext.txt
replace v1 = v1 + " "+ v2 + " " + v3 + " " + v4 + " "+ v5 + " " +v6 + " " + v7


// save AZ.dta, replace

gen dataid = trim(itrim(substr(v1,65,9)))

/*
gen temp = substr(v1, 65, 1)
gen temp2 = substr(v1, 66, 1)
replace dataid = substr(v1, 65, 9) if inlist(temp, "F", "L", "P", "Q", "R", "X")
*/
gen entityname = trim(substr(v1,74,55))


gen address = trim(substr(v1,134,90))
gen city = trim(substr(v1,224,20))
gen state = substr(v1,244,2)
gen zipcode = substr(v1,246,5)

gen shortname = wordcount(entityname) < 4
gen idate = substr(v1,312,8)
// replace idate = substr(v1,311,8) if !missing(v2)

gen type = substr(v1,484,1)
gen jurisdiction = substr(v1,486,2)
gen is_DE = jurisdiction == "DE"

gen potentiallylocal =  inlist(jurisdiction,"AZ","DE")
drop if type == "N"
drop if type == "I"
gen is_corp = inlist(type,"A","F","G","P")
/* Generating Variables */

gen incdate = date(idate,"YMD")
gen incyear = year(incdate)

drop if missing(incdate)
drop if missing(entityname)
//type

/** Address for foreign entities is stored somewhere else **/
replace address = trim(substr(v1,747,90)) if is_DE == 1
replace city = trim(substr(v1,837,20)) if is_DE == 1
replace state = substr(v1,857,2) if is_DE == 1
replace zipcode = substr(v1,859,5) if is_DE == 1


keep dataid entityname incdate incyear is_DE jurisdiction zipcode state city address is_corp shortname potentiallylocal
replace state = "AZ" if missing(state) & jurisdiction == "AZ"
gen local_firm = potentiallylocal
replace state = trim(itrim(state))
gen stateaddress = state
compress
if $only_DE == 1 {
    keep if is_DE == 1
    local N = _N
    di "Using only Delaware firms.  Only DE flag turned on. `N' firms remaining"
}


save AZ.dta,replace


/* Build Director File */
clear

import delimited /NOBACKUP/scratch/share_scp/raw_data/Arizona/offext.txt

gen dataid = substr(v1,1,9)
gen role = substr(v1,10,2)
replace role = upper(trim(itrim(role)))
gen fullname = trim(substr(v1,12,30))

// keep if inlist(role,"PR","P") for legislator task
keep dataid fullname role 
drop if missing(fullname)
save /NOBACKUP/scratch/share_scp/scp_private/final_datasets/AZ.directors.dta, replace



**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u AZ.dta , replace
	tomname entityname
	save AZ.dta, replace

	corp_add_eponymy, dtapath(AZ.dta) directorpath(AZ.directors.dta)


       corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(AZ.dta)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(AZ.dta)
	
	
	# delimit ;
	corp_add_trademarks AZ , 
		dta(AZ.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications AZ ARIZONA , 
		dta(AZ.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments  AZ ARIZONA , 
		dta(AZ.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/patent_assignments.dta" "/NOBACKUP/scratch/share_scp/ext_data/patent_assignments2.dta"  "/NOBACKUP/scratch/share_scp/ext_data/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 AZ  ,dta(AZ.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta)  longstate(ARIZONA)
	corp_add_mergers AZ  ,dta(AZ.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/mergers.dta)  longstate(ARIZONA) 



      corp_add_vc        AZ ,dta(AZ.dta) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(ARIZONA)
      save /NOBACKUP/scratch/share_scp/migration/datafiles/AZ.dta, replace // for now
