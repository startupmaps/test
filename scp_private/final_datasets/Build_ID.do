cd /projects/reap.proj/final_datasets/
global mergetempsuffix ID
/*
# delimit ;

import delimited dataid dupN fileName additionalFileName OfficerrType OfficeHeld DateAppointed 
OfficerName OfficerStreet OfficerBldng OfficerState OfficerZip5 OfficerZip4 OfficerCountry
OfficerForeignZip State CorpType FileDate CurrentStatus ChangeDate EntityName EntityStreet EntityBldng
EntityCity EntityState EntityZip5 EntityZip4 EntityCountry entityForeignZip BusinessType
using /projects/reap.proj/raw_data/Idaho/CorpDat.txt, delim(tab);
*/


/*Importing */


clear

import delimited using /projects/reap.proj/raw_data/Idaho/CorpDat.txt, delim(tab)

save ID.dta, replace

* Generating Variables 
gen fileType = substr(v1,1,1)
gen dataid = substr(v1,2,7)
gen fileName = substr(v1,10,77)
gen fileName2 = substr(v1,87,50)
gen originState = substr(v1,307,20)
gen firmType = substr(v1,327,1)
gen fileDate = substr(v1,329,8)
gen status = substr(v1,337,1)
gen changedate = substr(v1,339,8)
gen entityname = fileName
gen address = substr(v1,387,60)
gen city = substr(v1,447,20)
gen addressState = substr(v1,467,2)
gen zipcode = substr(v1,469,5)
* gen zip4 = substr(v1,474,4)
gen country = substr(v1,478,20)
* gen nature = substr(v1,506,40)

drop v1

save ID.dta, replace

* Drop Non-Profit 
drop if fileType == "U" | firmType == "U" | firmType == "N"

* Drop Business Names , title Trust
drop if firmType  == "D" | firmType == "T" | firmType == "H" | firmType == "R"
gen is_corp = firmType == "B"



* More Varibles */
destring dataid, replace
gen incdate = date(fileDate, "YMD")
gen incyear = year(incdate)


gen cdate = date(changedate, "YMD")
replace originState = substr(originState,1,2)
compress

gen jurisdiction = originState
replace jurisdiction = "ID" if missing(jurisdiction) | jurisdiction == "  "
gen is_DE = jurisdiction == "DE"

replace country = trim(country)
keep if inlist(country,"","UNITED STATES","U.S.","U S A","U.S.A","U.S.A.","US","USA")
replace addressState = "ID" if trim(addressState) == ""

*keep if inlist(addressState,"ID")

gen local_firm= jurisdiction == "ID" | jurisdiction == "DE"
rename addressState state
rename dataid corpid
gen dataid = firmType + string(corpid)
save ID.dta, replace


clear
cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets/
import delimited using /NOBACKUP/scratch/share_scp/raw_data/Idaho/CorpDat.txt, delim(tab)
* Generating Variables 

gen dataid = substr(v1,2,7)
gen firmType = substr(v1,327,1)
destring dataid, replace
rename dataid corpid
gen dataid = firmType + string(corpid)
gen fullname = substr(v1,148,40)
gen role = substr(v1,137,1)
keep dataid fullname role
duplicates drop
save ID.directors.dta, replace


**
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
**	corp_add_names, dta(ID.dta) names(ID.names.dta) nosave
	u ID.dta , replace
	tomname entityname
	save ID.dta, replace

	corp_add_eponymy, dtapath(ID.dta) directorpath(ID.directors.dta)


       corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(ID.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(ID.dta)
	
	# delimit ;
	corp_add_trademarks ID , 
		dta(ID.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications ID IDAHO , 
		dta(ID.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

/* No Observations */	
	corp_add_patent_assignments  ID IDAHO , 
		dta(ID.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta"  "/projects/reap.proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	# delimit cr	
	
	corp_add_ipos	 ID ,dta(ID.dta) ipo(/projects/reap.proj/data/ipoallUS.dta) longstate(IDAHO)
	corp_add_mergers ID ,dta(ID.dta) merger(/projects/reap.proj/data/mergers.dta) longstate(IDAHO)



*corp_add_vc2 ID ,dta(ID.dta) vc(~/final_datasets/VC.investors.dta) longstate(IDAHO)



corp_has_last_name, dtafile(ID.dta) lastnamedta(~/ado/names/lastnames.dta) num(5000)
corp_has_first_name, dtafile(ID.dta) num(1000)
corp_name_uniqueness, dtafile(ID.dta)

clear
u ID.dta
gen has_unique_name = uniquename <= 5
save ID.dta, replace




clear
u ID.dta
gen  shortname = wordcount(entityname) <= 3
save ID.dta, replace


!/projects/reap.proj/chown_reap_proj.sh /projects/reap.proj/final_datasets/ID.dta
!cp /projects/reap.proj/final_datasets/ID.dta ~/final_datasets/
