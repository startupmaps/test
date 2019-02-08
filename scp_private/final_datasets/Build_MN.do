

cd /projects/reap.proj/reapindex/Minnesota
global mergetempsuffix MNfirms

global MN_dta_file MN.dta
global only_DE 0

clear 
import delimited using ~/projects/reap_proj/raw_data/Minnesota/89211430003.csv, delim(",")
 
save MN_raw.dta, replace

clear
u MN_raw.dta,replace
keep if v2 == 01
compress
save MN1.dta,replace

rename v1 dataid
rename v5 entityname
rename v7 dateinc
rename v10 jurisdiction
keep if inlist(jurisdiction,"Delaware","Minnesota")
rename v3 type
gen is_corp=1 if type == 43 | type == 66
save MN1.dta, replace



clear
u MN_raw.dta,replace
keep if v2 == 03
compress
save MN3.dta, replace

rename v1 dataid
gen address = trim(v9 + v10)
gen city = v11
gen state = v12
gen zipcode = v13

* Get the principal office, not just any office
rename v7 address_type
gen office_priority = .
replace office_priority = 1 if address_type == "2"
replace office_priority = 2 if address_type == "5"
replace office_priority = 3 if address_type == "6"
replace office_priority = 4 if address_type == "16"
replace office_priority = 5 if address_type == "17"
replace office_priority = 6 if address_type == "9999"
replace office_priority = 7 if length(address_type) == 1 & office_priority == .

bysort dataid (office_priority): gen top_address  = _n == 1
keep if top_address == 1


duplicates drop dataid, force

merge 1:1 dataid using MN1.dta
drop if _merge == 1 
drop _merge

gen shortname = wordcount(entityname) < 4
gen is_DE  =  jurisdiction == "Delaware"

gen incdate = date(dateinc,"MDY")
format incdate %d

gen incyear = year(incdate)

drop if missing(incdate)
drop if missing(entityname)
keep dataid entityname incdate incyear is_DE jurisdiction zipcode state city address is_corp shortname

gen stateaddress = state

replace state = "MN" if missing(state) & jurisdiction == "Minnesota"
compress
gen local_firm = 1

if $only_DE == 1 {
    keep if is_DE == 1
}

save $MN_dta_file,replace

/*
No director file
*/

**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	u $MN_dta_file , replace
	tomname entityname
	save $MN_dta_file, replace
/*
	corp_add_eponymy, dtapath($MN_dta_file) directorpath(MN.directors.dta)
*/
	gen eponomous = 0
       corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta($MN_dta_file)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta($MN_dta_file)
	
	
	# delimit ;
	corp_add_trademarks MN , 
		dta($MN_dta_file) 
		trademarkfile(~/projects/reap_proj/data/trademarks.dta) 
		ownerfile(~/projects/reap_proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications MN MINNESOTA , 
		dta($MN_dta_file) 
		pat(~/projects/reap_proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	
	corp_add_patent_assignments  MN MINNESOTA , 
		dta($MN_dta_file)
		pat("~/projects/reap_proj/data_share/patent_assignments.dta" "~/projects/reap_proj/data_share/patent_assignments2.dta"  "~/projects/reap_proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 MN  ,dta($MN_dta_file) ipo(~/projects/reap_proj/data/ipoallUS.dta)  longstate(MINNESOTA)
	corp_add_mergers MN  ,dta($MN_dta_file) merger(~/projects/reap_proj/data/mergers.dta)  longstate(MINNESOTA) 

        corp_add_vc MN ,dta($MN_dta_file) vc(~/final_datasets/VX.dta) longstate(MINNESOTA)

