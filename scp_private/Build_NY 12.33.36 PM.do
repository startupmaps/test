cd /NOBACKUP/scratch/share_scp/scp_private/scp2018
global mergetempsuffix NYmerge

clear
import delimited using /NOBACKUP/scratch/share_scp/scp_private/scp2018/raw_data/New_York/Active_Corporations___Beginning_1800.csv


gen incdate = date(initialdosfilingdate,"MDY")
gen incyear = year(incdate)


keep if incyear >= 1988

/** Do not use the address for the corporation agents **/
bysort registeredagentname: egen num_of_times = sum(1) if registeredagentname != ""
bysort dosprocessname: egen num_of_times2 = sum(1) if dosprocessname != ""

gen dos_info_lawyers_address = num_of_times > 50 & num_of_times != . | num_of_times2 > 50 & num_of_times2 != .

foreach v of varlist dosprocess* {
    replace `v' = "" if dos_info_lawyers_address == 1
}

gen address1 = ""
gen address2 = ""
gen zipcode  = ""
gen state    = ""
gen city     = ""

/** Get address in the following priority: location, ceo address, **/ 
set more off
foreach prefix in location ceo dosprocess {
    foreach v in address1 address2 zip state city {
        replace `v' = `prefix'`v'  if `v' == ""
    }
}

keep if inlist(jurisdiction, "DELAWARE","NEW YORK","")
gen is_DE = jurisdiction == "DELAWARE"
gen address =  address1 
replace address  = address2 if (strpos(address1,"C/O") |  strpos(address1,"ATTN") |  strpos(address1,"LLC") |  strpos(address1,"INC")) & address2 != ""


/** States come in long format, make them short two-letter versions **/
rename state longstate
replace longstate =  itrim(trim(longstate))
shortstate longstate , gen(state)
replace state = longstate if state  == "" & longstate != ""

/**only 5 digit zipcodes **/
replace zipcode = substr(itrim(trim(zipcode)), 1,5)

rename (dosid currententityname) (dataid entityname)
gen is_corp = strpos(entitytype, "CORPORATION")
keep entityname incdate incyear is_DE address zipcode state city dataid is_corp


save NY.dta , replace



// Don't have this file now 
clear
import delimited using "/NOBACKUP/scratch/share_scp/raw_data/New_York/Aug2015/us_ny_export_for_mit_2015-08-24.csv", delim(",") varnames(1) bindquote(loose)

rename (company_number name headquarters_address_*) (dataid entityname *)

foreach v of varlist *postal_code { 
    tostring `v' , replace
    replace `v' = "" if `v' == "."
}





capture drop ra_*
safedrop zipcode state city address

split registered_address_in_full,  parse(,)  gen(ra_)
gen zipcode = ""
gen state = ""
gen city = ""
gen address = ""

forvalues i =12(-1)5 { 
	//TODO:This is complex, will hopefully simplify later
	replace zipcode = ra_`i' if ra_`i' != "" & zipcode == ""
	
	local prev1 = `i'-1
	replace state = ra_`prev1' if ra_`prev1' != "" & zipcode != "" & state == ""
	
	
	local prev2 = `i'-2
	replace city = ra_`prev2' if ra_`prev2' != "" & state != "" & city == ""
	
	
	local prev3 = `i'-3
	replace address = ra_`prev3' if ra_`prev3' != "" & city != "" & address == ""
	
	
	local prev4 = `i'-4
	replace address = ra_`prev4' if ra_`prev4' != "" & address != "" & (length(address) < 7)
}


bysort address zipcode: egen num_of_times = sum(1) 
gen wrong_address = num_of_times > 100 & num_of_times != .

foreach v of varlist zipcode state city address { 
	replace `v' = "" if wrong_address==1
}


gen incdate = date(incorporation_date, "YMD")
gen incyear = year(incdate)
gen is_corp = strpos(company_type,"CORPORATION") > 0
gen is_nonprofit = strpos(company_type,"NOT-FOR-PROFIT") > 0

rename home_jurisdiction jurisdiction


replace jurisdiction = trim(upper(subinstr(jurisdiction,"us_","",.)))
gen is_DE = jurisdiction == "DE"

keep if inlist(jurisdiction,"","DE","NY")
replace state = "NY" if state == "" & jurisdiction == "NY"

/**only 5 digit zipcodes **/
replace zipcode = substr(itrim(trim(zipcode)), 1,5)


/** these are only the inactive ones **/
drop if current_status == "Active"

keep dataid entityname incdate incyear is_corp address city state zipcode is_DE current_status

gen second_file = 1
append using NY.dta 

replace second_file = 0 if second_file ==.
bysort dataid (second_file): gen keepme = _n == 1
keep if keepme == 1
drop keepme second_file
save NY.dta,replace


replace city = itrim(trim(upper(city)))
replace state = itrim(trim(upper(state)))
replace zipcode = itrim(trim(zipcode))

replace shortname = wordcount(entityname) <= 3
replace corpnumber = dataid

replace local_firm= state == "NY"
replace stateaddress = state

save NY.dta , replace

// keep old ones
append using ../final_datasets/NY.dta, keep(entityname dataid zipcode state city address incdate incyear is_corp is_DE current_status corpnumber local_firm stateaddress shortname)

replace entityname = trim(itrim(entityname))
replace state = trim(itrim(state))
replace city = trim(itrim(city))
replace zipcode = trim(itrim(zipcode))
replace address = trim(itrim(address))
replace stateaddress = state
drop local_firm
gen local_firm=state=="NY"

duplicates drop 


**
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u NY.dta, replace
	tomname entityname
	save NY.dta, replace
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(NY.dta)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(NY.dta)
*add gender and epony?


	# delimit ;
	corp_add_trademarks NY , 
		dta(NY.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications NY NEW YORK , 
		dta(NY.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
		
	# delimit ;	
	corp_add_patent_assignments  NY NEW YORK , 
		dta(NY.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_assignments.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	
	# delimit cr	
	corp_add_ipos	 NY ,dta(NY.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta) longstate(NEW YORK)
	corp_add_mergers NY  ,dta(NY.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers_2018.dta)  longstate(NEW YORK) 
	replace targetsic = trim(targetsic)
	foreach var of varlist equityvalue mergeryear mergerdate{
	rename `var' `var'_new
	}
	corp_add_vc 	 NY ,dta(NY.dta) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(NEW YORK)



clear
u NY.dta
safedrop shortname
gen  shortname = wordcount(entityname) <= 3
compress
 save NY.dta, replace
