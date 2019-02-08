cd /NOBACKUP/scratch/share_scp/scp_private/scp2018

global mergetempsuffix WYmerge

clear
import delimited using "/NOBACKUP/scratch/share_scp/raw_data/Wyoming/2018/FILING.csv", delim("|") varnames(1) bindquote(loose)
rename mail_* *

rename (state_of_org postal_code filing_id filing_name)(jurisdiction zipcode dataid entityname)
gen address = upper(itrim(trim(addr1 + " " + addr2  + " " + addr3)))

replace jurisdiction = trim(jurisdiction)
replace jurisdiction = "DE" if jurisdiction == "Delaware"
replace jurisdiction = "WY" if jurisdiction == "" | jurisdiction == "Wyoming"
gen potentiallylocal= inlist(jurisdiction,"DE","WY")
 
gen is_nonprofit = filing_type == "Nonprofit Corporation"
gen is_corp = strpos(filing_type, "Corporation") >0
drop if is_nonprofit
gen is_DE = jurisdiction == "DE"
gen incdate = date(filing_date,"MDY")
ge incyear = year(incdate)


gen shortname = wordcount(entityname) <= 3
keep dataid entityname incdate incyear   is_corp  is_nonprofit address city state zipcode is_DE shortname potentiallylocal
gen local_firm = potentiallylocal

replace state = upper(trim(itrim(state)))

*****
rename state jurisdiction1
replace jurisdiction1 = "AL" if jurisdiction1 == "ALABAMA"
replace jurisdiction1 = "AK" if jurisdiction1 == "ALASKA"
replace jurisdiction1 = "AZ" if jurisdiction1 == "ARIZONA"
replace jurisdiction1 = "AR" if jurisdiction1 == "ARKANSAS"
replace jurisdiction1 = "CA" if jurisdiction1 == "CALIFORNIA"
replace jurisdiction1 = "CA" if jurisdiction1 == "CALIFORNIA (CA)"
replace jurisdiction1 = "CO" if jurisdiction1 == "COLORADO"
replace jurisdiction1 = "CT" if jurisdiction1 == "CONNECTICUT"
replace jurisdiction1 = "DE" if jurisdiction1 == "DELAWARE"
replace jurisdiction1 = "FL" if jurisdiction1 == "FLORIDA"
replace jurisdiction1 = "GA" if jurisdiction1 == "GEORGIA"
replace jurisdiction1 = "HI" if jurisdiction1 == "HAWAII"
replace jurisdiction1 = "ID" if jurisdiction1 == "IDAHO"
replace jurisdiction1 = "IL" if jurisdiction1 == "ILLINOIS"
replace jurisdiction1 = "IN" if jurisdiction1 == "INDIANA"
replace jurisdiction1 = "IA" if jurisdiction1 == "IOWA"
replace jurisdiction1 = "KS" if jurisdiction1 == "KANSAS"
replace jurisdiction1 = "KY" if jurisdiction1 == "KENTUCKY"
replace jurisdiction1 = "LA" if jurisdiction1 == "LOUISIANA"
replace jurisdiction1 = "ME" if jurisdiction1 == "MAINE"
replace jurisdiction1 = "MD" if jurisdiction1 == "MARYLAND"
replace jurisdiction1 = "MA" if jurisdiction1 == "MASSACHUSETTS"
replace jurisdiction1 = "MI" if jurisdiction1 == "MICHIGAN"
replace jurisdiction1 = "MN" if jurisdiction1 == "MINNESOTA"
replace jurisdiction1 = "MS" if jurisdiction1 == "MISSISSIPPI"
replace jurisdiction1 = "MO" if jurisdiction1 == "MISSOURI"
replace jurisdiction1 = "MT" if jurisdiction1 == "MONTANA"
replace jurisdiction1 = "NE" if jurisdiction1 == "NEBRASKA"
replace jurisdiction1 = "NV" if jurisdiction1 == "NEVADA"
replace jurisdiction1 = "NH" if jurisdiction1 == "NEW HAMPSHIRE"
replace jurisdiction1 = "NJ" if jurisdiction1 == "NEW JERSEY"
replace jurisdiction1 = "NM" if jurisdiction1 == "NEW MEXICO"
replace jurisdiction1 = "NY" if jurisdiction1 == "NEW YORK"
replace jurisdiction1 = "NC" if jurisdiction1 == "NORTH CAROLINA"
replace jurisdiction1 = "ND" if jurisdiction1 == "NORTH DAKOTA"
replace jurisdiction1 = "OH" if jurisdiction1 == "OHIO"
replace jurisdiction1 = "OK" if jurisdiction1 == "OKLAHOMA"
replace jurisdiction1 = "OR" if jurisdiction1 == "OREGON"
replace jurisdiction1 = "PA" if jurisdiction1 == "PENNSYLVANIA"
replace jurisdiction1 = "RI" if jurisdiction1 == "RHODE ISLAND"
replace jurisdiction1 = "SC" if jurisdiction1 == "SOUTH CAROLINA"
replace jurisdiction1 = "SD" if jurisdiction1 == "SOUTH DAKOTA"
replace jurisdiction1 = "TN" if jurisdiction1 == "TENNESSEE"
replace jurisdiction1 = "TX" if jurisdiction1 == "TEXAS"
replace jurisdiction1 = "TX" if jurisdiction1 == "TEXAS (TX)"
replace jurisdiction1 = "UT" if jurisdiction1 == "UTAH"
replace jurisdiction1 = "VT" if jurisdiction1 == "VERMONT"
replace jurisdiction1 = "VA" if jurisdiction1 == "VIRGINIA"
replace jurisdiction1 = "WA" if jurisdiction1 == "WASHINGTON"
replace jurisdiction1 = "WV" if jurisdiction1 == "WEST VIRGINIA"
replace jurisdiction1 = "WI" if jurisdiction1 == "WISCONSIN"
replace jurisdiction1 = "WY" if jurisdiction1 == "WYOMING" 

