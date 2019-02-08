 clear
 cd ~/final_datasets
 
 
 local keepraw = 0
 local dtasuffix = "Jan2014File"
 di "Suffix : `dtasuffix'"
global mergetempsuffix="CA_Official"
 
 set more off
 

	clear
	infile using /projects/reap.proj/raw_data/California/CA_CORPHISTORY, using(/projects/reap.proj/raw_data/California/CORPHISTORY.TXT)
	keep if transactioncode == "AMDT"
	gen namechangeddate = date(transactiondate,"YMD")
	save CAtempnames.dta,replace


	clear
	infile using /projects/reap.proj/raw_data/California/CA_CORPMASTER,  using(/projects/reap.proj/raw_data/California/CORPMASTER.TXT)
	gen ord = _n
	recast long ord 
	gen dataid = ord
	
	gen incdate = date(incdate_str,"YMD")
	format incdate %d
	gen incyear = year(incdate)
	gen is_corp = 1
	
	replace jurisdiction_state = "DE" if jurisdiction_state == "DELAWARE"
	replace jurisdiction_state = "CA" if jurisdiction_state == ""

	gen address = address1 + " " + address2
	
	gen deathjyear = substr(last_update, 1,2)
	gen deathjday = substr(last_update,3,3)
	replace deathjyear = "" if deathjyear == "ET"
	replace deathjday = "" if deathjday == "XIL"
	destring deathjyear, replace
	destring deathjday, replace
	replace deathjyear = 2000 + deathjyear if deathjyear < 50
	
	
	jtoe deathjyear deathjday,gen(deathdate)
	replace deathdate = . if corpstatus == "1"
	replace deathdate = date("1/1/3000","MDY") if corpstatus !="1" & missing(deathdate)
	gen deathyear = year(deathdate)


	format deathdate %d
	
	rename (jurisdiction_state state_county)(jurisdiction state)
	replace state  = "CA" if missing(state)

	sort incdate entityname 
	gen is_nonprofit= corptaxbase == "N" & !missing(corptaxbase)
	
	** Final Data Drops
	if `keepraw' != 1 {
		keep if inlist(jurisdiction,"DELAWARE","DE","","CA")
		drop if length(state) > 2

		keep if inrange(incyear,1988,2015)
		keep if !is_nonprofit
		keep if state == "CA"
	}
	
	
	preserve
	keep dataid corpnumber entityname incdate incyear deathdate deathyear is_corp jurisdiction  address city state zipcode is_nonprofit
	save CA.`dtasuffix'.dta,replace



	restore
	preserve
	keep presidentname dataid 
	rename presidentname fullname
	split fullname, parse(" ") limit(2)
	rename fullname1 firstname
	gen title = "PRESIDENT"
	keep dataid title firstname fullname
	save CA.directors.dta,replace
	
	
	clear
	infile using /projects/reap.proj/raw_data/California/CA_CORPHISTORY,  using(/projects/reap.proj/raw_data/California/01Jun2015/CORPHISTORY.TXT)
	keep if transactioncode == "AMDT"
	gen namechangeddate = date(transactiondate,"YMD")
	save CAtempnames.dta,replace



	restore
	merge m:m corpnum using CAtempnames.dta
	keep if _merge == 3
	drop _merge
	rename newcorpname oldname
	keep dataid oldname namechangeddate
	duplicates drop
	save CA.names.dta,replace

	** LLCs
	local keepraw = 0
	clear

	infile using /projects/reap.proj/raw_data/California/CA_LPMASTER, using(/projects/reap.proj/raw_data/California/01Jun2015/LPMASTER.TXT)
	rename id llcid
	gen ord = _n
	recast long ord 
	gen dataid = 15000000 + ord
	
	gen incdate = date(incdate_str,"YMD")
	gen incyear = year(incdate)
	gen is_corp = 0
	drop calif* jurisdiction_state2
	rename mail* *
	sort incdate entityname 
	rename jurisdiction_state jurisdiction
	replace jurisdiction = "CA" if jurisdiction == ""

	** Final Data Drops
	if `keepraw' != 1 {	
		keep if inlist(jurisdiction,"CA","DE")
		keep if state == "CA" | state == ""
		keep if inrange(incyear,1988,2015)
	}
	
	preserve
	keep dataid llcid entityname incdate incyear  is_corp jurisdiction  address city state zipcode
	
	*Line Added
	replace entityname = regexr(entityname,"WHICH WILL DO .*$","")
	
	append using CA.`dtasuffix'.dta
	compress
	save CA.`dtasuffix'.dta,replace
	

	restore

	keep dataid manager1 manager2 registeredagent
	rename (registeredagent) (manager3)
	reshape long manager, i(dataid) j(managernum)
	gen title = "MANAGER"
	rename manager fullname
	split fullname, parse(" ") limit(2)
	rename fullname1 firstname
	keep dataid title firstname fullname
	append using CA.directors.dta
	save CA.directors.dta,replace
	
	
	 clear
	infile using /projects/reap.proj/raw_data/California/CA_CORPHISTORY,  using(/projects/reap.proj/raw_data/California/01Jun2015/CORPHISTORY.TXT)
	keep if transactioncode == "MERG"
	drop if strpos(comment, "OUTGOING")
	rename (corpnumber namecorpnumber) (histmergedintoid histmergedid)
	gen histmergerdate = date(transactiondate,"YMD") 
	drop if missing(histmergedid)
	save CA.recapitalizations.dta, replace

	
****
*** Step 2: Add Information
****


	
	
	corp_add_names,dta(CA.`dtasuffix'.dta) names(CA.names.dta)
	*corp_add_recapitalizations,dta(~/final_datasets/CA.dta) merger(CA.recapitalizations.dta) matchvariable(corpnumber)
	
	
	clear
	u CA.`dtasuffix'.dta
	tomname entityname
	drop if missing(dataid)
	save CA.`dtasuffix'.dta,replace

	corp_add_gender, dta(~/final_datasets/CA.`dtasuffix'.dta) directors(~/final_datasets/CA.directors.dta) names(~/ado/names/NATIONAL.TXT)

	corp_add_eponymy, dtapath(CA.`dtasuffix'.dta) directorpath(CA.directors.dta)
	
	# delimit ;
	corp_add_trademarks CA , 
		dta(CA.`dtasuffix'.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		classificationfile(/projects/reap.proj/data/trademarks/classification.dta)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications CA CALIFORNIA , 
		dta(CA.`dtasuffix'.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	corp_add_patent_assignments  CA CALIFORNIA , 
		dta(CA.`dtasuffix'.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	# delimit cr	
	
	
	corp_add_vc2 	 CA  ,dta(~/final_datasets/CA.`dtasuffix'.dta) vc(~/final_datasets/VC.investors.dta) longstate(CALIFORNIA) 

	###corp_add_vc 	 CA  ,dta(~/final_datasets/CA.`dtasuffix'.dta) vc(~/final_datasets/VX.dta) longstate(CALIFORNIA) 


	corp_add_ipos	 CA  ,dta(~/final_datasets/CA.`dtasuffix'.dta) ipo(/projects/reap.proj/data/ipoallUS.dta)  longstate(CALIFORNIA) 
	corp_add_mergers CA  ,dta(~/final_datasets/CA.`dtasuffix'.dta) merger(/projects/reap.proj/data/mergers.dta)  longstate(CALIFORNIA) 


*		set trace on
*		set tracedepth 1
	corp_add_industry_dummies , ind(~/nbercriw/industry_words.dta) dta(~/final_datasets/CA.`dtasuffix'.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(~/final_datasets/CA.`dtasuffix'.dta)

	
	

clear
u ~/final_datasets/CA.`dtasuffix'.dta
gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3

gen zip2 = substr(zipcode,1,2)
replace zip2 = "" if regexm(zip2,"[^0-9]")
destring zip2, replace
gen region= "SoCal" if  inlist(zip2,91,92)
replace region = "NoCal" if  inlist(zip2,93,94,95)
replace region = "Los Angeles" if  inlist(zip2,90)

 save ~/final_datasets/CA.`dtasuffix'.dta, replace


