 cd /projects/reap.proj/final_datasets/
 global mergetempsuffix="IL_Official"


*** Step 1: Load the data.
clear
infile using IL.corp.dct , using(/projects/reap.proj/raw_data/Illinois/cdmaster1.txt)

rename FileNumber dataid
rename CorpName entityname
gen incdate = date(IncorpDate,"YMD")
gen incyear = year(incdate)

gen jurisdiction = ""
replace jurisdiction = "AL" if StateCode == 1
replace jurisdiction = "AK" if StateCode == 2
replace jurisdiction = "AZ" if StateCode == 4
replace jurisdiction = "AR" if StateCode == 5
replace jurisdiction = "CA" if StateCode == 6
replace jurisdiction = "CO" if StateCode == 8
replace jurisdiction = "CT" if StateCode == 9
replace jurisdiction = "DE" if StateCode == 10
replace jurisdiction = "DC" if StateCode == 11
replace jurisdiction = "FL" if StateCode == 12
replace jurisdiction = "GA" if StateCode == 13
replace jurisdiction = "HI" if StateCode == 15
replace jurisdiction = "ID" if StateCode == 16
replace jurisdiction = "IL" if StateCode == 17
replace jurisdiction = "IN" if StateCode == 18
replace jurisdiction = "IA" if StateCode == 19
replace jurisdiction = "KS" if StateCode == 20
replace jurisdiction = "KY" if StateCode == 21
replace jurisdiction = "LA" if StateCode == 22
replace jurisdiction = "ME" if StateCode == 23
replace jurisdiction = "MD" if StateCode == 24
replace jurisdiction = "MA" if StateCode == 25
replace jurisdiction = "MI" if StateCode == 26
replace jurisdiction = "MN" if StateCode == 27
replace jurisdiction = "MS" if StateCode == 28
replace jurisdiction = "MO" if StateCode == 29
replace jurisdiction = "MT" if StateCode == 30
replace jurisdiction = "NE" if StateCode == 31
replace jurisdiction = "NV" if StateCode == 32
replace jurisdiction = "NH" if StateCode == 33
replace jurisdiction = "NJ" if StateCode == 34
replace jurisdiction = "NM" if StateCode == 35
replace jurisdiction = "NY" if StateCode == 36
replace jurisdiction = "NC" if StateCode == 37
replace jurisdiction = "ND" if StateCode == 38
replace jurisdiction = "OH" if StateCode == 39
replace jurisdiction = "OK" if StateCode == 40
replace jurisdiction = "OR" if StateCode == 41
replace jurisdiction = "PA" if StateCode == 42
replace jurisdiction = "RI" if StateCode == 44
replace jurisdiction = "SC" if StateCode == 45
replace jurisdiction = "SD" if StateCode == 46
replace jurisdiction = "TN" if StateCode == 47
replace jurisdiction = "TX" if StateCode == 48
replace jurisdiction = "UT" if StateCode == 49
replace jurisdiction = "VT" if StateCode == 50
replace jurisdiction = "VA" if StateCode == 51
replace jurisdiction = "WA" if StateCode == 53
replace jurisdiction = "WV" if StateCode == 54
replace jurisdiction = "WI" if StateCode == 55
replace jurisdiction = "WY" if StateCode == 56


gen is_nonprofit = CorpIntent > 45
drop if is_nonprofit

keep if incyear >= 1988

gen zipcode = substr(PresNameADDR,-5,.)
replace zipcode = substr(PresNameADDR,-10,.) if substr(zipcode,1,1) == "-"
replace zipcode = substr(zipcode,1,5) if length(zipcode) == 10


merge m:1 zipcode using zip_state.dta
drop if _merge == 2
drop _merge

rename stabbr state
replace state = "IL" if state == "" & jurisdiction == "IL"
gen local_firm = state == "IL" & (jurisdiction == "IL" | jurisdiction == "DE")


gen city = ""
gen address = ""
gen is_corp = 1

gen shortname = wordcount(entityname) <= 3
gen is_DE = jurisdiction == "DE"
keep dataid entityname incdate incyear  jurisdiction zipcode state city address is_corp shortname local_firm is_DE
save IL.dta , replace


*** Add cdmaster2.txt
clear
infile using IL.corp.dct , using(/projects/reap.proj/raw_data/Illinois/cdmaster2.txt)

rename FileNumber dataid
rename CorpName entityname
gen incdate = date(IncorpDate,"YMD")
gen incyear = year(incdate)