replace jurisdiction1 = "WY" if jurisdiction1 == "WYOMING - WY" 
replace jurisdiction1 = "WY" if jurisdiction1 == "WYOMING (WY)" 
rename jurisdiction1 state
*****
gen stateaddress = state
save WY.dta,replace


***** Directors ******
clear
import delimited using "/NOBACKUP/scratch/share_scp/raw_data/Wyoming/2018/PARTY.csv", delim("|") varnames(1) bindquote(loose)
rename source_id dataid
rename (first_name middle_name last_name) (firstname middlename lastname)

	replace lastname = subinstr(lastname,"."," ",.)
	replace lastname = subinstr(lastname,"*"," ",.)
	replace lastname = subinstr(lastname,","," ",.)
	replace lastname = upper(trim(itrim(lastname)))
	
	
	replace firstname = subinstr(firstname,"."," ",.)
	replace firstname = subinstr(firstname,"*"," ",.)
	replace firstname = subinstr(firstname,","," ",.)
	replace firstname = upper(trim(itrim(firstname)))
	
	replace middlename = subinstr(middlename,"."," ",.)
	replace middlename = subinstr(middlename,"*"," ",.)
	replace middlename = subinstr(middlename,","," ",.)
	replace middlename = upper(trim(itrim(middlename)))
	
	
	gen fullname = firstname + " " + middlename + " " + lastname
	replace fullname = trim(itrim(fullname))

keep if inlist(party_type,"President","Incorporator","Applicant","Organizer","Member","Manager","Member/Manager","General Partner")
gen role = "CEO" 
keep dataid fullname role
save WY.directors.dta,replace


**
**
** STEP 2: Add variables.

**	
	u WY.dta, replace
	tomname entityname
	save WY.dta, replace
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(WY.dta)
	corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(WY.dta)

*	corp_add_gender, dta(WY.dta) directors(WY.directors.dta) names(/NOBACKUP/scratch/share_scp/ext_data/names/WY.TXT)


	corp_add_eponymy, dtapath(WY.dta) directorpath(WY.directors.dta)
	
	# delimit ;
	corp_add_trademarks WY , 
		dta(WY.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/2018dta/trademarks/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications WY WYOMING , 
		dta(WY.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_applications/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	corp_add_patent_assignments  WY WYOMING , 
		dta(WY.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/2018dta/patent_assignments/patent_assignments.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	
	# delimit cr	
	corp_add_ipos	 WY ,dta(WY.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta) longstate(WYOMING)
	corp_add_mergers WY  ,dta(WY.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/2018dta/mergers/mergers_2018.dta)  longstate(WYOMING) 
	replace targetsic = trim(targetsic)
	foreach var of varlist equityvalue mergeryear mergerdate{
	rename `var' `var'_new
	}



 
       corp_add_vc        WY ,dta(WY.dta) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(WYOMING)
   
