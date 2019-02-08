cd /projects/reap.proj/reapindex/Maine

global mergetempsuffix Maine
global ME_file ME.dta
global only_DE 0

clear
import delimited using  ~/projects/reap_proj/raw_data/Maine/corp_all_new_20160607.csv , delim(",")

save $ME_file, replace

rename v1 dataid

/*Drop name registrations, those are not changes */
drop if strpos(dataid,"R")

rename v34 entityname
gen record_category = v37
gen address = v39 + v40
gen city = v41
gen state = v42
gen zipcode = v44

gen shortname = wordcount(entityname) < 4

gen jurisdiction = v6
gen is_DE = jurisdiction == "DE"

gen potentiallylocal =  inlist(jurisdiction,"ME","DE")

/* Generating Variables */

/**
   Preference for Address should be: M, C, O, H, X
   only keep 1
**/

gen address_value = .
replace address_value = 1 if record_category == "M"
replace address_value = 2 if record_category == "C"
replace address_value = 3 if record_category == "O"
replace address_value = 4 if record_category == "H"
replace address_value = 5 if record_category == "X"

bysort dataid (address_value): gen top_record = _n == 1
keep if top_record

gen incdate = date(v3,"YMD")
replace incdate = date(v4,"YMD") if incdate == .
format incdate %d

gen incyear = year(incdate)

drop if missing(incdate)
drop if missing(entityname)
//type
gen is_corp = 1 if regexm(entityname,"CORP")
replace is_corp = 1 if regexm(entityname,"INC")
gen country = "USA"
keep dataid entityname incdate incyear is_DE jurisdiction country zipcode state city address is_corp shortname country potentiallylocal
replace state = "ME" if missing(state) & jurisdiction == "ME"
gen stateaddress = state
gen local_firm = potentiallylocal

if "$only_DE" == "1" {
    keep if is_DE
}
replace zipcode = trim(zipcode)
replace zipcode = "0"+zipcode if strlen(zipcode) ==4
compress
duplicates drop
save $ME_file,replace

di ""
di " STATUS: NUMBER OF FIRMS"
di _N


**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u $ME_file , replace
	tomname entityname
	save $ME_file, replace
	gen eponymous = 0
	//corp_add_eponymy, dtapath($ME_file) directorpath(ME.directors.dta)


       corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta($ME_file)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta($ME_file)
	
	
	# delimit ;
	corp_add_trademarks ME , 
		dta($ME_file) 
		trademarkfile(~/projects/reap_proj/data/trademarks.dta) 
		ownerfile(~/projects/reap_proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications ME MAINE , 
		dta($ME_file) 
		pat(~/projects/reap_proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments  ME MAINE , 
		dta($ME_file)
		pat("~/projects/reap_proj/data_share/patent_assignments.dta" "~/projects/reap_proj/data_share/patent_assignments2.dta"  "~/projects/reap_proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 ME  ,dta($ME_file) ipo(~/projects/reap_proj/data/ipoallUS.dta)  longstate(MAINE) 
	corp_add_mergers ME  ,dta($ME_file) merger(~/projects/reap_proj/data/mergers.dta)  longstate(MAINE) 

      corp_add_vc        ME ,dta($ME_file) vc(~/final_datasets/VX.dta) longstate(MAINE)
