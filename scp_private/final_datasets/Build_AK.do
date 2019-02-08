cd /NOBACKUP/scratch/share_scp/scp_private/scp2018/
global mergetempsuffix = "migration.AK"
clear 
import delimited using /NOBACKUP/scratch/share_scp/raw_data/Alaska/2018/CorporationsDownload.CSV, delim(",") varnames(1)

rename (entitynumber legalname) (dataid entityname)
keep if homecountry == "UNITED STATES" | homecountry == ""

rename entitymailing* *

drop entityphys* registered*
rename zip zipcode
rename stateprovince state

replace state = "AK" if missing(state)
rename homestate jurisdiction
replace jurisdiction = trim(itrim(jurisdiction))
replace jurisdiction = "AL" if jurisdiction == "ALABAMA"
replace jurisdiction = "AK" if jurisdiction == "ALASKA"
replace jurisdiction = "AZ" if jurisdiction == "ARIZONA"
replace jurisdiction = "AR" if jurisdiction == "ARKANSAS"
replace jurisdiction = "CA" if jurisdiction == "CALIFORNIA"
replace jurisdiction = "CO" if jurisdiction == "COLORADO"
replace jurisdiction = "CT" if jurisdiction == "CONNECTICUT"
replace jurisdiction = "DE" if jurisdiction == "DELAWARE"
replace jurisdiction = "FL" if jurisdiction == "FLORIDA"
replace jurisdiction = "GA" if jurisdiction == "GEORGIA"
replace jurisdiction = "HI" if jurisdiction == "HAWAII"
replace jurisdiction = "ID" if jurisdiction == "IDAHO"
replace jurisdiction = "IL" if jurisdiction == "ILLINOIS"
replace jurisdiction = "IN" if jurisdiction == "INDIANA"
replace jurisdiction = "IA" if jurisdiction == "IOWA"
replace jurisdiction = "KS" if jurisdiction == "KANSAS"
replace jurisdiction = "KY" if jurisdiction == "KENTUCKY"
replace jurisdiction = "LA" if jurisdiction == "LOUISIANA"
replace jurisdiction = "ME" if jurisdiction == "MAINE"
replace jurisdiction = "MD" if jurisdiction == "MARYLAND"
replace jurisdiction = "MA" if jurisdiction == "MASSACHUSETTS"
replace jurisdiction = "MI" if jurisdiction == "MICHIGAN"
replace jurisdiction = "MN" if jurisdiction == "MINNESOTA"
replace jurisdiction = "MS" if jurisdiction == "MISSISSIPPI"
replace jurisdiction = "MO" if jurisdiction == "MISSOURI"
replace jurisdiction = "MT" if jurisdiction == "MONTANA"
replace jurisdiction = "NE" if jurisdiction == "NEBRASKA"
replace jurisdiction = "NV" if jurisdiction == "NEVADA"
replace jurisdiction = "NH" if jurisdiction == "NEW HAMPSHIRE"
replace jurisdiction = "NJ" if jurisdiction == "NEW JERSEY"
replace jurisdiction = "NM" if jurisdiction == "NEW MEXICO"
replace jurisdiction = "NY" if jurisdiction == "NEW YORK"
replace jurisdiction = "NC" if jurisdiction == "NORTH CAROLINA"
replace jurisdiction = "ND" if jurisdiction == "NORTH DAKOTA"
replace jurisdiction = "OH" if jurisdiction == "OHIO"
replace jurisdiction = "OK" if jurisdiction == "OKLAHOMA"
replace jurisdiction = "OR" if jurisdiction == "OREGON"
replace jurisdiction = "PA" if jurisdiction == "PENNSYLVANIA"
replace jurisdiction = "RI" if jurisdiction == "RHODE ISLAND"
replace jurisdiction = "SC" if jurisdiction == "SOUTH CAROLINA"
replace jurisdiction = "SD" if jurisdiction == "SOUTH DAKOTA"
replace jurisdiction = "TN" if jurisdiction == "TENNESSEE"
replace jurisdiction = "TX" if jurisdiction == "TEXAS"
replace jurisdiction = "UT" if jurisdiction == "UTAH"
replace jurisdiction = "VT" if jurisdiction == "VERMONT"
replace jurisdiction = "VA" if jurisdiction == "VIRGINIA"
replace jurisdiction = "WA" if jurisdiction == "WASHINGTON"
replace jurisdiction = "WV" if jurisdiction == "WEST VIRGINIA"
replace jurisdiction = "WI" if jurisdiction == "WISCONSIN"
replace jurisdiction = "WY" if jurisdiction == "WYOMING"   

gen is_DE = jurisdiction == "DE"



gen stateaddress = state
gen local_firm = stateaddress == "AK" & inlist(jurisdiction,"AK","DE")

gen is_corp = strpos(corptype,"Corporation") > 0

drop if inlist(corptype, "Name Reservation","Business Name Registration")
gen is_nonprofit = strpos(corptype,"Nonprofit")
drop if is_nonprofit
gen incdate = date(akformeddate,"MDY")
gen incyear = year(incdate)
gen address = address1 + " " + address2
replace address = trim(itrim(address))
drop address1 address2
gen shortname = wordcount(entityname) <= 3
drop if incyear > 2019
save AK.dta, replace


clear
import delimited using /NOBACKUP/scratch/share_scp/raw_data/Alaska/2018/OfficialsDownload.csv, delim(",") varnames(1)
rename parententitynumber dataid

keep if inlist(officialtitle,"Member","President","Manager","Owner","Incorporator","General Manager")
gen is_individual = length(officialfirstname) > 0
drop if !is_individual
rename (officialfirst officiallast) (firstname lastname)

	replace lastname = subinstr(lastname,"."," ",.)
	replace lastname = subinstr(lastname,"*"," ",.)
	replace lastname = subinstr(lastname,","," ",.)
	replace lastname = upper(trim(itrim(lastname)))
	
	
	replace firstname = subinstr(firstname,"."," ",.)
	replace firstname = subinstr(firstname,"*"," ",.)
	replace firstname = subinstr(firstname,","," ",.)
	replace firstname = upper(trim(itrim(firstname)))
	
	gen fullname = firstname + " " + lastname
	replace fullname = trim(itrim(fullname))
	
gen title = "President"

keep fullname title firstname lastname dataid
save AK.directors.dta, replace


**
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	

    clear
    u AK.dta, replace
	tomname entityname
	save AK.dta, replace
	corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(~/migration/datafiles//AK.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(~/migration/datafiles//AK.dta)

	corp_add_eponymy, dtapath(~/migration/datafiles/AK.dta) directorpath(~/migration/datafiles/AK.directors.dta)
	
	# delimit ;
	corp_add_trademarks AK , 
		dta(~/migration/datafiles/AK.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications AK ALASKA , 
		dta(~/migration/datafiles/AK.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	corp_add_patent_assignments  AK ALASKA , 
		dta(~/migration/datafiles/AK.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	
	# delimit cr	
	// corp_add_ipos	 AK ,dta(~/migration/datafiles/AK.dta) ipo(/projects/reap.proj/data/ipoallUS.dta) longstate(ALASKA)
	corp_add_mergers AK ,dta(~/migration/datafiles/AK.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(ALASKA)

        // corp_add_vc 	 AK ,dta(AK.dta) vc(~/final_datasets/VX.dta) longstate(ALASKA)




 



