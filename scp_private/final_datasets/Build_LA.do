clear
cd /NOBACKUP/scratch/share_scp/scp_private/final_datasets

global mergetempsuffix = "LA_State"
global only_DE 0
local dtasuffix = ""
local keepraw = 0

clear
import delimited using /NOBACKUP/scratch/share_scp/raw_data/Louisiana/Entities.csv, varname(1)
split startdate, parse(T)
drop startdate startdate2
gen incdate = date(startdate1, "YMD")
drop if incdate < td(01jan1988)
gen incyear =year(incdate)

rename (chartercategory id name address1) (firmtype dataid entityname address)
replace firmtype = trim(itrim(firmtype))
drop if inlist(firmtype, "X", "N", "W")

gen is_corp = inlist(firmtype, "D", "F")
gen is_foreign = inlist(firmtype, "F")

gen jurisdiction = trim(state)
keep if inlist(jurisdiction, "DE","LA")

/** Companies in DE have a different address under principal address **/
replace address = v24 if jurisdiction == "DE"
replace city = v25 if jurisdiction == "DE"
replace state = v26 if jurisdiction == "DE"
replace zipcode = v6 if jurisdiction == "DE"
    
replace zipcode = substr(itrim(trim(zipcode)),1,5)

replace state = trim(itrim(state))
gen local_firm= state == "LA"
gen stateaddress = state
gen is_DE = 1 if jurisdiction == "DE"
replace is_DE = 0 if jurisdiction != "DE"

if $only_DE == 1 {
   keep if is_DE ==1
}

keep dataid entityname incdate incyear is_corp is_DE address city state zipcode local_firm stateaddress
order dataid entityname incdate incyear is_corp is_DE address city state zipcode
save LA.dta, replace

****** DIRECTORS ****************
clear
import delimited using /NOBACKUP/scratch/share_scp/raw_data/Louisiana/OfficeraAgents.csv, varname(1)
drop if missing(firstname)
rename eid dataid
keep dataid firstname lastname titles v9 v10 v15 v16 v17 v22
order dataid firstname lastname titles v9 v10 v15 v16 v17 v22
rename (v9 v10 v15 v16 v17 v22) (f1 l1 t1 f2 l2 t2)

replace titles = upper(trim(itrim(titles)))
replace t1 = upper(trim(itrim(t1)))
replace t2 = upper(trim(itrim(t2)))

replace titles = "PRESIDENT" if inlist(titles, "ALL OFFICERS", "CHAIRMAN", "PRESIDENT","CEO")
replace titles = "MANAGER" if inlist(titles,"MANAGER","PARTNER","MEMBER")
gen dummy = inlist(titles, "PRESIDENT", "MANAGER")

replace t1 = "PRESIDENT" if inlist(t1, "ALL OFFICERS", "CHAIRMAN", "PRESIDENT","CEO")
replace t1 = "MANAGER" if inlist(t1,"MANAGER","PARTNER","MEMBER")
gen dummy1 = inlist(t1, "PRESIDENT", "MANAGER")

replace t2 = "PRESIDENT" if inlist(t2, "ALL OFFICERS", "CHAIRMAN", "PRESIDENT","CEO")
replace t2 = "MANAGER" if inlist(t2,"MANAGER","PARTNER","MEMBER")
gen dummy2 = inlist(t2, "PRESIDENT", "MANAGER")

// drop if dummy ==0 & dummy1 == 0 & dummy2 == 0 // keep for the legislator task
replace firstname = f1 if dummy ==0 & dummy1 == 1
replace lastname = l1 if dummy ==0 & dummy1 == 1
replace titles = t1 if dummy ==0 & dummy1 == 1

replace firstname = f2 if dummy ==0 & dummy2 == 1
replace lastname = l2 if dummy ==0 & dummy2 == 1
replace titles = t2 if dummy ==0 & dummy2 == 1

replace firstname = f2 if dummy ==1 & dummy2 == 1
replace lastname = l2 if dummy ==1 & dummy2 == 1
replace titles = t2 if dummy ==1 & dummy2 == 1