gen jurisdiction = ""
replace jurisdiction = "AL" if StateCode == 1
replace jurisdiction = "AK" if StateCode == 2
replace jurisdiction = "AZ" if StateCode == 4
replace jurisdiction = "AR" if StateCode == 5
replace jurisdiction = "CA" if StateCode == 6
replace jurisdiction = "CO" if StateCode == 8
replace jurisdiction = "CT" if StateCode == 9
replace jurisdiction = "DE" if StateCode == 10
replace jurisdiction = "DC" if StateCode == 11
replace jurisdiction = "FL" if StateCode == 12
replace jurisdiction = "GA" if StateCode == 13
replace jurisdiction = "HI" if StateCode == 15
replace jurisdiction = "ID" if StateCode == 16
replace jurisdiction = "IL" if StateCode == 17
replace jurisdiction = "IN" if StateCode == 18
replace jurisdiction = "IA" if StateCode == 19
replace jurisdiction = "KS" if StateCode == 20
replace jurisdiction = "KY" if StateCode == 21
replace jurisdiction = "LA" if StateCode == 22
replace jurisdiction = "ME" if StateCode == 23
replace jurisdiction = "MD" if StateCode == 24
replace jurisdiction = "MA" if StateCode == 25
replace jurisdiction = "MI" if StateCode == 26
replace jurisdiction = "MN" if StateCode == 27
replace jurisdiction = "MS" if StateCode == 28
replace jurisdiction = "MO" if StateCode == 29
replace jurisdiction = "MT" if StateCode == 30
replace jurisdiction = "NE" if StateCode == 31
replace jurisdiction = "NV" if StateCode == 32
replace jurisdiction = "NH" if StateCode == 33
replace jurisdiction = "NJ" if StateCode == 34
replace jurisdiction = "NM" if StateCode == 35
replace jurisdiction = "NY" if StateCode == 36
replace jurisdiction = "NC" if StateCode == 37
replace jurisdiction = "ND" if StateCode == 38
replace jurisdiction = "OH" if StateCode == 39
replace jurisdiction = "OK" if StateCode == 40
replace jurisdiction = "OR" if StateCode == 41
replace jurisdiction = "PA" if StateCode == 42
replace jurisdiction = "RI" if StateCode == 44
replace jurisdiction = "SC" if StateCode == 45
replace jurisdiction = "SD" if StateCode == 46
replace jurisdiction = "TN" if StateCode == 47
replace jurisdiction = "TX" if StateCode == 48
replace jurisdiction = "UT" if StateCode == 49
replace jurisdiction = "VT" if StateCode == 50
replace jurisdiction = "VA" if StateCode == 51
replace jurisdiction = "WA" if StateCode == 53
replace jurisdiction = "WV" if StateCode == 54
replace jurisdiction = "WI" if StateCode == 55
replace jurisdiction = "WY" if StateCode == 56


gen is_nonprofit = CorpIntent > 45
drop if is_nonprofit

keep if incyear >= 1988

gen zipcode = substr(PresNameADDR,-5,.)
replace zipcode = substr(PresNameADDR,-10,.) if substr(zipcode,1,1) == "-"
replace zipcode = substr(zipcode,1,5) if length(zipcode) == 10


merge m:1 zipcode using zip_state.dta
drop if _merge == 2
drop _merge

rename stabbr state
replace state = "IL" if state == "" & jurisdiction == "IL"
gen local_firm = state == "IL" & (jurisdiction == "IL" | jurisdiction == "DE")


gen city = ""
gen address = ""
gen is_corp = 1

gen shortname = wordcount(entityname) <= 3
gen is_DE = jurisdiction == "DE"
keep dataid entityname incdate incyear  jurisdiction zipcode state city address is_corp shortname local_firm is_DE
save IL.dta , replace





append using IL.dta 
save IL.dta, replace


*** Add llc.txt
clear
infile using IL.llc.dct , using(/projects/reap.proj/raw_data/Illinois/limlib.txt)
keep if recordtype == "M"
rename incdate incdatestr
gen incdate = date(incdatestr,"YMD")
gen incyear = year(incdate)
replace zipcode = substr(zipcode,1,5)
merge m:1 zipcode using zip_state.dta
drop if _merge == 2
drop _merge

rename stabbr state

gen local_firm = state == "IL" & inlist(jurisdiction,"IL","DE")
gen is_corp = 0
gen shortname = wordcount(entityname)
gen is_DE = jurisdiction == "DE"

append using IL.dta
save IL.dta , replace 

*** For Eden:
	** Task 1. Access equity, and open stata in EXACTLY the same files  Jorge  is working on.
	** Task 2. Copy all files  from /projects/ reap.proj/sharedrive/ado to ~/ado/
	** Task 3. Add cdmaster2.txt and lim...txt firms to IL.dta






**
**
** STEP 2: Add varCTbles. These varCTbles are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
** Prepare the data
	u IL.dta , replace
	tomname entityname
	save IL.dta, replace
/*
	corp_add_eponymy, dtapath(IL.dta) directorpath(IL.directors.dta)
*/
	gen eponymous = 0
       corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(IL.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(IL.dta)
	
	
	# delimit ;
	corp_add_trademarks IL , 
		dta(IL.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications IL ILLINOIS , 
		dta(IL.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;

	
	
	 
	corp_add_patent_assignments  IL ILLINOIS , 
		dta(IL.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta"  "/projects/reap.proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		;
	# delimit cr	

	

	corp_add_ipos	 IL  ,dta(IL.dta) ipo(/projects/reap.proj/data/ipoallUS.dta)  longstate(ILLINOIS)
	corp_add_mergers IL  ,dta(IL.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(ILLINOIS) 

	corp_add_vc 	 IL ,dta(IL.dta) vc(~/final_datasets/VX.dta) longstate(ILLINOIS)

 
