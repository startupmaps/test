
/* Change this to create test samples */



**
** STEP 1: Load the data dump from OK Corporations 
**
**



cd /projects/reap.proj/final_datasets/

/*
1:01 -- Firm List
898867:02 -- Address
3557314:03 --  Agent (we don't want)
4356409:04 -- Officers
5404401:05
6454123:06

*/


clear
import delimited using /projects/reap.proj/raw_data/Oklahoma/CORP_MSTR_151003.txt, delim("~") rowrange(1:898866) varnames(1) stringcols(_all) colrange(:19)
save OK.dta, replace


clear
import delimited using /projects/reap.proj/raw_data/Oklahoma/CORP_MSTR_151003.txt, delim("~") rowrange(898867:3557313) varnames(898867) stringcols(_all) colrange(:19)

gen address = trim(itrim(address1 + " " + address2))
drop address1 address2
rename zip_code zipcode

merge 1:m address_id using OK.dta
keep if _merge != 1
drop _merge
save OK.dta, replace


drop v10 v11

drop perpetual_flag
drop report_due_date
drop tax_id
drop foreign_fein
drop fictitious_name

rename name entityname

 compress
save OK.dta, replace

/* Don't know whether to use creation_date or formation_date */
gen incdate = date(creation_date,"MDY")

rename filing_number dataid
rename foreign_state jurisdiction

/*Only keep those firms that are in Oklahoma and with jurisdition eitheri n OK, or empty, or in DE */
replace jurisdiction = "OK" if jurisdiction == ""
replace state = "OK" if state == ""
gen stateaddress = state
gen local_firm = inlist(jurisdiction,"DE","OK") & stateaddress == "OK"

** Keep only USA firms
keep if inlist(foreign_country," ","","US","USA")
drop foreign_country

* Drop name reservations
destring corp_type_id, replace
drop if inrange(corp_type_id,1,6) | inrange(corp_type_id,16,18) | inrange(corp_type_id,35,51)
gen is_corp = inrange(corp_type_id,7,15)
save OK.dta, replace



*Build Director file

	
/*
1:01 -- Firm List
898867:02 -- Address
3557314:03 --  Agent (we don't want)
4356409:04 -- Officers
5404401:05
6454123:06

*/


clear
import delimited using /projects/reap.proj/raw_data/Oklahoma/CORP_MSTR_151003.txt, delim("~") rowrange(4356412:5404400) varnames(4356412) stringcols(_all)
rename filing_number dataid
gen fullname = itrim(first_name + " " + middle_name + " " + last_name)
rename officer_title role
replace role = upper(role)
keep if inlist(role, "PARTNER","OWNER","CEO","MANAGER","PRESIDENT")
keep dataid fullname role first_name
order dataid fullname role
save OK.directors.dta, replace
	


	
**
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	

	u OK.dta , replace
	tomname entityname
	save OK.dta, replace
	corp_add_eponymy, dtapath(OK.dta) directorpath(OK.directors.dta)
	
	
	corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(OK.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(OK.dta)
	
	# delimit ;
	corp_add_trademarks OK , 
		dta(OK.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications OK OKLAHOMA , 
		dta(OK.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;
	
/* No Patent Assignment */	
	corp_add_patent_assignments  OK OKLAHOMA , 
		dta(OK.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta"  "/projects/reap.proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
		
	# delimit cr	
	corp_add_ipos	 OK ,dta(OK.dta) ipo(/projects/reap.proj/data/ipoallUS.dta) longstate(OKLAHOMA)
	corp_add_mergers OK ,dta(OK.dta) merger(/projects/reap.proj/data/mergers.dta) longstate(OKLAHOMA)


corp_add_vc2 OK ,dta(OK.dta) vc(~/final_datasets/VC.investors.dta) longstate(OKLAHOMA)



corp_has_last_name, dtafile(OK.dta) lastnamedta(~/ado/names/lastnames.dta) num(5000)
corp_has_first_name, dtafile(OK.dta) num(1000)
corp_name_uniqueness, dtafile(OK.dta)

clear
u OK.dta
gen has_unique_name = uniquename <= 5
save OK.dta, replace




clear
u OK.dta
gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3
save OK.dta, replace

!/projects/reap.proj/chown_reap_proj.sh /projects/reap.proj/final_datasets/OK.dta
!cp  /projects/reap.proj/final_datasets/OK.dta ~/final_datasets/