drop if strpos(firstname, "-")
drop if strpos(firstname, "(")
drop if strpos(firstname, `")"')
drop if strpos(firstname, "+")
drop if strpos(firstname, "&")
drop if strpos(firstname, "LLC")
drop if strpos(firstname, "LTD")
drop if strpos(firstname, `"""')
drop if strpos(firstname, "'")
drop if regexm(firstname,"[0-9]")
drop if strlen(firstname) < 4

drop if strpos(lastname, "-")
drop if strpos(lastname, "(")
drop if strpos(firstname, `")"')
drop if strpos(lastname, "+")
drop if strpos(lastname, "&")
drop if strpos(lastname, "LLC")
drop if strpos(lastname, "LTD")
drop if strpos(lastname, `"""')
drop if strpos(lastname, "'")
drop if regexm(lastname,"[0-9]")
drop if strlen(lastname) < 4
drop if missing(lastname)


replace firstname = subinstr(firstname,","," ",.)
replace firstname = subinstr(firstname,"."," ",.)
replace firstname = subinstr(firstname,"MOST REV"," ",.)
replace firstname = subinstr(firstname,"REV"," ",.)
replace lastname = subinstr(lastname,"MOST REV"," ",.)
replace lastname = subinstr(lastname,"REV"," ",.)

replace lastname = subinstr(lastname,","," ",.)
replace lastname = subinstr(lastname,"."," ",.)

replace firstname = upper(trim(itrim(firstname)))
replace lastname = upper(trim(itrim(lastname)))

gen fullname = firstname + " "+ lastname
replace fullname = trim(itrim(fullname))
rename titles role
keep dataid fullname role firstname
order dataid fullname role firstname
save LA.directors.dta, replace

******* OLD NAMES **************
clear
import delimited using /NOBACKUP/scratch/share_scp/raw_data/Louisiana/PreviousNames.csv, varname(1)
rename (previous1 dateofchange) (oldname date)
keep dataid date oldname 
split date, parse(T)
gen date3 = date(date1, "YMD")
drop date date1 date2
rename date3 namechangeddate
format namechangeddate %td

duplicates drop
save LA.names.dta, replace

********** STEP 2: Add variables ***********************

u LA.dta, replace
tomname entityname
save LA.dta, replace

corp_add_names, dta(LA.dta) names(LA.names.dta)
corp_add_gender, dta(LA.dta) directors(LA.directors.dta) names(/NOBACKUP/scratch/share_scp/scp_private/ado/names/NATIONAL.TXT)
corp_add_eponymy, dtapath(LA.dta) directorpath(LA.directors.dta)

	# delimit ;
	corp_add_patent_applications LA LOUISIANA , 
		dta(LA.dta) 
		pat(/NOBACKUP/scratch/share_scp/ext_data/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	corp_add_patent_assignments  LA LOUISIANA , 
		dta(LA.dta)
		pat("/NOBACKUP/scratch/share_scp/ext_data/patent_assignments.dta" "/NOBACKUP/scratch/share_scp/ext_data/patent_assignments2.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	

	# delimit ;
	corp_add_trademarks LA , 
		dta(LA.dta) 
		trademarkfile(/NOBACKUP/scratch/share_scp/ext_data/trademarks.dta) 
		ownerfile(/NOBACKUP/scratch/share_scp/ext_data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		classificationfile(/NOBACKUP/scratch/share_scp/ext_data/classification.dta)
		tomonths(12)
		;
		
	# delimit cr	
	
	corp_add_vc 	 LA  ,dta(LA.dta) vc(/NOBACKUP/scratch/share_scp/ext_data/VX.dta) longstate(LOUISIANA) 
	corp_add_ipos	 LA  ,dta(LA.dta) ipo(/NOBACKUP/scratch/share_scp/ext_data/ipoallUS.dta)  longstate(LOUISIANA) 
	corp_add_mergers LA  ,dta(LA.dta) merger(/NOBACKUP/scratch/share_scp/ext_data/mergers.dta)  longstate(LOUISIANA) 

	
corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/industry_words.dta) dta(LA.dta)
corp_add_industry_dummies , ind(/NOBACKUP/scratch/share_scp/ext_data/VC_industry_words.dta) dta(LA.dta)

clear
u LA.dta
gen  shortname = wordcount(entityname) <= 3
duplicates drop
save LA.dta, replace
