set more off
cd ~/final_datasets
global mergetempsuffix="TX_Official"

/* Change this to create test samples */
global dtasuffix 


**
** STEP 1: Load the data dump from TX Corporations 
**
**

clear
infile using ~/final_datasets/TX02.dct, using(/projects/reap.proj/raw_data/Texas/July2015/02_TexasClean.txt)
drop if filing_number == ""
save TX.pre.dta, replace

clear
infile using ~/final_datasets/TX03.dct, using(/projects/reap.proj/raw_data/Texas/July2015/03_TexasClean.txt)
drop if filing_number == ""
merge 1:1 filing_number using TX.pre.dta
drop if _merge == 1
save TX.pre.dta, replace 




clear
       use TX.pre.dta

	replace foreign_state = "TX" if missing(foreign_state)

        gen address = address1 + " " + address2

        replace state = "TX" if state == "" & foreign_state == "TX"
        gen stateaddress = state

	gen is_nonprofit= inlist(corp_type_id,"08","09")

	gen incdate = date(creation_date,"YMD") 
	gen incdateDE = date(foreign_formation_date,"YMD")
	gen incyear = year(incdate)

	gen is_corp =inlist(corp_type_id,"01","02","03","04")
	rename (name filing_number) (entityname dataid)
	rename (foreign_state zip_code   ) (jurisdiction zipcode   )
	gen corpnumber = dataid
        gen local_firm = state == "TX" & inlist(jurisdiction,"TX","DE")


keep dataid corpnumber entityname incdate incyear  is_corp jurisdiction is_nonprofit address city state zipcode incdateDE stateaddress local_firm
	save TX$dtasuffix.dta,replace



	clear
	infile using ~/final_datasets/TX08.dct, using(/projects/reap.proj/raw_data/Texas/July2015/08_TexasClean.txt)
	rename filingnumber dataid
	gen fullname = trim(itrim(firstname + " " + middlename + " " +lastname))
	replace officertitle = upper(trim(itrim(officertitle)))
	replace officertitle = "MANAGER" if officertitle == "MANAGING MEMBER" | officertitle == "MEMBER" | officertitle == "MANAGING DIRECTOR"
	replace officertitle = "CEO" if officertitle == "CHIEF EXECUTIVE OFFICER" | officertitle == "CHAIRMAN" 
	replace officertitle = "PRESIDENT" if officertitle == "OWNER"
	rename officertitle role
	keep dataid fullname role firstname
	save TX.directors.dta,replace


	** Names
	clear
	infile using ~/final_datasets/TX09.dct, using(/projects/reap.proj/raw_data/Texas/July2015/09_TexasClean.txt)

	rename filingnumber dataid
	destring nametypeid ,replace
	destring namestatusid ,replace
	drop if namestatusid ==1
	drop if nametypeid !=1
	gen namechangeddate = date(creationdatestr,"YMD")
	keep dataid oldname namechangeddate
	duplicates drop


	save TX.names.dta,replace



	
**
**
** STEP 2: Add variables. These variables are within the first year
**		and very similar to the ones used in "Where Is Silicon Valley?"
**
**	
	corp_add_names, dta(TX$dtasuffix.dta) names(TX.names.dta) nosave
	u TX$dtasuffix.dta , replace
	tomname entityname
	save TX$dtasuffix.dta, replace
	corp_add_industry_dummies , ind(~/ado/industry_words.dta) dta(TX$dtasuffix.dta)
	corp_add_industry_dummies , ind(~/ado/VC_industry_words.dta) dta(TX$dtasuffix.dta)
	corp_add_gender, dta(TX$dtasuffix.dta) directors(TX.directors.dta) names(~/ado/names/NATIONAL.TXT)

	corp_add_eponymy, dtapath(TX$dtasuffix.dta) directorpath(TX.directors.dta)
	
	# delimit ;
	corp_add_trademarks TX , 
		dta(TX$dtasuffix.dta) 
		trademarkfile(/projects/reap.proj/data/trademarks.dta) 
		ownerfile(/projects/reap.proj/data/trademark_owner.dta)
		var(trademark) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	
	# delimit ;
	corp_add_patent_applications TX TEXAS , 
		dta(TX$dtasuffix.dta) 
		pat(/projects/reap.proj/data_share/patent_applications.dta) 
		var(patent_application) 
		frommonths(-12)
		tomonths(12)
		statefileexists;
	
	# delimit ;
	
	corp_add_patent_assignments  TX TEXAS , 
		dta(TX$dtasuffix.dta)
		pat("/projects/reap.proj/data_share/patent_assignments.dta" "/projects/reap.proj/data_share/patent_assignments2.dta"  "/projects/reap.proj/data_share/patent_assignments3.dta")
		frommonths(-12)
		tomonths(12)
		var(patent_assignment)
		statefileexists;
	# delimit cr	
	corp_add_ipos	 TX ,dta(TX$dtasuffix.dta) ipo(/projects/reap.proj/data/ipoallUS.dta) longstate(TEXAS)
	corp_add_mergers TX ,dta(TX$dtasuffix.dta) merger(/projects/reap.proj/data/mergers.dta) longstate(TEXAS)


      corp_add_vc        TX ,dta(TX.dta) vc(~/final_datasets/VX.dta) longstate(TEXAS)


corp_has_last_name, dtafile(TX$dtasuffix.dta) lastnamedta(~/ado/names/lastnames.dta) num(5000)
corp_has_first_name, dtafile(TX$dtasuffix.dta) num(1000)
corp_name_uniqueness, dtafile(TX$dtasuffix.dta)

clear
u TX$dtasuffix.dta
gen has_unique_name = uniquename <= 5
save TX$dtasuffix.dta, replace


clear
u TX$dtasuffix.dta
gen is_DE = jurisdiction == "DE"
gen  shortname = wordcount(entityname) <= 3
save TX$dtasuffix.dta, replace



u TX$dtasuffix.dta, replace
gen zip2 = substr(zipcode,1,2)
replace zip2 = "" if regexm(zip2,"[^0-9]")
destring zip2, replace
gen region = "So Texas (AUS/SAT)" if zip2 == 78
replace region = "Dallas/Houston" if inlist(zip2, 77,76)
gen region = "Other Texas" if zip2 == 79

 save TX$dtasuffix.dta, replace



